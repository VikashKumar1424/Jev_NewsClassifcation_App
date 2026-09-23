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
final class NewsStore {

    enum State {
        case idle
        case loading
        case loaded
        case error(String)
    }

    var state: State = .idle
    var response: NewsResponse?
    var errorMessage: String?

    private let apiService = NewsAPIService()

    private var classificationTask: Task<Void, Never>?

    // MARK: - Classify

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
