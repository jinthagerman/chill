import Foundation

struct AuthConfiguration {
    enum ConfigurationError: Error, LocalizedError, Equatable {
        case missingSupabaseURL
        case invalidSupabaseURL
        case missingSupabaseAnonKey
        case missingConfigurationFile
        case invalidConfigurationFormat

        var errorDescription: String? {
            switch self {
            case .missingSupabaseURL:
                return "Supabase URL is not configured."
            case .invalidSupabaseURL:
                return "Supabase URL is invalid."
            case .missingSupabaseAnonKey:
                return "Supabase anonymous key is not configured."
            case .missingConfigurationFile:
                return "Supabase configuration file is missing."
            case .invalidConfigurationFormat:
                return "Supabase configuration file is malformed."
            }
        }
    }

    let supabaseURL: URL
    let supabaseAnonKey: String

    init(supabaseURL: URL, supabaseAnonKey: String) {
        self.supabaseURL = supabaseURL
        self.supabaseAnonKey = supabaseAnonKey
    }

    static func load(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) throws -> AuthConfiguration {
        
        guard let urlString = bundle.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              let url = validatedURL(from: urlString) else {
                throw ConfigurationError.invalidSupabaseURL
        }

        guard let anonKey = bundle.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
              !anonKey.isEmpty else {
            throw ConfigurationError.missingSupabaseAnonKey
        }

        return AuthConfiguration(supabaseURL: url, supabaseAnonKey: anonKey)
    }

    private static func validatedURL(from value: String) -> URL? {
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return nil
        }
        return url
    }
}
