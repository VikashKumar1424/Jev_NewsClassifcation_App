//
//  ContentView.swift
//  NewsJev
//
//  Created by Vikash on 22/09/26.
//

import SwiftUI

import SwiftUI

struct ContentView: View {

    @State private var store = NewsState()

    @State private var newsText = ""

    private var canClassify: Bool {
        !newsText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    private var isLoading: Bool {

        if case .loading = store.state {
            return true
        }

        return false
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    headerView

                    inputCard

                    actionButtons

                    if let errorMessage = store.errorMessage {
                        errorCard(errorMessage)
                    }

                    if let response = store.response {
                        resultCard(response)
                    }

                    if let comparison = store.comparisonResponse {
                        comparisonDashboard(
                            result: comparison
                        )
                    }

                    Spacer(minLength: 30)
                }
                .padding()
            }
            .navigationTitle("JEV News AI")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Header

extension ContentView {

    private var headerView: some View {

        VStack(spacing: 8) {

            Image(systemName: "newspaper.fill")
                .font(.system(size: 42))
                .foregroundStyle(.blue)

            Text("News Classification")
                .font(.title)
                .fontWeight(.bold)

            Text("JEV + Gemini")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(
                "Classify, compare, measure and route news intelligently."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Input

extension ContentView {

    private var inputCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            Label(
                "News Text",
                systemImage: "doc.text"
            )
            .font(.headline)

            TextEditor(text: $newsText)
                .frame(minHeight: 150)
                .padding(8)
                .background(
                    Color(.secondarySystemBackground)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius: 14
                    )
                    .stroke(
                        Color.gray.opacity(0.2)
                    )
                }

            Text(
                "\(newsText.count) characters"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 8
        )
    }
}

// MARK: - Buttons

extension ContentView {

    private var actionButtons: some View {

        VStack(spacing: 12) {

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
                            systemName:
                                "sparkles"
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

            Button {

                Task {

                    await store.compare(
                        text: newsText
                    )
                }

            } label: {

                HStack {

                    if store.isComparing {

                        ProgressView()
                            .tint(.white)

                        Text("Comparing...")

                    } else {

                        Image(
                            systemName:
                                "arrow.left.arrow.right"
                        )

                        Text(
                            "Compare JEV vs Gemini"
                        )
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    canClassify &&
                    !store.isComparing
                    ? Color.purple
                    : Color.gray
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
            }
            .disabled(
                !canClassify ||
                store.isComparing
            )
        }
    }
}

// MARK: - Error

extension ContentView {

    private func errorCard(
        _ message: String
    ) -> some View {

        HStack(alignment: .top, spacing: 12) {

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.red)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Error")
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(
            Color.red.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}

// MARK: - Normal Result

extension ContentView {

    private func resultCard(
        _ result: NewsResponse
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            sectionTitle(
                "JEV Classification",
                icon: "checkmark.seal.fill"
            )

            categoryBadge(
                result.category
            )

            confidenceRow(
                title: "Confidence",
                value: result.confidence
            )

            Divider()

            topTwoView(result)

            Divider()

            probabilityView(
                probabilities:
                    result.probabilities
            )

            Divider()

            informationRow(
                title: "Specificity",
                value:
                    "\(result.specificity) (\(percentage(result.specificityScore)))"
            )

            informationRow(
                title: "Decision",
                value:
                    result.decisionReason
            )

            informationRow(
                title: "Processing",
                value:
                    result.processingPath
            )

            informationRow(
                title: "Human Review",
                value:
                    result.needsHumanReview
                    ? "Required"
                    : "Not Required"
            )

            if !result.summary.isEmpty {

                Divider()

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text("Summary")
                        .font(.headline)

                    Text(result.summary)
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 8
        )
    }
}

// MARK: - Top Two

extension ContentView {

    private func topTwoView(
        _ result: NewsResponse
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Top Categories")
                .font(.headline)

            HStack {

                VStack(
                    alignment: .leading
                ) {

                    Text("Top 1")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    Text(
                        result.topCategory
                            .capitalized
                    )
                    .font(.headline)

                    Text(
                        percentage(
                            result.topConfidence
                        )
                    )
                    .font(.subheadline)
                }

                Spacer()

                VStack(
                    alignment: .trailing
                ) {

                    Text("Top 2")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    Text(
                        result.secondCategory
                            .capitalized
                    )
                    .font(.headline)

                    Text(
                        percentage(
                            result.secondConfidence
                        )
                    )
                    .font(.subheadline)
                }
            }

            Text(
                "Confidence Margin: \(percentage(result.confidenceMargin))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Probability

extension ContentView {

    private func probabilityView(
        probabilities: [String: Double]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
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
                    alignment: .leading,
                    spacing: 5
                ) {

                    HStack {

                        Text(
                            item.key.capitalized
                        )

                        Spacer()

                        Text(
                            percentage(item.value)
                        )
                        .font(.caption)
                    }

                    ProgressView(
                        value: item.value
                    )
                }
            }
        }
    }
}

// MARK: - Comparison Dashboard

extension ContentView {

    private func comparisonDashboard(
        result: NewsComparisonResponse
    ) -> some View {

        VStack(spacing: 16) {

            sectionTitle(
                "JEV vs Gemini Dashboard",
                icon: "chart.bar.xaxis"
            )

            modelComparisonCards(
                result: result
            )

            agreementCard(
                result: result
            )

            performanceCard(
                result: result
            )

            tokenCard(
                gemini: result.gemini
            )

            multiQuestionCard(
                questions:
                    result.jev.questions
            )

            routeCard(
                routing:
                    result.routing
            )

            geminiReasonCard(
                reason:
                    result.gemini.reason
            )
        }
        .padding()
        .background(
            Color(.secondarySystemBackground)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}

// MARK: - Model Cards

extension ContentView {

    private func modelComparisonCards(
        result: NewsComparisonResponse
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            modelCard(
                title: "JEV",
                category:
                    result.jev.category,
                confidence:
                    result.jev.confidence,
                latency:
                    result.jev.latencyMs
            )

            modelCard(
                title: "Gemini",
                category:
                    result.gemini.category,
                confidence:
                    result.gemini.confidence,
                latency:
                    result.gemini.latencyMs
            )
        }
    }

    private func modelCard(
        title: String,
        category: String,
        confidence: Double,
        latency: Double
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(title)
                .font(.headline)

            Text(category.capitalized)
                .font(.title3)
                .fontWeight(.bold)

            Text(
                "Confidence \(percentage(confidence))"
            )
            .font(.subheadline)

            Divider()

            HStack {

                Image(
                    systemName:
                        "clock"
                )

                Text(
                    "\(String(format: "%.2f", latency)) ms"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}

// MARK: - Agreement

extension ContentView {

    private func agreementCard(
        result: NewsComparisonResponse
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Image(
                    systemName:
                        result.comparison.sameCategory
                        ? "checkmark.circle.fill"
                        : "exclamationmark.circle.fill"
                )
                .foregroundStyle(
                    result.comparison.sameCategory
                    ? .green
                    : .orange
                )

                Text(
                    result.comparison.sameCategory
                    ? "Models agree"
                    : "Models disagree"
                )
                .font(.headline)

                Spacer()
            }

            informationRow(
                title: "JEV",
                value:
                    result.comparison.jevCategory
            )

            informationRow(
                title: "Gemini",
                value:
                    result.comparison.geminiCategory
            )

            informationRow(
                title: "Confidence Difference",
                value:
                    percentage(
                        result.comparison
                            .confidenceDifference
                    )
            )
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}

// MARK: - Performance

extension ContentView {

    private func performanceCard(
        result: NewsComparisonResponse
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Performance")
                .font(.headline)

            HStack {

                metric(
                    title: "JEV",
                    value:
                        "\(String(format: "%.2f", result.jev.latencyMs)) ms"
                )

                metric(
                    title: "Gemini",
                    value:
                        "\(String(format: "%.2f", result.gemini.latencyMs)) ms"
                )

                metric(
                    title: "Difference",
                    value:
                        "\(String(format: "%.2f", result.comparison.latencyDifferenceMs)) ms"
                )
            }
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private func metric(
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 5) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(
            maxWidth: .infinity
        )
    }
}

// MARK: - Token Dashboard

extension ContentView {

    private func tokenCard(
        gemini: GeminiClassification
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Gemini Token Usage")
                .font(.headline)

            HStack {

                usageValue(
                    title: "Input",
                    value:
                        "\(gemini.inputTokens)"
                )

                usageValue(
                    title: "Output",
                    value:
                        "\(gemini.outputTokens)"
                )

                usageValue(
                    title: "Thought",
                    value:
                        "\(gemini.thoughtTokens)"
                )

                usageValue(
                    title: "Total",
                    value:
                        "\(gemini.totalTokens)"
                )
            }

            Divider()

            HStack {

                VStack(
                    alignment: .leading
                ) {

                    Text("Input Cost")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    Text(
                        currency(
                            gemini.inputCostUsd
                        )
                    )
                    .font(.headline)
                }

                Spacer()

                VStack(
                    alignment: .trailing
                ) {

                    Text("Output Cost")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    Text(
                        currency(
                            gemini.outputCostUsd
                        )
                    )
                    .font(.headline)
                }
            }

            HStack {

                Text("Total Cost")

                Spacer()

                Text(
                    currency(
                        gemini.totalCostUsd
                    )
                )
                .font(.title3)
                .fontWeight(.bold)
            }
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private func usageValue(
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 4) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(
            maxWidth: .infinity
        )
    }
}

// MARK: - JEV Multi Question

extension ContentView {

    private func multiQuestionCard(
        questions: JEVQuestionResults
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text("JEV Questions")

                Spacer()

                Text("5 Questions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.headline)

            // Category is String
            questionRow(
                "Category",
                questions.category
            )

            // These are Double
            questionRow(
                "Specificity",
                questions.specificity
            )

            questionRow(
                "Sports",
                questions.isSports
            )

            questionRow(
                "Business",
                questions.isBusiness
            )

            questionRow(
                "Technology",
                questions.isTechnology
            )

            questionRow(
                "Politics",
                questions.isPolitics
            )
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // For Double values
    private func questionRow(
        _ title: String,
        _ value: Double,
        isPercentage: Bool = true
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            HStack {

                Text(title)

                Spacer()

                Text(
                    isPercentage
                    ? percentage(value)
                    : String(
                        format: "%.2f",
                        value
                    )
                )
                .font(.subheadline)
                .fontWeight(.semibold)
            }

            if isPercentage {

                ProgressView(
                    value: value
                )
            }
        }
    }

    // For String values
    private func questionRow(
        _ title: String,
        _ value: String
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(value.capitalized)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Routing

extension ContentView {

    private func routeCard(
        routing: RoutingResponse
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Image(
                    systemName:
                        routeIcon(
                            routing.route
                        )
                )
                .font(.title2)

                Text("Auto Router")
                    .font(.headline)

                Spacer()

                Text(
                    routing.route
                        .replacingOccurrences(
                            of: "_",
                            with: " "
                        )
                        .capitalized
                )
                .font(.subheadline)
                .fontWeight(.bold)
            }

            Text(routing.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if routing.needsFollowUp {

                Divider()

                Label(
                    "Follow-up Required",
                    systemImage:
                        "questionmark.circle.fill"
                )
                .font(.headline)

                if let question = routing.question {

                    Text(question)
                        .font(.subheadline)
                }

                if !routing.options.isEmpty {

                    HStack {

                        ForEach(
                            routing.options,
                            id: \.self
                        ) { option in

                            Text(
                                option.capitalized
                            )
                            .font(.caption)
                            .padding(
                                .horizontal,
                                10
                            )
                            .padding(
                                .vertical,
                                6
                            )
                            .background(
                                Color.blue
                                    .opacity(0.1)
                            )
                            .clipShape(
                                Capsule()
                            )
                        }
                    }
                }
            }

            if routing.needsHumanReview {

                Divider()

                Label(
                    "Human Review Required",
                    systemImage:
                        "person.crop.circle.badge.exclamationmark"
                )
                .foregroundStyle(.red)
                .fontWeight(.semibold)
            }
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private func routeIcon(
        _ route: String
    ) -> String {

        switch route {

        case "jev_only":
            return "checkmark.circle.fill"

        case "jev_then_gemini":
            return "arrow.triangle.branch"

        case "ask_follow_up":
            return "questionmark.circle.fill"

        case "human_review":
            return "person.crop.circle.badge.exclamationmark"

        default:
            return "circle"
        }
    }
}

// MARK: - Gemini Reason

extension ContentView {

    private func geminiReasonCard(
        reason: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Gemini Reason")
                .font(.headline)

            Text(reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}

// MARK: - Reusable UI

extension ContentView {

    private func sectionTitle(
        _ title: String,
        icon: String
    ) -> some View {

        HStack {

            Image(systemName: icon)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Spacer()
        }
    }

    private func categoryBadge(
        _ category: String
    ) -> some View {

        Text(category.uppercased())
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(
                .horizontal,
                16
            )
            .padding(
                .vertical,
                8
            )
            .background(
                categoryColor(category)
            )
            .clipShape(
                Capsule()
            )
    }

    private func confidenceRow(
        title: String,
        value: Double
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(
                percentage(value)
            )
            .fontWeight(.bold)
        }
    }

    private func informationRow(
        title: String,
        value: String
    ) -> some View {

        HStack(
            alignment: .top
        ) {

            Text(title)
                .foregroundStyle(
                    .secondary
                )

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(
                    .trailing
                )
        }
        .font(.subheadline)
    }
}

// MARK: - Helpers

extension ContentView {

    private func percentage(
        _ value: Double
    ) -> String {

        String(
            format: "%.1f%%",
            value * 100
        )
    }

    private func currency(
        _ value: Double
    ) -> String {

        String(
            format: "$%.6f",
            value
        )
    }

    private func categoryColor(
        _ category: String
    ) -> Color {

        switch category.lowercased() {

        case "technology":
            return .blue

        case "business":
            return .orange

        case "sports":
            return .green

        case "politics":
            return .purple

        case "entertainment":
            return .pink

        case "science":
            return .indigo

        case "health":
            return .red

        default:
            return .gray
        }
    }
}

#Preview {
    ContentView()
}
