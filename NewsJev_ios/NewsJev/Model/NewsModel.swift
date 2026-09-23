import Foundation
import SwiftUI

struct ConfidenceLevel {

    let title: String
    let icon: String
    let color: Color
}

struct NewsRequest: Codable {
    let text: String
}

struct NewsResponse: Codable {

    // Classification
    let category: String
    let confidence: Double

    // Top-1
    let topCategory: String
    let topConfidence: Double

    // Top-2
    let secondCategory: String
    let secondConfidence: Double

    // Margin
    let confidenceMargin: Double

    // All probabilities
    let probabilities: [String: Double]

    // Summary
    let summary: String

    // Routing
    let needsHumanReview: Bool
    let processingPath: String

    // Specificity
    let specificity: String
    let specificityScore: Double

    // Explainability
    let decisionReason: String

    enum CodingKeys: String, CodingKey {

        case category
        case confidence

        case topCategory = "top_category"
        case topConfidence = "top_confidence"

        case secondCategory = "second_category"
        case secondConfidence = "second_confidence"

        case confidenceMargin =
            "confidence_margin"

        case probabilities
        case summary

        case needsHumanReview =
            "needs_human_review"

        case processingPath =
            "processing_path"

        case specificity

        case specificityScore =
            "specificity_score"

        case decisionReason =
            "decision_reason"
    }
}
