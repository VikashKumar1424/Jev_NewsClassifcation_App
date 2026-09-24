//
//  NewsStore.swift
//  NewsJev
//
//  Created by Vikash on 22/09/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class NewsState {

    enum State {
           case idle
           case loading
           case loaded
           case error(String)
       }

       var state: State = .idle

       var response: NewsResponse?

       var comparisonResponse: NewsComparisonResponse?

       var errorMessage: String?

       var isComparing = false

       private let apiService = NewsAPIService()

       private var classificationTask: Task<Void, Never>?

    
    func compare(text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            errorMessage = "Please enter some news text."
            return
        }

        isComparing = true
        comparisonResponse = nil
        errorMessage = nil

        do {
            print("🔵 Starting JEV vs Gemini comparison...")
            print("📝 Text: \(trimmedText)")

            let result = try await apiService.compare(text: trimmedText)

            print("✅ Comparison API completed")
            print("🤖 JEV Category: \(result.jev.category)")
            print("✨ Gemini Category: \(result.gemini.category)")
            print("🔄 Same Category: \(result.comparison.sameCategory)")

            comparisonResponse = result

        } catch {
            print("❌ Comparison failed")
            print("❌ Error: \(error)")
            print("❌ Description: \(error.localizedDescription)")

            errorMessage = error.localizedDescription
        }

        isComparing = false
    }    // MARK: - Classify

    func classify(text: String) async {

        // Cancel previous request if any
        classificationTask?.cancel()

        state = .loading
        response = nil
        errorMessage = nil

        classificationTask = Task {

            do {

                let result = try await apiService.classify(
                    text: text
                )

                // Check if user cancelled
                try Task.checkCancellation()

                response = result
                state = .loaded

            } catch is CancellationError {

                state = .idle
                response = nil

            } catch {

                // Don't show an error if task was cancelled
                if Task.isCancelled {
                    state = .idle
                    return
                }

                errorMessage = error.localizedDescription
                state = .error(
                    error.localizedDescription
                )
            }
        }

        await classificationTask?.value
        classificationTask = nil
    }

    // MARK: - Cancel

    func cancelClassification() {

        classificationTask?.cancel()
        classificationTask = nil

        state = .idle
        response = nil
        errorMessage = nil
    }
}
