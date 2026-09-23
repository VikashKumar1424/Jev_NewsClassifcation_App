//
//  ContentView.swift
//  NewsJev
//
//  Created by Vikash on 22/09/26.
//

import SwiftUI

//
//  ContentView.swift
//  NewsJev
//

import SwiftUI

struct ContentView: View {

    @State private var store = NewsStore()

    @State private var newsText = ""

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    headerSection

                    inputSection

                    classifyButton

                    resultSection
                }
                .padding()
            }
            .background(
                Color(.systemGroupedBackground)
            )
            .navigationTitle("News Classifier")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Header

private extension ContentView {

    var headerSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack(spacing: 12) {

                Image(
                    systemName: "newspaper.fill"
                )
                .font(.largeTitle)
                .foregroundStyle(.blue)

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text("JEV News Classifier")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("JEV + Gemini")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(
                "Classify news using JEV confidence-based routing with Gemini enrichment."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Input

private extension ContentView {

    var inputSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("News Text")
                .font(.headline)

            TextEditor(
                text: $newsText
            )
            .frame(minHeight: 150)
            .padding(8)
            .background(
                RoundedRectangle(
                    cornerRadius: 16
                )
                .fill(
                    Color(.secondarySystemBackground)
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: 1
                )
            )

            Text(
                "Enter a headline or short news article."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Top 2 Classification

private extension ContentView {

    func topTwoView(
        _ response: NewsResponse
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Top Classification")
                .font(.headline)

            HStack(
                spacing: 12
            ) {

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

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

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
                .foregroundStyle(
                    .secondary
                )
            }
            .padding()
            .background(
                RoundedRectangle(
                    cornerRadius: 16
                )
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

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Image(
                    systemName: icon
                )
                .foregroundStyle(
                    .blue
                )

                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
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
            RoundedRectangle(
                cornerRadius: 16
            )
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
        }

        if margin >= 0.15 {
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

        } else {

            return "Top 1 and Top 2 are close. Classification may be ambiguous."
        }
    }
}

// MARK: - Classify Button
// MARK: - Classify + Cancel Buttons

private extension ContentView {

    var classifyButton: some View {

        HStack(spacing: 12) {

            // MARK: Cancel

            Button {

                store.cancelClassification()

            } label: {

                HStack(spacing: 6) {

                    Image(
                        systemName: "xmark"
                    )

                    Text("Cancel")
                }
                .font(.headline)
                .foregroundStyle(
                    isLoading ? .red : .secondary
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isLoading
                    ? Color.red.opacity(0.10)
                    : Color.gray.opacity(0.08)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
            }
            .disabled(!isLoading)

            // MARK: Classify

            Button {

                Task {
                    await store.classify(
                        text: newsText
                    )
                }

            } label: {

                HStack {

                    if isLoading {

                        ProgressView()
                            .tint(.white)

                        Text("Classifying...")

                    } else {

                        Image(
                            systemName: "sparkles"
                        )

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
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
            }
            .disabled(
                !canClassify || isLoading
            )
        }
    }
}
/*
private extension ContentView {

    var classifyButton: some View {

        Button {

            Task {

                await store.classify(
                    text: newsText
                )
            }

        } label: {

            HStack {

                if isLoading {

                    ProgressView()
                        .tint(.white)

                    Text("Classifying...")

                } else {

                    Image(
                        systemName: "sparkles"
                    )

                    Text("Classify News")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                canClassify
                ? Color.blue
                : Color.gray
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .disabled(
            !canClassify || isLoading
        )
    }
} */

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

        if case .loading = store.state {
            return true
        }

        return false
    }
}

// MARK: - Result Section

private extension ContentView {

    @ViewBuilder
    var resultSection: some View {

        switch store.state {

        case .idle:

            EmptyView()

        case .loading:

            loadingView

        case .loaded:

            if let response = store.response {

                resultCard(
                    response
                )
            }

        case .error(let message):

            errorCard(
                message
            )
        }
    }
}

// MARK: - Loading

private extension ContentView {

    var loadingView: some View {

        HStack {

            ProgressView()

            Text("Analyzing news...")

                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 16
            )
            .fill(
                Color(.systemBackground)
            )
        )
    }
}

// MARK: - Error Card

private extension ContentView {

    func errorCard(
        _ message: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.red)

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text("Classification Failed")
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 16
            )
            .fill(
                Color.red.opacity(0.08)
            )
        )
    }
}

// MARK: - Result Card

private extension ContentView {

    func resultCard(
        _ response: NewsResponse
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            // MARK: Category

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {

                    Image(
                        systemName: categoryIcon(
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

            // MARK: Top 1 / Top 2

            topTwoView(
                response
            )

            // MARK: Decision Reason

            decisionReasonView(
                response.decisionReason
            )

            // MARK: Processing Path

            processingPathView(
                response
            )

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
            RoundedRectangle(
                cornerRadius: 24
            )
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

// MARK: - Confidence

private extension ContentView {

    func confidenceView(
        _ confidence: Double
    ) -> some View {

        let level = confidenceLevel(
            confidence
        )

        return VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Text("Confidence")
                    .font(.headline)

                Spacer()

                Text(
                    "\(confidence * 100, specifier: "%.1f")%"
                )
                .font(.headline)
                .fontWeight(.bold)
            }

            HStack {

                Image(
                    systemName: level.icon
                )

                Text(level.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .foregroundStyle(level.color)

            ProgressView(
                value: confidence,
                total: 1.0
            )
            .tint(level.color)
            .scaleEffect(
                x: 1,
                y: 1.5,
                anchor: .center
            )
        }
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 16
            )
            .fill(
                level.color.opacity(0.08)
            )
        )
    }
}

private extension ContentView {

    func confidenceLevel(
        _ confidence: Double
    ) -> ConfidenceLevel {

        if confidence >= 0.90 {

            return ConfidenceLevel(
                title: "High Confidence",
                icon: "checkmark.circle.fill",
                color: .green
            )

        } else if confidence >= 0.60 {

            return ConfidenceLevel(
                title: "Medium Confidence",
                icon: "minus.circle.fill",
                color: .orange
            )

        } else if confidence >= 0.30 {

            return ConfidenceLevel(
                title: "Low Confidence",
                icon: "exclamationmark.circle.fill",
                color: .orange
            )

        } else {

            return ConfidenceLevel(
                title: "Very Low Confidence",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
    }
}

// MARK: - Processing Path

private extension ContentView {

    func processingPathView(
        _ response: NewsResponse
    ) -> some View {

        let isJEVOnly =
            response.processingPath == "jev_only"

        return HStack(
            spacing: 14
        ) {

            // Icon

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
            .clipShape(
                Circle()
            )

            // Description

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text("Processing Path")
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

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
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()

            // Badge

            Text(
                isJEVOnly
                ? "High Confidence"
                : "Enriched"
            )
            .font(.caption)
            .fontWeight(.semibold)
            .padding(
                .horizontal,
                10
            )
            .padding(
                .vertical,
                6
            )
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
            .clipShape(
                Capsule()
            )
        }
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 18
            )
            .fill(
                isJEVOnly
                ? Color.green.opacity(0.06)
                : Color.blue.opacity(0.06)
            )
        )
    }
}

// MARK: - Decision Reason

private extension ContentView {

    func decisionReasonView(
        _ reason: String
    ) -> some View {

        HStack(
            spacing: 12
        ) {

            Image(
                systemName: decisionReasonIcon(
                    reason
                )
            )
            .font(.title3)
            .foregroundStyle(
                decisionReasonColor(
                    reason
                )
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Decision Reason")
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                Text(
                    formatDecisionReason(
                        reason
                    )
                )
                .font(.headline)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 16
            )
            .fill(
                decisionReasonColor(
                    reason
                )
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
            return reason.replacingOccurrences(
                of: "_",
                with: " "
            ).capitalized
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

// MARK: - Processing Description

private extension ContentView {

    func processingPathDescription(
        _ path: String
    ) -> String {

        switch path {

        case "jev_only":

            return "JEV confidence was high enough to complete classification."

        case "jev_then_gemini":

            return "JEV classification was enriched using Gemini."

        default:

            return "Classification completed using the AI pipeline."
        }
    }
}

// MARK: - Human Review

private extension ContentView {

    var humanReviewView: some View {

        HStack(
            spacing: 12
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    "Human Review Required"
                )
                .font(.headline)
                .foregroundStyle(.orange)

                Text(
                    "JEV confidence was below the review threshold."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 16
            )
            .fill(
                Color.orange.opacity(0.10)
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
            spacing: 8
        ) {

            Text("Summary")
                .font(.headline)

            Text(summary)
                .font(.body)
                .foregroundStyle(
                    .secondary
                )
        }
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

            ForEach(
                probabilities.sorted {
                    $0.value > $1.value
                },
                id: \.key
            ) { item in

                VStack(
                    spacing: 5
                ) {

                    HStack {

                        Text(
                            item.key
                                .capitalized
                        )
                        .font(.subheadline)

                        Spacer()

                        Text(
                            "\(item.value * 100, specifier: "%.1f")%"
                        )
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }

                    ProgressView(
                        value: item.value,
                        total: 1.0
                    )
                    .tint(.blue)
                }
            }
        }
    }
}

// MARK: - Category Icon

private extension ContentView {

    func categoryIcon(
        _ category: String
    ) -> String {

        switch category.lowercased() {

        case "technology":
            return "desktopcomputer"

        case "business":
            return "chart.bar.fill"

        case "sports":
            return "sportscourt.fill"

        case "politics":
            return "building.columns.fill"

        case "entertainment":
            return "play.tv.fill"

        case "science":
            return "atom"

        case "health":
            return "cross.case.fill"

        default:
            return "newspaper.fill"
        }
    }
}

// MARK: - Confidence Color

private extension ContentView {

    func confidenceColor(
        _ confidence: Double
    ) -> Color {

        if confidence >= 0.90 {
            return .green
        }

        if confidence >= 0.60 {
            return .orange
        }

        return .red
    }
}

// MARK: - Preview

#Preview {

    ContentView()
}
