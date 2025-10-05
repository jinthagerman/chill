//
//  AddVideoServiceTests.swift
//  ChillTests
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//

import XCTest
import LoadifyEngine
@testable import Chill

/// Tests for AddVideoService including LoadifyEngine integration
/// Task: T010
final class AddVideoServiceTests: XCTestCase {
    
    var service: AddVideoService!
    var mockLoadifyClient: MockLoadifyClient!
    
    override func setUp() {
        super.setUp()
        mockLoadifyClient = MockLoadifyClient()
        service = AddVideoService(loadifyClient: mockLoadifyClient)
    }
    
    override func tearDown() {
        service = nil
        mockLoadifyClient = nil
        super.tearDown()
    }
    
    // MARK: - Successful Metadata Extraction Tests
    
    func testSuccessfulFacebookMetadataExtraction() async throws {
        // Arrange
        let testURL = "https://facebook.com/user/videos/123"
        let expectedResponse = LoadifyResponse.mockFacebook
        mockLoadifyClient.mockResponse = expectedResponse
        
        // Act
        let metadata = try await service.extractMetadata(from: testURL)
        
        // Assert
        XCTAssertEqual(metadata.platform, .facebook)
        XCTAssertNotNil(metadata.title)
        XCTAssertNotNil(metadata.thumbnailURL)
        XCTAssertNotNil(metadata.creator)
        XCTAssertEqual(mockLoadifyClient.fetchCallCount, 1, "Should call LoadifyEngine once")
    }
    
    func testSuccessfulTwitterMetadataExtraction() async throws {
        let testURL = "https://twitter.com/user/status/123"
        let expectedResponse = LoadifyResponse.mockTwitter
        mockLoadifyClient.mockResponse = expectedResponse
        
        let metadata = try await service.extractMetadata(from: testURL)
        
        XCTAssertEqual(metadata.platform, .twitter)
        XCTAssertNotNil(metadata.title)
        XCTAssertNotNil(metadata.thumbnailURL)
    }
    
    func testMetadataMapping() async throws {
        // Test LoadifyResponse → VideoMetadata mapping
        let testURL = "https://facebook.com/user/videos/123"
        let mockResponse = LoadifyResponse(
            platform: .facebook,
            user: LoadifyResponse.UserDetails(
                name: "Test User",
                profileImage: "https://example.com/profile.jpg",
                profileImageSmall: nil
            ),
            video: LoadifyResponse.VideoDetails(
                url: "https://example.com/video.mp4",
                size: 1024.0,
                thumbnail: "https://example.com/thumb.jpg"
            )
        )
        mockLoadifyClient.mockResponse = mockResponse
        
        let metadata = try await service.extractMetadata(from: testURL)
        
        XCTAssertEqual(metadata.title, "Test User") // Or video title if available
        XCTAssertEqual(metadata.creator, "Test User")
        XCTAssertEqual(metadata.thumbnailURL, "https://example.com/thumb.jpg")
        XCTAssertEqual(metadata.platform, .facebook)
    }
    
    func testMissingCreatorUsesDefault() async throws {
        // Test fallback to "Unknown creator" when user details missing
        let testURL = "https://facebook.com/user/videos/123"
        let mockResponse = LoadifyResponse(
            platform: .facebook,
            user: nil, // No user details
            video: LoadifyResponse.VideoDetails(
                url: "https://example.com/video.mp4",
                size: nil,
                thumbnail: "https://example.com/thumb.jpg"
            )
        )
        mockLoadifyClient.mockResponse = mockResponse
        
        let metadata = try await service.extractMetadata(from: testURL)
        
        XCTAssertEqual(metadata.creator, "Unknown creator", "Should use default when creator missing")
    }
    
    // MARK: - Error Handling Tests
    
