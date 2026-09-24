//
//  APihandler.swift
//  NewsJev
//
//  Created by Vikash on 22/09/26.
//



import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."

        case .invalidResponse:
            return "Invalid response from server."

        case .serverError(let statusCode):
            return "Server returned HTTP \(statusCode)."

        case .decodingError(let message):
            return "JSON decoding failed: \(message)"
        }
    }
}

final class NewsAPIService {

    private let baseURL = "http://127.0.0.1:8000"

    // MARK: - Classify

    func classify(text: String) async throws -> NewsResponse {

        guard let url = URL(
            string: "\(baseURL)/api/v1/news/classify"
        ) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body = NewsRequest(text: text)

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("HTTP Status:", httpResponse.statusCode)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(
                NewsResponse.self,
                from: data
            )
        } catch {
            print("❌ Decode error:", error)

            if let json = String(
                data: data,
                encoding: .utf8
            ) {
                print("❌ JSON:", json)
            }

            throw APIError.decodingError(
                error.localizedDescription
            )
        }
    }

    // MARK: - Compare JEV vs Gemini

    func compare(
        text: String
    ) async throws -> NewsComparisonResponse {

        guard let url = URL(
            string: "\(baseURL)/api/v1/news/compare"
        ) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body = NewsRequest(text: text)

        request.httpBody = try JSONEncoder().encode(body)

        print("Calling:", url.absoluteString)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("HTTP Status:", httpResponse.statusCode)

        guard (200...299).contains(httpResponse.statusCode) else {

            if let serverMessage = String(
                data: data,
                encoding: .utf8
            ) {
                print("Server Error:", serverMessage)
            }

            throw APIError.serverError(httpResponse.statusCode)
        }

        do {

            let result = try JSONDecoder().decode(
                NewsComparisonResponse.self,
                from: data
            )

            print("JSON decoded successfully")

            return result

        } catch {

            print("❌ Comparison JSON decoding error:")
            print(error)

            if let json = String(
                data: data,
                encoding: .utf8
            ) {
                print("❌ JSON:")
                print(json)
            }

            throw APIError.decodingError(
                error.localizedDescription
            )
        }
    }
}
