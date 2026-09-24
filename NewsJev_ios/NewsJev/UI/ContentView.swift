//
//  ContentView.swift
//  NewsJev
//
//  Created by Vikash on 22/09/26.
//

import SwiftUI

struct ContentView: View {

    @State private var state = NewsState()

    @State private var newsText = ""

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    headerSection

                    inputSection

                    VStack(spacing: 12) {

                        classifyButton

                        compareButton
                    }

                    // MARK: - Normal JEV Classification

                    if let response = state.response {

                        resultCard(response)
                    }

                    // MARK: - JEV vs Gemini Comparison

                    if let comparison = state.comparisonResponse {

                        comparisonSection(comparison)
                    }

                    // MARK: - Error

                    if case .error(let message) = state.state {

                        errorCard(message)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header

private extension ContentView {

    var headerSection: some View {

        VStack(spacing: 8) {

            Image(systemName: "newspaper.fill")
                .font(.system(size: 42))
                .foregroundStyle(.blue)

            Text("JEV News Classifier")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("JEV + Gemini AI Classification")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - Input

private extension ContentView {

    var inputSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("News Article")
                .font(.headline)

            ZStack(alignment: .topLeading) {

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))

                if newsText.isEmpty {

                    Text("Enter news headline or article...")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                }

                TextEditor(text: $newsText)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 150)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )

            HStack {

                Image(systemName: "info.circle")

                Text("\(newsText.count) characters")

                Spacer()

                if !newsText.isEmpty {

                    Button("Clear") {

                        newsText = ""
                        state.response = nil
                        state.comparisonResponse = nil
                    }
                    .font(.caption)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Classification Button

private extension ContentView {

    var classifyButton: some View {

        Button {

            Task {

                await state.classify(
                    text: newsText
                )
            }

        } label: {

            HStack(spacing: 10) {

                if isLoading {

                    ProgressView()
                        .tint(.white)

                    Text("Classifying...")
                } else {

                    Image(systemName: "sparkles")

                    Text("Classify News")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                canClassify && !isLoading
                ? Color.blue
                : Color.gray
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
        .disabled(
            !canClassify || isLoading
        )
    }
}

// MARK: - Compare Button

private extension ContentView {

    var compareButton: some View {

        Button {

            Task {

                await state.compare(
                    text: newsText
                )
            }

        } label: {

            HStack(spacing: 10) {

                if state.isComparing {

                    ProgressView()
                        .tint(.white)

                    Text("Comparing...")
                } else {

                    Image(systemName: "arrow.left.arrow.right")

                    Text("Compare JEV vs Gemini")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                canClassify && !state.isComparing
                ? Color.purple
                : Color.gray
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
        .disabled(
            !canClassify || state.isComparing
        )
    }
}

// MARK: - Button State

private extension ContentView {

    var canClassify: Bool {

        !newsText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    var isLoading: Bool {

        if case .loading = state.state {

            return true
        }

        return false
    }
}

// MARK: - Normal Result Card

private extension ContentView {

    func resultCard(
        _ response: NewsResponse
    ) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            // MARK: Category

            VStack(alignment: .leading, spacing: 8) {

                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {

                    Image(
                        systemName:
                            categoryIcon(
                                response.category
                            )
                    )
                    .font(.title2)
                    .foregroundStyle(.blue)

                    Text(
                        response.category.capitalized
                    )
                    .font(.title)
                    .fontWeight(.bold)

                    Spacer()
                }
            }

            Divider()

            // MARK: Confidence

            confidenceView(
                response.confidence
            )

            // MARK: Top Two

            topTwoView(response)

            // MARK: Decision Reason

            decisionReasonView(
                response.decisionReason
            )

            // MARK: Specificity

            specificityView(response)

            // MARK: Processing Path

            processingPathView(response)

            // MARK: Human Review

            if response.needsHumanReview {

                humanReviewView
            }

            // MARK: Summary

            summaryView(
                response.summary
            )

            // MARK: Probabilities

            probabilitiesView(
                response.probabilities
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

// MARK: - Confidence

private extension ContentView {

    func confidenceView(
        _ confidence: Double
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text("Confidence")
                    .font(.headline)

                Spacer()

                Text(
                    "\(confidence * 100, specifier: "%.1f")%"
                )
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(
                    confidenceColor(confidence)
                )
            }

            ProgressView(
                value: confidence,
                total: 1.0
            )
            .tint(
                confidenceColor(confidence)
            )

            Text(
                confidenceLevel(confidence)
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Top Two

private extension ContentView {

    func topTwoView(
        _ response: NewsResponse
    ) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            Text("Top Classification")
                .font(.headline)

            HStack(spacing: 12) {

                classificationProbabilityCard(
                    title: "Top 1",
                    category: response.topCategory,
                    confidence: response.topConfidence,
                    icon: "1.circle.fill"
                )

                classificationProbabilityCard(
                    title: "Top 2",
                    category: response.secondCategory,
                    confidence: response.secondConfidence,
                    icon: "2.circle.fill"
                )
            }

            VStack(alignment: .leading, spacing: 8) {

                HStack {

                    Text("Confidence Margin")

                    Spacer()

                    Text(
                        "\(response.confidenceMargin * 100, specifier: "%.1f")%"
                    )
                    .fontWeight(.bold)
                }

                ProgressView(
                    value: response.confidenceMargin,
                    total: 1.0
                )
                .tint(
                    marginColor(
                        response.confidenceMargin
                    )
                )

                Text(
                    marginDescription(
                        response.confidenceMargin
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        Color(.secondarySystemBackground)
                    )
            )
        }
    }

    func classificationProbabilityCard(
        title: String,
        category: String,
        confidence: Double,
        icon: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack {

                Image(systemName: icon)
                    .foregroundStyle(.blue)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(
                category.capitalized
            )
            .font(.headline)

            Text(
                "\(confidence * 100, specifier: "%.1f")%"
            )
            .font(.title3)
            .fontWeight(.bold)

            ProgressView(
                value: confidence,
                total: 1.0
            )
            .tint(.blue)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color.blue.opacity(0.06)
                )
        )
    }

    func marginColor(
        _ margin: Double
    ) -> Color {

        if margin >= 0.30 {

            return .green

        } else if margin >= 0.15 {

            return .orange
        }

        return .red
    }

    func marginDescription(
        _ margin: Double
    ) -> String {

        if margin >= 0.30 {

            return "Strong separation between Top 1 and Top 2."

        } else if margin >= 0.15 {

            return "Moderate separation between Top 1 and Top 2."
        }

        return "Top 1 and Top 2 are close. Classification may be ambiguous."
    }
}

// MARK: - Decision Reason

private extension ContentView {

    func decisionReasonView(
        _ reason: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(
                systemName:
                    decisionReasonIcon(reason)
            )
            .font(.title3)
            .foregroundStyle(
                decisionReasonColor(reason)
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Decision Reason")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    formatDecisionReason(reason)
                )
                .font(.headline)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    decisionReasonColor(reason)
                        .opacity(0.08)
                )
        )
    }

    func formatDecisionReason(
        _ reason: String
    ) -> String {

        switch reason {

        case "high_confidence_specific":

            return "High Confidence + Specific"

        case "ambiguous_top_two":

            return "Top-2 Categories Are Ambiguous"

        case "medium_confidence":

            return "Medium Confidence"

        case "low_confidence":

            return "Low Confidence"

        case "not_specific":

            return "News Is Not Specific"

        default:

            return reason
                .replacingOccurrences(
                    of: "_",
                    with: " "
                )
                .capitalized
        }
    }

    func decisionReasonIcon(
        _ reason: String
    ) -> String {

        switch reason {

        case "high_confidence_specific":

            return "checkmark.circle.fill"

        case "ambiguous_top_two":

            return "arrow.left.arrow.right.circle.fill"

        case "medium_confidence":

            return "minus.circle.fill"

        case "low_confidence":

            return "exclamationmark.circle.fill"

        case "not_specific":

            return "questionmark.circle.fill"

        default:

            return "info.circle.fill"
        }
    }

    func decisionReasonColor(
        _ reason: String
    ) -> Color {

        switch reason {

        case "high_confidence_specific":

            return .green

        case "ambiguous_top_two":

            return .orange

        case "medium_confidence":

            return .orange

        case "low_confidence":

            return .red

        case "not_specific":

            return .orange

        default:

            return .blue
        }
    }
}

// MARK: - Specificity

private extension ContentView {

    func specificityView(
        _ response: NewsResponse
    ) -> some View {

        let isSpecific =
            response.specificity == "specific"

        return HStack(spacing: 14) {

            Image(
                systemName:
                    isSpecific
                    ? "checkmark.circle.fill"
                    : "questionmark.circle.fill"
            )
            .font(.title2)
            .foregroundStyle(
                isSpecific
                ? .green
                : .orange
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("News Specificity")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    isSpecific
                    ? "Specific"
                    : "Not Specific"
                )
                .font(.headline)

                Text(
                    "Score: \(response.specificityScore * 100, specifier: "%.1f")%"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    (
                        isSpecific
                        ? Color.green
                        : Color.orange
                    )
                    .opacity(0.08)
                )
        )
    }
}

// MARK: - Processing Path

private extension ContentView {

    func processingPathView(
        _ response: NewsResponse
    ) -> some View {

        let isJEVOnly =
            response.processingPath == "jev_only"

        return HStack(spacing: 14) {

            Image(
                systemName:
                    isJEVOnly
                    ? "checkmark.shield.fill"
                    : "arrow.triangle.branch"
            )
            .font(.title2)
            .foregroundStyle(
                isJEVOnly
                ? .green
                : .blue
            )
            .frame(
                width: 44,
                height: 44
            )
            .background(
                (
                    isJEVOnly
                    ? Color.green
                    : Color.blue
                )
                .opacity(0.12)
            )
            .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text("Processing Path")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    isJEVOnly
                    ? "JEV Only"
                    : "JEV + Gemini"
                )
                .font(.headline)
                .fontWeight(.semibold)

                Text(
                    processingPathDescription(
                        response.processingPath
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(
                isJEVOnly
                ? "High Confidence"
                : "Enriched"
            )
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                (
                    isJEVOnly
                    ? Color.green
                    : Color.blue
                )
                .opacity(0.12)
            )
            .foregroundStyle(
                isJEVOnly
                ? .green
                : .blue
            )
            .clipShape(Capsule())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    isJEVOnly
                    ? Color.green.opacity(0.06)
                    : Color.blue.opacity(0.06)
                )
        )
    }

    func processingPathDescription(
        _ path: String
    ) -> String {

        switch path {

        case "jev_only":

            return "JEV confidence was high enough to complete classification."

        case "jev_then_gemini":

            return "JEV classification was enriched using Gemini."

        case "jev_specificity_check_then_gemini":

            return "JEV found the news was not specific, so Gemini was used for enrichment."

        default:

            return "Classification completed using the AI pipeline."
        }
    }
}

// MARK: - Human Review

private extension ContentView {

    var humanReviewView: some View {

        HStack(spacing: 14) {

            Image(
                systemName:
                    "person.crop.circle.badge.exclamationmark"
            )
            .font(.title2)
            .foregroundStyle(.orange)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Human Review Required")
                    .font(.headline)

                Text(
                    "The AI pipeline could not confidently process this news."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    Color.orange.opacity(0.08)
                )
        )
    }
}

// MARK: - Summary

private extension ContentView {

    func summaryView(
        _ summary: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Image(systemName: "text.quote")

                    .foregroundStyle(.blue)

                Text("Summary")
                    .font(.headline)
            }

            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    Color(.secondarySystemBackground)
                )
        )
    }
}

// MARK: - Probabilities

private extension ContentView {

    func probabilitiesView(
        _ probabilities: [String: Double]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Category Probabilities")
                .font(.headline)

            let sorted = probabilities.sorted {
                $0.value > $1.value
            }

            ForEach(
                sorted,
                id: \.key
            ) { item in

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    HStack {

                        Text(
                            item.key.capitalized
                        )

                        Spacer()

                        Text(
                            "\(item.value * 100, specifier: "%.1f")%"
                        )
                        .fontWeight(.semibold)
                    }

                    ProgressView(
                        value: item.value,
                        total: 1.0
                    )
                    .tint(
                        item.key
                        == probabilities.keys.first
                        ? .blue
                        : .gray
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    Color(.secondarySystemBackground)
                )
        )
    }
}

// MARK: - JEV vs Gemini Comparison

private extension ContentView {

    func comparisonSection(
        _ response: NewsComparisonResponse
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            HStack {

                Image(
                    systemName:
                        "arrow.left.arrow.right"
                )
                .font(.title2)
                .foregroundStyle(.purple)

                Text("JEV vs Gemini")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }

            // JEV

            comparisonModelCard(
                title: "JEV",
                category: response.jev.category,
                confidence: response.jev.confidence,
                icon: "cpu"
            )

            // Gemini

            comparisonModelCard(
                title: "Gemini",
                category: response.gemini.category,
                confidence: response.gemini.confidence,
                icon: "sparkles"
            )

            // Match / Mismatch

            comparisonSummary(
                response.comparison
            )

            // Gemini Reason

            geminiReasonCard(
                response.gemini.reason
            )

            // JEV Specificity

            jevComparisonDetails(
                response.jev
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    Color(.systemBackground)
                )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

// MARK: - Comparison Model Card

private extension ContentView {

    func comparisonModelCard(
        title: String,
        category: String,
        confidence: Double,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Image(
                    systemName: icon
                )
                .font(.title2)
                .foregroundStyle(.purple)

                Text(title)
                    .font(.headline)

                Spacer()

                Text(
                    "\(confidence * 100, specifier: "%.1f")%"
                )
                .font(.headline)
                .fontWeight(.bold)
            }

            Text(
                category.capitalized
            )
            .font(.title3)
            .fontWeight(.semibold)

            ProgressView(
                value: confidence,
                total: 1.0
            )
            .tint(.purple)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color.purple.opacity(0.06)
                )
        )
    }
}

// MARK: - Comparison Summary

private extension ContentView {

    func comparisonSummary(
        _ comparison: ComparisonResult
    ) -> some View {

        let color: Color =
            comparison.sameCategory
            ? .green
            : .orange

        return VStack(spacing: 14) {

            Image(
                systemName:
                    comparison.sameCategory
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill"
            )
            .font(
                .system(size: 40)
            )
            .foregroundStyle(color)

            Text(
                comparison.sameCategory
                ? "Category Match"
                : "Category Mismatch"
            )
            .font(.headline)

            HStack {

                VStack(spacing: 4) {

                    Text("JEV")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        comparison
                            .jevCategory
                            .capitalized
                    )
                    .fontWeight(.semibold)
                }

                Spacer()

                Image(
                    systemName:
                        "arrow.left.arrow.right"
                )
                .foregroundStyle(.secondary)

                Spacer()

                VStack(spacing: 4) {

                    Text("Gemini")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        comparison
                            .geminiCategory
                            .capitalized
                    )
                    .fontWeight(.semibold)
                }
            }

            Divider()

            HStack {

                Text(
                    "Confidence Difference"
                )

                Spacer()

                Text(
                    "\(comparison.confidenceDifference * 100, specifier: "%.2f")%"
                )
                .fontWeight(.bold)
            }

            HStack {

                Text("JEV Confidence")

                Spacer()

                Text(
                    "\(comparison.jevConfidence * 100, specifier: "%.1f")%"
                )
            }

            HStack {

                Text("Gemini Confidence")

                Spacer()

                Text(
                    "\(comparison.geminiConfidence * 100, specifier: "%.1f")%"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    color.opacity(0.08)
                )
        )
    }
}

// MARK: - Gemini Reason

private extension ContentView {

    func geminiReasonCard(
        _ reason: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Image(
                    systemName: "sparkles"
                )
                .foregroundStyle(.purple)

                Text("Gemini Reasoning")
                    .font(.headline)
            }

            Text(reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color(.secondarySystemBackground)
                )
        )
    }
}

// MARK: - JEV Comparison Details

private extension ContentView {

    func jevComparisonDetails(
        _ jev: JEVComparisonResult
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("JEV Details")
                .font(.headline)

            HStack {

                Text("Specificity")

                Spacer()

                Text(
                    jev.specificity
                        .replacingOccurrences(
                            of: "_",
                            with: " "
                        )
                        .capitalized
                )
                .fontWeight(.semibold)
            }

            HStack {

                Text("Specificity Score")

                Spacer()

                Text(
                    "\(jev.specificityScore * 100, specifier: "%.1f")%"
                )
                .fontWeight(.semibold)
            }

            Divider()

            Text("JEV Probabilities")
                .font(.subheadline)
                .fontWeight(.semibold)

            let sorted =
                jev.probabilities.sorted {
                    $0.value > $1.value
                }

            ForEach(
                sorted,
                id: \.key
            ) { item in

                HStack {

                    Text(
                        item.key.capitalized
                    )

                    Spacer()

                    Text(
                        "\(item.value * 100, specifier: "%.1f")%"
                    )
                    .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color(.secondarySystemBackground)
                )
        )
    }
}

// MARK: - Error

private extension ContentView {

    func errorCard(
        _ message: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.red)

                Text("Error")
                    .font(.headline)
            }

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    Color.red.opacity(0.08)
                )
        )
    }
}

// MARK: - Helpers

private extension ContentView {

    func categoryIcon(
        _ category: String
    ) -> String {

        switch category.lowercased() {

        case "technology":
            return "cpu"

        case "business":
            return "chart.line.uptrend.xyaxis"

        case "sports":
            return "sportscourt"

        case "politics":
            return "building.columns"

        case "entertainment":
            return "film"

        case "science":
            return "atom"

        case "health":
            return "cross.case"

        default:
            return "newspaper"
        }
    }

    func confidenceColor(
        _ confidence: Double
    ) -> Color {

        if confidence >= 0.90 {

            return .green

        } else if confidence >= 0.60 {

            return .orange
        }

        return .red
    }

    func confidenceLevel(
        _ confidence: Double
    ) -> String {

        if confidence >= 0.90 {

            return "High confidence"

        } else if confidence >= 0.60 {

            return "Medium confidence"
        }

        return "Low confidence"
    }
}

// MARK: - Preview

#Preview {

    ContentView()
}
