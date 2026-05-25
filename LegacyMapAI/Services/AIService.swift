import Foundation
import SwiftUI

struct HeadstoneScanResult: Identifiable, Hashable {
    let id = UUID()
    var possibleInscription: String
    var estimatedDates: [String]
    var likelySurname: String
    var conditionEstimate: String
    var preservationSuggestions: [String]
    var confidenceNote: String
}

struct HistoricalInsightResult: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var details: String
    var caution: String
}

struct HistoricalRecordDraft: Hashable {
    var fullName: String
    var birthYear: Int?
    var deathYear: Int?
    var cemetery: String
    var plotPlaceholder: String
    var digitizedText: String
    var notes: String
}

enum LegacyAIPrompt {
    static let system = "You are LegacyMap AI, a respectful genealogy and cemetery preservation assistant. Help users preserve memorial history, digitize historical records, organize cemetery data, and generate cautious memorial summaries. Do not fabricate genealogy facts, legal identity verification, or unsupported historical claims."
}

protocol AIService {
    func scanHeadstone(imageData: Data?, cemeteryName: String?, memorialNotes: String?) async throws -> HeadstoneScanResult
    func generateMemorialSummary(memorial: Memorial, cemetery: Cemetery?, notes: String) async throws -> String
    func generateHistoricalInsight(cemetery: Cemetery?, historicalText: String) async throws -> [HistoricalInsightResult]
    func generateFamilyConnectionSuggestions(memorial: Memorial, nearbyMemorials: [Memorial]) async throws -> [String]
    func digitizeHistoricalRecord(imageData: Data?, historicalText: String) async throws -> HistoricalRecordDraft
}

private struct LegacyAIRequest: Encodable {
    var module: String
    var cemeteryName: String
    var memorialNotes: String
    var imageBase64: String
    var historicalText: String
}

private struct LegacyAIResponse: Decodable {
    var possibleInscription: String?
    var estimatedDates: [String]?
    var historicalInsights: [String]?
    var summary: String?
}

enum AIServiceError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "LegacyMap AI could not interpret the response. Please try again or review the text manually."
        }
    }
}

struct MockAIService: AIService {
    func scanHeadstone(imageData: Data?, cemeteryName: String?, memorialNotes: String?) async throws -> HeadstoneScanResult {
        try await Task.sleep(nanoseconds: 450_000_000)
        return HeadstoneScanResult(
            possibleInscription: "Possible inscription: In loving memory of Eleanor Hart, beloved mother and neighbor. Weathering obscures several lower lines.",
            estimatedDates: ["Estimated date range: 1880-1930", "Possible death year fragment: 1912"],
            likelySurname: "Likely surname: Hart",
            conditionEstimate: "Moderate weathering with softened lettering and biological growth near the base.",
            preservationSuggestions: [
                "Photograph again with side lighting before any cleaning.",
                "Use non-invasive documentation first; avoid abrasive cleaning.",
                "Ask cemetery staff or a trained conservator before stone repair."
            ],
            confidenceNote: "Mock result for planning. OCR and AI outputs require human review and independent verification."
        )
    }

    func generateMemorialSummary(memorial: Memorial, cemetery: Cemetery?, notes: String) async throws -> String {
        try await Task.sleep(nanoseconds: 350_000_000)
        let cemeteryName = cemetery?.cemeteryName ?? "the recorded cemetery"
        return """
        This memorial appears to preserve the name \(memorial.fullName) at \(cemeteryName). The available dates are \(memorial.yearRange). The inscription and notes should be treated as historical clues rather than verified genealogy facts. Based on the saved material, a careful summary can highlight the memorial's location, visible inscription, and known family links while avoiding unsupported claims.

        Suggested summary: \(memorial.fullName) is remembered through a memorial recorded at \(cemeteryName). The saved inscription and notes may help descendants, researchers, or local historians reconnect this grave with wider community history, pending independent verification.
        """
    }

    func generateHistoricalInsight(cemetery: Cemetery?, historicalText: String) async throws -> [HistoricalInsightResult] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return [
            HistoricalInsightResult(
                title: "Possible preservation priority",
                details: "Several records mention weathering, missing plot labels, or incomplete dates. Consider prioritizing photography and manual transcription.",
                caution: "This is an informational suggestion, not an official preservation assessment."
            ),
            HistoricalInsightResult(
                title: "Local history clue",
                details: "Names, dates, and family clusters may help identify community migration or settlement patterns when checked against independent sources.",
                caution: "Do not treat AI grouping as a confirmed family relationship."
            )
        ]
    }

    func generateFamilyConnectionSuggestions(memorial: Memorial, nearbyMemorials: [Memorial]) async throws -> [String] {
        try await Task.sleep(nanoseconds: 300_000_000)
        let surname = memorial.fullName.split(separator: " ").last.map(String.init) ?? "the recorded surname"
        let matches = nearbyMemorials.filter { $0.id != memorial.id && $0.fullName.localizedCaseInsensitiveContains(surname) }
        if matches.isEmpty {
            return [
                "No strong local surname suggestions found in saved memorials.",
                "Try adding nearby graves, dates, and inscriptions before linking family lines."
            ]
        }
        return matches.prefix(3).map { "Possible surname match with \($0.fullName). Verify through records before linking." }
    }

    func digitizeHistoricalRecord(imageData: Data?, historicalText: String) async throws -> HistoricalRecordDraft {
        try await Task.sleep(nanoseconds: 450_000_000)
        return HistoricalRecordDraft(
            fullName: "Possible name from record",
            birthYear: nil,
            deathYear: nil,
            cemetery: "",
            plotPlaceholder: "",
            digitizedText: historicalText.isEmpty ? "Mock OCR draft: handwriting and paper damage may affect transcription. Review every line manually." : historicalText,
            notes: "AI OCR placeholder. Check the original archive source before using this as a genealogy record."
        )
    }
}

