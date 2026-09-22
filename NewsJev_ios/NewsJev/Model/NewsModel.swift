//
//  NewsModel.swift
//  NewsJev
//
//  Created by Vikash on 22/09/26.
//

import Foundation
import SwiftUI

struct NewsRequest: Codable {
    let text: String
}

struct NewsResponse: Codable {

    let category: String
    let confidence: Double
    let probabilities: [String: Double]

    let summary: String

    let needsHumanReview: Bool

    let processingPath: String

    let specificity: String

    let specificityConfidence: Double

    enum CodingKeys: String, CodingKey {

        case category
        case confidence
        case probabilities
        case summary

        case needsHumanReview =
            "needs_human_review"

        case processingPath =
            "processing_path"

        case specificity

        case specificityConfidence =
            "specificity_confidence"
    }
}

struct ConfidenceLevel {

    let title: String
    let icon: String
    let color: Color
}
