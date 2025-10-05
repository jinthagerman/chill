//
//  AddVideoViewModelTests.swift
//  ChillTests
//
//  Created by Chill Team on 10/4/25.
//  Feature: 004-implement-add-video
//

import XCTest
import Combine
@testable import Chill

/// Tests for AddVideoViewModel state management and business logic
/// Tasks: T007, T008, T009
final class AddVideoViewModelTests: XCTestCase {
    
    var viewModel: AddVideoViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = AddVideoViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - T007: State Machine Tests
    
    func testInitialState() {
        // Initial state should have empty input and disabled button
        XCTAssertEqual(viewModel.urlInput, "", "URL input should start empty")
        XCTAssertEqual(viewModel.descriptionInput, "", "Description should start empty")
        XCTAssertFalse(viewModel.isSaveButtonEnabled, "Save button should be disabled initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error initially")
        XCTAssertFalse(viewModel.isConfirmationPresented, "Confirmation screen should not be presented")
    }
    
    func testValidURLEnablesButton() {
        let expectation = XCTestExpectation(description: "Button enabled after valid URL")
        
        viewModel.$isSaveButtonEnabled
            .dropFirst() // Skip initial value
            .sink { isEnabled in
                if isEnabled {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.urlInput = "https://facebook.com/user/videos/123"
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isSaveButtonEnabled, "Valid URL should enable save button")
    }
    
    func testInvalidURLDisablesButton() {
        // Set valid URL first
        viewModel.urlInput = "https://facebook.com/user/videos/123"
        
        // Then set invalid URL
        viewModel.urlInput = "not-a-url"
        
        // Wait for debounce
        let expectation = XCTestExpectation(description: "Wait for validation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(viewModel.isSaveButtonEnabled, "Invalid URL should disable button")
        XCTAssertNotNil(viewModel.errorMessage, "Should show error message")
    }
    
    func testSubmissionTransitionsToLoadingState() {
        viewModel.urlInput = "https://facebook.com/user/videos/123"
        
        let loadingExpectation = XCTestExpectation(description: "Loading state set")
        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if isLoading {
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.submitURL()
        
        wait(for: [loadingExpectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isLoading, "Should be in loading state during submission")
    }
    
    func testSuccessTransitionsToConfirmationScreen() {
        viewModel.urlInput = "https://facebook.com/user/videos/123"
        
        let confirmationExpectation = XCTestExpectation(description: "Confirmation presented")
        viewModel.$isConfirmationPresented
            .dropFirst()
            .sink { isPresented in
                if isPresented {
                    confirmationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate successful metadata fetch
        viewModel.submitURL()
        
        // Note: This will fail until AddVideoService is implemented
        // Expected behavior: isConfirmationPresented becomes true
    }
    
    func testFailureShowsErrorAndPreservesInput() {
        let originalURL = "https://facebook.com/user/videos/123"
        viewModel.urlInput = originalURL
        
        // Simulate network failure
        viewModel.simulateNetworkError() // Will need to be implemented
        
        XCTAssertNotNil(viewModel.errorMessage, "Should show error message on failure")
        XCTAssertEqual(viewModel.urlInput, originalURL, "Should preserve input on failure")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after error")
        XCTAssertFalse(viewModel.isConfirmationPresented, "Should not show confirmation on error")
    }
    
    // MARK: - T008: Validation Debounce Tests
    
    func testValidationDebounces300ms() {
        var validationCount = 0
        
        viewModel.$isSaveButtonEnabled
            .dropFirst()
            .sink { _ in
                validationCount += 1
            }
            .store(in: &cancellables)
        
        // Rapid typing simulation
        viewModel.urlInput = "h"
        viewModel.urlInput = "ht"
        viewModel.urlInput = "htt"
        viewModel.urlInput = "http"
        viewModel.urlInput = "https://facebook.com/user/videos/123"
        
        // Validation should not fire immediately
        XCTAssertEqual(validationCount, 0, "Validation should not fire immediately")
        
        // Wait for debounce period
        let expectation = XCTestExpectation(description: "Wait for debounce")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Validation should have fired once after debounce
        XCTAssertEqual(validationCount, 1, "Should validate once after debounce period")
    }
    
    func testRapidTypingDoesNotTriggerExcessiveValidation() {
        var validationCount = 0
        
        viewModel.$isSaveButtonEnabled
            .dropFirst()
            .sink { _ in
                validationCount += 1
            }
            .store(in: &cancellables)
        
        // Type rapidly (simulating real user typing)
        let testURL = "https://facebook.com/user/videos/123"
        for i in 1...testURL.count {
            let index = testURL.index(testURL.startIndex, offsetBy: i)
            viewModel.urlInput = String(testURL[..<index])
            Thread.sleep(forTimeInterval: 0.05) // 50ms between keystrokes
        }
        
        // Wait for final debounce
        let expectation = XCTestExpectation(description: "Wait for validation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Should only validate once at the end
        XCTAssertLessThanOrEqual(validationCount, 2, "Should not validate excessively during typing")
    }
    
    func testPasteTriggersValidationAfterDebounce() {
        let expectation = XCTestExpectation(description: "Validation after paste")
        
        viewModel.$isSaveButtonEnabled
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate paste (entire URL at once)
        viewModel.urlInput = "https://facebook.com/user/videos/123"
        
        wait(for: [expectation], timeout: 1.0)
        // Validation should fire after debounce period
    }
    
    // MARK: - T009: Duplicate Detection Tests
    
    func testDuplicateDetectionForExactMatch() {
        // This test requires ModelContext and existing VideoCardEntity
        // Will need to be fleshed out with proper SwiftData setup
        
        let duplicateURL = "https://facebook.com/user/videos/123"
        
        // TODO: Insert existing video with this URL in test database
        
        viewModel.urlInput = duplicateURL
        
        // Wait for validation and duplicate check
        let expectation = XCTestExpectation(description: "Duplicate detected")
        viewModel.$isDuplicate
            .dropFirst()
            .sink { isDuplicate in
                if isDuplicate {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertTrue(viewModel.isDuplicate, "Should detect duplicate URL")
        XCTAssertTrue(viewModel.isSaveButtonEnabled, "Button should remain enabled for duplicates")
        // Note: Warning message should be shown in UI but button stays enabled (per spec)
    }
    
    func testDuplicateDetectionForNormalizedVariants() {
        // Test that normalized URLs are detected as duplicates
        let originalURL = "https://facebook.com/watch/?v=123"
        let variantURL = "https://www.facebook.com/watch/?v=123&utm_source=share"
        
        // TODO: Insert original URL
        
        viewModel.urlInput = variantURL
        
        // Both should normalize to same URL and be detected as duplicate
        // Expected: isDuplicate = true, button enabled, warning shown
    }
    
    func testNonDuplicateURLAllowsSubmission() {
        let uniqueURL = "https://facebook.com/user/videos/999999"
        
        viewModel.urlInput = uniqueURL
        
        let expectation = XCTestExpectation(description: "Not duplicate")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(viewModel.isDuplicate, "Unique URL should not be flagged as duplicate")
        XCTAssertTrue(viewModel.isSaveButtonEnabled, "Button should be enabled for unique valid URL")
    }
}
