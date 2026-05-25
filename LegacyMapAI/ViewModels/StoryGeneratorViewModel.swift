import Foundation

@MainActor
final class StoryGeneratorViewModel: ObservableObject {
    @Published var generatedSummary = ""
    @Published var insights: [HistoricalInsightResult] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?

    var aiService: any AIService = MockAIService()

    func generateSummary(memorial: Memorial, cemetery: Cemetery?, notes: String) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            generatedSummary = try await aiService.generateMemorialSummary(memorial: memorial, cemetery: cemetery, notes: notes)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generateInsight(cemetery: Cemetery?, historicalText: String) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            insights = try await aiService.generateHistoricalInsight(cemetery: cemetery, historicalText: historicalText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
