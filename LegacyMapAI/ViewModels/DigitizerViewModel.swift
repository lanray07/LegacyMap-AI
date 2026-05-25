import Foundation

@MainActor
final class DigitizerViewModel: ObservableObject {
    @Published var draft = HistoricalRecordDraft(
        fullName: "",
        birthYear: nil,
        deathYear: nil,
        cemetery: "",
        plotPlaceholder: "",
        digitizedText: "",
        notes: ""
    )
    @Published var isProcessing = false
    @Published var errorMessage: String?

    var aiService: any AIService = MockAIService()

    func digitize(imageData: Data?, historicalText: String) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            draft = try await aiService.digitizeHistoricalRecord(imageData: imageData, historicalText: historicalText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
