//
//  APihandler.swift
//  NewsJev
//
//  Created by Vikash on 22/09/26.
//



import Foundation

struct NewsAPIService {

    private let baseURL = "http://127.0.0.1:8000"

    func classify(
        text: String
    ) async throws -> NewsResponse {

        guard let url = URL(
            string: "\(baseURL)/api/v1/news/classify"
        ) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(
            url: url
        )

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body = NewsRequest(
            text: text
        )

        request.httpBody = try JSONEncoder().encode(
            body
        )

        let (
            data,
            response
        ) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard
            200...299 ~= httpResponse.statusCode
        else {

            let serverMessage =
                String(
                    data: data,
                    encoding: .utf8
                )
                ?? "Unknown server error"

            throw APIError.serverError(
                statusCode: httpResponse.statusCode,
                message: serverMessage
            )
        }

        do {

            return try JSONDecoder().decode(
                NewsResponse.self,
                from: data
            )

        } catch {

            print(
                "❌ JSON Decoding Error:"
            )

            print(error)

            if let jsonString =
                String(
                    data: data,
                    encoding: .utf8
                ) {

                print(
                    "Server Response:"
                )

                print(jsonString)
            }

            throw APIError.decodingError(
                error
            )
        }
    }
}

// MARK: - API Error

enum APIError: LocalizedError {

    case invalidURL
    case invalidResponse

    case serverError(
        statusCode: Int,
        message: String
    )

    case decodingError(
        Error
    )

    var errorDescription: String? {

        switch self {

        case .invalidURL:

            return "Invalid API URL."

        case .invalidResponse:

            return "Invalid server response."

        case .serverError(
            let statusCode,
            let message
        ):

            return """
            Server Error \(statusCode)

            \(message)
            """

        case .decodingError(
            let error
        ):

            return """
            JSON decoding failed:

            \(error.localizedDescription)
            """
        }
    }
}
