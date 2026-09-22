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

    func classify(text: String) async {

        state = .loading
        response = nil
        errorMessage = nil

        do {

            let result = try await apiService.classify(
                text: text
            )

            response = result
            state = .loaded

        } catch {

            errorMessage = error.localizedDescription
            state = .error(
                error.localizedDescription
            )
        }
    }
}
