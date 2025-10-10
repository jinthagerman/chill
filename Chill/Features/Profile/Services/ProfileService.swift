import Foundation
import Supabase

/// Protocol for ProfileService
/// Added in: 006-add-a-profile
protocol ProfileServiceType {
    func loadProfile(for userID: UUID) async throws -> UserProfile
    func refreshStats(for userID: UUID) async throws -> Int
}

/// Service responsible for loading user profile data and aggregating information
/// from multiple sources (auth session, user metadata, video statistics)
/// Added in: 006-add-a-profile
@MainActor
final class ProfileService: ProfileServiceType {
    private let client: SupabaseClient
    private let cacheKey = "com.bitcrank.chill.cached_profile"
    private let cacheTimestampKey = "com.bitcrank.chill.cached_profile_timestamp"
    private let maxCacheAgeSeconds: TimeInterval = 86400  // 24 hours
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    /// Load complete user profile by aggregating data from multiple sources
    func loadProfile(for userID: UUID) async throws -> UserProfile {
        do {
            // Fetch current user session
            let session = try await client.auth.session
            
            // Fetch user metadata
            let user = try await client.auth.user()
            let metadata = user.userMetadata
            
            // Derive display name from metadata or email
            let displayName: String
            if let metadataDisplayName = metadata["display_name"] as? String, !metadataDisplayName.isEmpty {
                displayName = metadataDisplayName
            } else {
                // Default to email prefix (part before @)
                let emailComponents = session.user.email?.split(separator: "@") ?? []
                displayName = emailComponents.first.map(String.init) ?? "User"
            }
            
            // Get last login timestamp from metadata
            let lastLoginAt: Date?
            if let lastLoginTimestamp = metadata["last_login_at"] as? TimeInterval {
                lastLoginAt = Date(timeIntervalSince1970: lastLoginTimestamp)
            } else if let lastLoginString = metadata["last_login_at"] as? String,
                      let timestamp = Double(lastLoginString) {
                lastLoginAt = Date(timeIntervalSince1970: timestamp)
            } else {
                lastLoginAt = nil
            }
            
            // Query saved videos count (with graceful failure)
            let savedVideosCount: Int
            do {
                savedVideosCount = try await refreshStats(for: userID)
            } catch {
                // Stats query failure should not prevent profile load
                // Default to 0 as specified in contract
                savedVideosCount = 0
            }
            
            // Aggregate into UserProfile
            let profile = UserProfile(
                userID: session.user.id,
                email: session.user.email ?? "",
                displayName: displayName,
                accountCreatedAt: session.user.createdAt,
                isVerified: session.user.emailConfirmedAt != nil,
                lastLoginAt: lastLoginAt,
                savedVideosCount: savedVideosCount
            )
            
            // Cache the profile for offline access
            cacheProfile(profile)
            
            return profile
        } catch let error as ProfileError {
            // If network error, try to return cached profile
            if error == .networkUnavailable, let cached = loadCachedProfile() {
                return cached
            }
            throw error
        } catch {
            // Map Supabase/network errors to ProfileError
            let mappedError = mapError(error)
            
            // If network error, try to return cached profile
            if mappedError == .networkUnavailable, let cached = loadCachedProfile() {
                return cached
            }
            
            throw mappedError
        }
    }
    
    /// Refresh video statistics for a user
    func refreshStats(for userID: UUID) async throws -> Int {
        do {
            // Query videos table for count
            // Note: Adjust table name based on your schema
            let result: [CountResult] = try await client
                .from("videos")
                .select("id", head: false, count: .exact)
                .eq("user_id", value: userID.uuidString)
                .limit(0)  // We only want the count, not the data
                .execute()
                .value
            
            // The count is in the response metadata
            // For now, return 0 as a placeholder - actual count would come from response headers
            // In a real implementation, you'd extract count from response.count
            let count = result.count
            
            return count
        } catch {
            throw ProfileError.loadFailed
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapError(_ error: Error) -> ProfileError {
        // Check for network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            default:
                return .loadFailed
            }
        }
        
        // Check for Supabase auth errors
        if let authError = error as? Supabase.AuthError {
            switch authError {
            case .sessionMissing:
                return .unauthorized
            default:
                return .loadFailed
            }
        }
        
        // Default to loadFailed
        return .loadFailed
    }
    
    // MARK: - Caching
    
    private func cacheProfile(_ profile: UserProfile) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(CachedProfile(profile: profile))
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        } catch {
            // Cache failure is non-critical
            print("Failed to cache profile: \(error)")
        }
    }
    
    private func loadCachedProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? TimeInterval else {
            return nil
        }
        
        // Check cache age
        let cacheAge = Date().timeIntervalSince1970 - timestamp
        guard cacheAge < maxCacheAgeSeconds else {
            // Cache too old, clear it
            clearCache()
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cached = try decoder.decode(CachedProfile.self, from: data)
            return cached.profile
        } catch {
            // Corrupted cache, clear it
            clearCache()
            return nil
        }
    }
    
    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }
}

// MARK: - Helper Types

private struct CountResult: Decodable {
    let id: UUID?
}

private struct CachedProfile: Codable {
    let profile: UserProfile
}