final class RemoteAIService: AIService {
    private let endpoint: URL
    private let urlSession: URLSession

    init(
        endpoint: URL? = URL(string: "https://YOUR_BACKEND_URL.com/legacymap-ai"),
        urlSession: URLSession = .shared
    ) {
        self.endpoint = endpoint ?? URL(fileURLWithPath: "/legacymap-ai")
        self.urlSession = urlSession
    }

    func scanHeadstone(imageData: Data?, cemeteryName: String?, memorialNotes: String?) async throws -> HeadstoneScanResult {
        let response = try await performRequest(
            module: "headstone_scan",
            cemeteryName: cemeteryName ?? "",
            memorialNotes: memorialNotes ?? "",
            imageData: imageData,
            historicalText: ""
        )

        return HeadstoneScanResult(
            possibleInscription: response.possibleInscription ?? "No possible inscription returned.",
            estimatedDates: response.estimatedDates ?? [],
            likelySurname: "Likely surname requires review.",
            conditionEstimate: "Condition estimate unavailable from remote response.",
            preservationSuggestions: response.historicalInsights ?? [],
            confidenceNote: "Remote AI result. Review OCR and genealogy suggestions independently."
        )
    }

    func generateMemorialSummary(memorial: Memorial, cemetery: Cemetery?, notes: String) async throws -> String {
        let response = try await performRequest(
            module: "memorial_summary",
            cemeteryName: cemetery?.cemeteryName ?? "",
            memorialNotes: "\(memorial.fullName)\n\(memorial.inscription)\n\(notes)",
            imageData: nil,
            historicalText: memorial.notes
        )
        return response.summary ?? "No summary returned. Review source material manually."
    }

    func generateHistoricalInsight(cemetery: Cemetery?, historicalText: String) async throws -> [HistoricalInsightResult] {
        let response = try await performRequest(
            module: "historical_insight",
            cemeteryName: cemetery?.cemeteryName ?? "",
            memorialNotes: "",
            imageData: nil,
            historicalText: historicalText
        )

        return (response.historicalInsights ?? []).map {
            HistoricalInsightResult(title: "Historical insight", details: $0, caution: "Verify with independent sources.")
        }
    }

    func generateFamilyConnectionSuggestions(memorial: Memorial, nearbyMemorials: [Memorial]) async throws -> [String] {
        let text = nearbyMemorials.map { "\($0.fullName), \($0.yearRange)" }.joined(separator: "\n")
        let response = try await performRequest(
            module: "family_connection_suggestions",
            cemeteryName: "",
            memorialNotes: "\(memorial.fullName)\n\(memorial.inscription)",
            imageData: nil,
            historicalText: text
        )
        return response.historicalInsights ?? ["No suggestions returned. Verify family links independently."]
    }

    func digitizeHistoricalRecord(imageData: Data?, historicalText: String) async throws -> HistoricalRecordDraft {
        let response = try await performRequest(
            module: "record_digitizer",
            cemeteryName: "",
            memorialNotes: "",
            imageData: imageData,
            historicalText: historicalText
        )
        return HistoricalRecordDraft(
            fullName: "",
            birthYear: nil,
            deathYear: nil,
            cemetery: "",
            plotPlaceholder: "",
            digitizedText: response.summary ?? response.possibleInscription ?? "",
            notes: "Remote OCR draft. Review manually before saving."
        )
    }

    private func performRequest(
        module: String,
        cemeteryName: String,
        memorialNotes: String,
        imageData: Data?,
        historicalText: String
    ) async throws -> LegacyAIResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            LegacyAIRequest(
                module: module,
                cemeteryName: cemeteryName,
                memorialNotes: memorialNotes,
                imageBase64: imageData?.base64EncodedString() ?? "",
                historicalText: historicalText
            )
        )

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AIServiceError.invalidResponse
        }
        return try JSONDecoder().decode(LegacyAIResponse.self, from: data)
    }
}

private struct AIServiceKey: EnvironmentKey {
    static let defaultValue: any AIService = MockAIService()
}

extension EnvironmentValues {
    var aiService: any AIService {
        get { self[AIServiceKey.self] }
        set { self[AIServiceKey.self] = newValue }
    }
}
