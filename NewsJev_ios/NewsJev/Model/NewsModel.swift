import Foundation
import SwiftUI

struct ConfidenceLevel {

    let title: String
    let icon: String
    let color: Color
}

// MARK: - Request

struct NewsRequest: Codable {
    let text: String
}

// MARK: - Normal Classification Response

struct NewsResponse: Codable {
    let category: String
    let confidence: Double

    let topCategory: String
    let topConfidence: Double

    let secondCategory: String
    let secondConfidence: Double

    let confidenceMargin: Double

    let probabilities: [String: Double]

    let summary: String

    let needsHumanReview: Bool
    let processingPath: String

    let specificity: String
    let specificityScore: Double

    let decisionReason: String

    enum CodingKeys: String, CodingKey {
        case category
        case confidence

        case topCategory = "top_category"
        case topConfidence = "top_confidence"

        case secondCategory = "second_category"
        case secondConfidence = "second_confidence"

        case confidenceMargin = "confidence_margin"

        case probabilities
        case summary

        case needsHumanReview = "needs_human_review"
        case processingPath = "processing_path"

        case specificity
        case specificityScore = "specificity_score"

        case decisionReason = "decision_reason"
    }
}

// MARK: - JEV Questions

struct JEVQuestionResults: Codable {
    let category: String
    let specificity: Double

    let isSports: Double
    let isBusiness: Double
    let isTechnology: Double
    let isPolitics: Double

    enum CodingKeys: String, CodingKey {
        case category
        case specificity

        case isSports = "is_sports"
        case isBusiness = "is_business"
        case isTechnology = "is_technology"
        case isPolitics = "is_politics"
    }
}

// MARK: - JEV Comparison

struct JEVComparisonResult: Codable {
    let category: String
    let confidence: Double

    let probabilities: [String: Double]

    let specificity: String
    let specificityScore: Double

    let questions: JEVQuestionResults

    let questionCount: Int
    let executionMode: String
    let latencyMs: Double

    enum CodingKeys: String, CodingKey {
        case category
        case confidence
        case probabilities

        case specificity
        case specificityScore = "specificity_score"

        case questions
        case questionCount = "question_count"
        case executionMode = "execution_mode"
        case latencyMs = "latency_ms"
    }
}

// MARK: - Gemini

struct GeminiClassification: Codable {
    let category: String
    let confidence: Double
    let reason: String

    let latencyMs: Double

    let inputTokens: Int
    let outputTokens: Int
    let thoughtTokens: Int
    let totalTokens: Int

    let inputCostUsd: Double
    let outputCostUsd: Double
    let totalCostUsd: Double

    enum CodingKeys: String, CodingKey {
        case category
        case confidence
        case reason

        case latencyMs = "latency_ms"

        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case thoughtTokens = "thought_tokens"
        case totalTokens = "total_tokens"

        case inputCostUsd = "input_cost_usd"
        case outputCostUsd = "output_cost_usd"
        case totalCostUsd = "total_cost_usd"
    }
}

// MARK: - Comparison

struct ComparisonResult: Codable {
    let sameCategory: Bool

    let confidenceDifference: Double

    let categoryMatch: String

    let jevCategory: String
    let jevConfidence: Double

    let geminiCategory: String
    let geminiConfidence: Double

    let latencyDifferenceMs: Double

    enum CodingKeys: String, CodingKey {
        case sameCategory = "same_category"

        case confidenceDifference = "confidence_difference"

        case categoryMatch = "category_match"

        case jevCategory = "jev_category"
        case jevConfidence = "jev_confidence"

        case geminiCategory = "gemini_category"
        case geminiConfidence = "gemini_confidence"

        case latencyDifferenceMs = "latency_difference_ms"
    }
}

// MARK: - Routing

struct RoutingResponse: Codable {
    let route: String
    let reason: String

    let needsFollowUp: Bool
    let needsHumanReview: Bool

    let question: String?
    let options: [String]

    enum CodingKeys: String, CodingKey {
        case route
        case reason

        case needsFollowUp = "needs_follow_up"
        case needsHumanReview = "needs_human_review"

        case question
        case options
    }
}

// MARK: - Complete Comparison

struct NewsComparisonResponse: Codable {
    let text: String

    let jev: JEVComparisonResult

    let gemini: GeminiClassification

    let comparison: ComparisonResult

    let routing: RoutingResponse
}
