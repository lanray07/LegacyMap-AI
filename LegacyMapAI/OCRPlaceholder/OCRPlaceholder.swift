import Foundation

struct OCRRequest {
    var imageData: Data?
    var cropDescription: String
    var sourceContext: String
}

protocol OCRProcessing {
    func process(_ request: OCRRequest) async throws -> HeadstoneScanResult
}

struct OCRPlaceholderPipeline: OCRProcessing {
    private let aiService: any AIService

    init(aiService: any AIService = MockAIService()) {
        self.aiService = aiService
    }

    func process(_ request: OCRRequest) async throws -> HeadstoneScanResult {
        try await aiService.scanHeadstone(
            imageData: request.imageData,
            cemeteryName: request.sourceContext,
            memorialNotes: request.cropDescription
        )
    }
}
