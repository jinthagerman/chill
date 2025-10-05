//
//  URLValidatorTests.swift
//  ChillTests
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//

import XCTest
@testable import Chill

/// Tests for URL validation including Facebook, Twitter, and unsupported platforms
/// Tasks: T004, T005, T006
final class URLValidatorTests: XCTestCase {
    
    var validator: URLValidator!
    
    override func setUp() {
        super.setUp()
        validator = URLValidator()
    }
    
    override func tearDown() {
        validator = nil
        super.tearDown()
    }
    
    // MARK: - T004: Facebook URL Validation Tests
    
    func testFacebookStandardURL() {
        // Test: facebook.com/{user}/videos/{id}
        let url = "https://facebook.com/username/videos/123456789"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid, "Standard Facebook URL should be valid")
        XCTAssertEqual(result.platform, .facebook, "Should detect Facebook platform")
        XCTAssertNil(result.errorMessage, "Valid URL should have no error")
        XCTAssertNotNil(result.normalizedURL, "Should return normalized URL")
    }
    
    func testFacebookWatchURL() {
        // Test: facebook.com/watch/?v={id}
        let url = "https://facebook.com/watch/?v=987654321"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid, "Facebook watch URL should be valid")
        XCTAssertEqual(result.platform, .facebook)
    }
    
    func testFacebookShortURL() {
        // Test: fb.watch/{id}
        let url = "https://fb.watch/abc123def"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid, "Facebook short URL (fb.watch) should be valid")
        XCTAssertEqual(result.platform, .facebook)
    }
    
    func testFacebookMobileURL() {
        // Test: m.facebook.com/watch/?v={id}
        let url = "https://m.facebook.com/watch/?v=555666777"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid, "Mobile Facebook URL should be valid")
        XCTAssertEqual(result.platform, .facebook)
    }
    
    func testFacebookInvalidURL() {
        let url = "https://facebook.com/not-a-video"
        let result = validator.validate(url)
        
        XCTAssertFalse(result.isValid, "Invalid Facebook URL should fail")
        XCTAssertNotNil(result.errorMessage, "Should have error message")
    }
    
    func testFacebookURLNormalization() {
        let url = "https://www.facebook.com/watch/?v=123&utm_source=share"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid)
        XCTAssertNotNil(result.normalizedURL)
        // Normalized URL should: remove www., remove tracking params
        XCTAssertFalse(result.normalizedURL?.contains("www.") ?? true, "Should remove www.")
        XCTAssertFalse(result.normalizedURL?.contains("utm_source") ?? true, "Should remove tracking params")
    }
    
    // MARK: - T005: Twitter URL Validation Tests
    
    func testTwitterStandardURL() {
        // Test: twitter.com/{user}/status/{id}
        let url = "https://twitter.com/username/status/1234567890123456789"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid, "Standard Twitter URL should be valid")
        XCTAssertEqual(result.platform, .twitter, "Should detect Twitter platform")
        XCTAssertNil(result.errorMessage)
    }
    
    func testTwitterXDotComURL() {
        // Test: x.com/{user}/status/{id}
        let url = "https://x.com/username/status/9876543210987654321"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid, "X.com URL should be valid")
        XCTAssertEqual(result.platform, .twitter, "x.com should map to Twitter platform")
    }
    
    func testTwitterMobileURL() {
        // Test: mobile.twitter.com/{user}/status/{id}
        let url = "https://mobile.twitter.com/user/status/1111111111111111111"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid, "Mobile Twitter URL should be valid")
        XCTAssertEqual(result.platform, .twitter)
    }
    
    func testTwitterShortenedURL() {
        // Test: t.co shortened URLs (these need special handling)
        let url = "https://t.co/abcd1234"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid, "t.co shortened URL should be valid")
        XCTAssertEqual(result.platform, .twitter)
    }
    
    func testTwitterInvalidURL() {
        let url = "https://twitter.com/username/invalid"
        let result = validator.validate(url)
        
        XCTAssertFalse(result.isValid, "Invalid Twitter URL should fail")
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testTwitterURLNormalization() {
        let url = "https://www.twitter.com/user/status/123?s=20"
        let result = validator.validate(url)
        
        XCTAssertTrue(result.isValid)
        XCTAssertNotNil(result.normalizedURL)
        XCTAssertFalse(result.normalizedURL?.contains("www.") ?? true)
        XCTAssertFalse(result.normalizedURL?.contains("?s=") ?? true, "Should remove query params")
    }
    
    // MARK: - T006: Unsupported Platform Rejection Tests
    
    func testYouTubeURLRejection() {
        // YouTube is NOT supported (LoadifyEngine doesn't support it)
        let urls = [
            "https://youtube.com/watch?v=abc123",
            "https://youtu.be/abc123",
            "https://www.youtube.com/watch?v=def456"
        ]
        
        for url in urls {
            let result = validator.validate(url)
            XCTAssertFalse(result.isValid, "YouTube URL should be rejected: \(url)")
            XCTAssertNil(result.platform, "Should not detect platform for unsupported URL")
            XCTAssertEqual(result.errorMessage, "Only Facebook and Twitter videos are supported",
                          "Should show correct error message")
        }
    }
    
    func testTikTokURLRejection() {
        // TikTok available in LoadifyEngine but excluded per clarification
        let url = "https://tiktok.com/@user/video/1234567890123456789"
        let result = validator.validate(url)
        
        XCTAssertFalse(result.isValid, "TikTok URL should be rejected")
        XCTAssertEqual(result.errorMessage, "Only Facebook and Twitter videos are supported")
    }
    
    func testInstagramURLRejection() {
        // Instagram available in LoadifyEngine but excluded per clarification
        let url = "https://instagram.com/p/ABC123def456/"
        let result = validator.validate(url)
        
        XCTAssertFalse(result.isValid, "Instagram URL should be rejected")
        XCTAssertEqual(result.errorMessage, "Only Facebook and Twitter videos are supported")
    }
    
    func testInvalidFormatRejection() {
        let invalidURLs = [
            "not-a-url",
            "ftp://invalid.com",
            "javascript:alert(1)",
            "",
            "   ",
            "http://",
            "random text here"
        ]
        
        for url in invalidURLs {
            let result = validator.validate(url)
            XCTAssertFalse(result.isValid, "Invalid format should be rejected: \(url)")
            XCTAssertEqual(result.errorMessage, "Please enter a valid video URL")
        }
    }
    
    func testErrorMessageClarity() {
        // Verify error messages match spec requirements
        let youtubeResult = validator.validate("https://youtube.com/watch?v=test")
        XCTAssertEqual(youtubeResult.errorMessage, "Only Facebook and Twitter videos are supported")
        
        let invalidResult = validator.validate("not-a-url")
        XCTAssertEqual(invalidResult.errorMessage, "Please enter a valid video URL")
    }
}
