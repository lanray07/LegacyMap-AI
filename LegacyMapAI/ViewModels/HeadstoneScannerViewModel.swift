import Foundation

@MainActor
final class HeadstoneScannerViewModel: ObservableObject {
    @Published var result: HeadstoneScanResult?
    @Published var isScanning = false
    @Published var errorMessage: String?

    var aiService: any AIService = MockAIService()

    func scan(imageData: Data?, cemeteryName: String, notes: String) async {
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }

        do {
            result = try await aiService.scanHeadstone(
                imageData: imageData,
                cemeteryName: cemeteryName.isEmpty ? nil : cemeteryName,
                memorialNotes: notes.isEmpty ? nil : notes
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