    func testTimeoutHandling() async {
        mockLoadifyClient.shouldTimeout = true
        mockLoadifyClient.timeoutDelay = 11.0 // Exceeds 10s limit
        
        do {
            _ = try await service.extractMetadata(from: "https://facebook.com/user/videos/123")
            XCTFail("Should throw timeout error")
        } catch let error as AddVideoServiceError {
            XCTAssertEqual(error, .timeout, "Should throw timeout error after 10s")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testMetadataExtractionFailure() async {
        mockLoadifyClient.shouldFail = true
        mockLoadifyClient.error = LoadifyError.parsingFailure
        
        do {
            _ = try await service.extractMetadata(from: "https://facebook.com/user/videos/123")
            XCTFail("Should throw extraction error")
        } catch let error as AddVideoServiceError {
            XCTAssertEqual(error, .extractionFailed, "Should throw extraction failed error")
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testNetworkFailureHandling() async {
        mockLoadifyClient.shouldFail = true
        mockLoadifyClient.error = LoadifyError.networkFailure
        
        do {
            _ = try await service.extractMetadata(from: "https://facebook.com/user/videos/123")
            XCTFail("Should throw network error")
        } catch let error as AddVideoServiceError {
            XCTAssertEqual(error, .networkError, "Should throw network error")
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testUnsupportedPlatformHandling() async {
        // LoadifyEngine might return TikTok but we only support Facebook/Twitter
        let testURL = "https://tiktok.com/@user/video/123"
        let mockResponse = LoadifyResponse.mockTikTok
        mockLoadifyClient.mockResponse = mockResponse
        
        do {
            _ = try await service.extractMetadata(from: testURL)
            XCTFail("Should reject unsupported platform")
        } catch let error as AddVideoServiceError {
            XCTAssertEqual(error, .unsupportedPlatform, "Should reject TikTok")
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    // MARK: - Progress Indication Tests
    
    func testProgressMessageAfter3Seconds() async {
        mockLoadifyClient.fetchDelay = 4.0 // Longer than 3s threshold
        
        let progressExpectation = expectation(description: "Progress message shown")
        var progressMessageShown = false
        
        Task {
            try? await Task.sleep(nanoseconds: 3_100_000_000) // 3.1 seconds
            if mockLoadifyClient.isCurrentlyFetching {
                progressMessageShown = true
                progressExpectation.fulfill()
            }
        }
        
        _ = try? await service.extractMetadata(from: "https://facebook.com/user/videos/123")
        
        await fulfillment(of: [progressExpectation], timeout: 5.0)
        XCTAssertTrue(progressMessageShown, "Should show progress message after 3s")
    }
    
    // MARK: - Caching Tests
    
    func testDuplicateFetchUsesCache() async throws {
        let testURL = "https://facebook.com/user/videos/123"
        mockLoadifyClient.mockResponse = LoadifyResponse.mockFacebook
        
        // First fetch
        _ = try await service.extractMetadata(from: testURL)
        
        // Second fetch (same URL)
        _ = try await service.extractMetadata(from: testURL)
        
        // Should use cache for second request
        XCTAssertEqual(mockLoadifyClient.fetchCallCount, 1, "Should cache and not fetch twice")
    }
}

// MARK: - Mock Classes

class MockLoadifyClient: LoadifyClientProtocol {
    var mockResponse: LoadifyResponse?
    var shouldFail = false
    var error: Error?
    var shouldTimeout = false
    var timeoutDelay: TimeInterval = 10.0
    var fetchDelay: TimeInterval = 0.5
    var fetchCallCount = 0
    var isCurrentlyFetching = false
    
    func fetchVideoDetails(for url: String) async throws -> LoadifyResponse {
        fetchCallCount += 1
        isCurrentlyFetching = true
        
        defer { isCurrentlyFetching = false }
        
        // Simulate delay
        try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        
        if shouldTimeout {
            try await Task.sleep(nanoseconds: UInt64(timeoutDelay * 1_000_000_000))
        }
        
        if shouldFail, let error = error {
            throw error
        }
        
        guard let response = mockResponse else {
            throw LoadifyError.parsingFailure
        }
        
        return response
    }
}

protocol LoadifyClientProtocol {
    func fetchVideoDetails(for url: String) async throws -> LoadifyResponse
}

enum LoadifyError: Error {
    case networkFailure
    case parsingFailure
    case unsupportedPlatform
}

enum AddVideoServiceError: Error, Equatable {
    case timeout
    case extractionFailed
    case networkError
    case unsupportedPlatform
}
