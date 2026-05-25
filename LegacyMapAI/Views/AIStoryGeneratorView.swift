import SwiftData
import SwiftUI

struct AIStoryGeneratorView: View {
    @Environment(\.aiService) private var aiService
    @Query(sort: \Memorial.fullName) private var memorials: [Memorial]
    @Query(sort: \Cemetery.cemeteryName) private var cemeteries: [Cemetery]
    @StateObject private var viewModel = StoryGeneratorViewModel()

    @State private var selectedMemorialId: UUID?
    @State private var selectedCemeteryId: UUID?
    @State private var notes = ""
    @State private var historicalText = ""

    private var selectedMemorial: Memorial? {
        guard let selectedMemorialId else { return nil }
        return memorials.first { $0.id == selectedMemorialId }
    }

    private var selectedCemetery: Cemetery? {
        if let selectedCemeteryId {
            return cemeteries.first { $0.id == selectedCemeteryId }
        }
        if let selectedMemorial {
            return cemeteries.first { $0.id == selectedMemorial.cemeteryId }
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "AI Story Generator", subtitle: "Generate respectful summaries from available data only.", systemImage: "text.bubble")

                VStack(alignment: .leading, spacing: 12) {
                    Picker("Memorial", selection: $selectedMemorialId) {
                        Text("Select memorial").tag(UUID?.none)
                        ForEach(memorials) { memorial in
                            Text(memorial.fullName).tag(Optional(memorial.id))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Cemetery for historical insight", selection: $selectedCemeteryId) {
                        Text("Use memorial cemetery").tag(UUID?.none)
                        ForEach(cemeteries) { cemetery in
                            Text(cemetery.cemeteryName).tag(Optional(cemetery.id))
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .trailing, spacing: 8) {
                        TextField("Notes for memorial summary", text: $notes, axis: .vertical)
                            .lineLimit(3...7)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $notes, label: "Dictate notes")
                    }
                    VStack(alignment: .trailing, spacing: 8) {
                        TextField("Historical text for cemetery significance", text: $historicalText, axis: .vertical)
                            .lineLimit(3...7)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $historicalText, label: "Dictate history")
                    }

                    HStack {
                        Button {
                            Task { await generateSummary() }
                        } label: {
                            Label("Memorial summary", systemImage: "sparkles")
                        }
                        .buttonStyle(LegacyPrimaryButtonStyle())

                        Button {
                            Task { await generateInsight() }
                        } label: {
                            Label("Historical overview", systemImage: "building.columns")
                        }
                        .buttonStyle(LegacyPrimaryButtonStyle())
                    }
                }
                .legacyCard()

                InsightCard(
                    title: "No fictional claims",
                    detail: "Generated copy must stay tied to saved data and cautious wording. It should never invent genealogy facts, identity verification, or official certification.",
                    systemImage: "checkmark.shield"
                )

                if viewModel.isGenerating {
                    LoadingStateView(message: "Writing a respectful, cautious summary...")
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                if !viewModel.generatedSummary.isEmpty {
                    ReportPreviewView(title: "Generated memorial summary", sections: [("Draft", viewModel.generatedSummary)])
                }

                if !viewModel.insights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Historical insights", subtitle: "Review with independent sources.", systemImage: "lightbulb")
                        ForEach(viewModel.insights) { insight in
                            InsightCard(title: insight.title, detail: "\(insight.details)\n\(insight.caution)", systemImage: "lightbulb")
                        }
                    }
                }
            }
            .padding()
        }
        .background(LegacyBackground())
        .onAppear {
            viewModel.aiService = aiService
        }
    }

    private func generateSummary() async {
        guard let selectedMemorial else {
            viewModel.errorMessage = "Select a memorial before generating a summary."
            return
        }
        await viewModel.generateSummary(memorial: selectedMemorial, cemetery: selectedCemetery, notes: notes)
    }

    private func generateInsight() async {
        await viewModel.generateInsight(cemetery: selectedCemetery, historicalText: historicalText)
    }
}
