import Foundation
import UIKit

enum PDFExportService {
    static func makeMemorialReport(memorial: Memorial, cemetery: Cemetery?, photos: [MemorialPhoto]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LegacyMapAI-\(memorial.id.uuidString).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            drawHeader("LegacyMap AI Memorial Report")
            drawBody(
                [
                    "Preserve the past. Reconnect forgotten stories.",
                    "",
                    "Memorial: \(memorial.fullName)",
                    "Years: \(memorial.yearRange)",
                    "Cemetery: \(cemetery?.cemeteryName ?? "Unknown")",
                    "GPS: \(memorial.gpsLatitude), \(memorial.gpsLongitude)",
                    "",
                    "Inscription",
                    memorial.inscription.isEmpty ? "No inscription saved." : memorial.inscription,
                    "",
                    "Historical notes",
                    memorial.notes.isEmpty ? "No notes saved." : memorial.notes,
                    "",
                    "Family links placeholder",
                    "Family relationships require independent verification.",
                    "",
                    "Cemetery map snapshot",
                    "Map snapshot placeholder. Use MapKit snapshotting in the backend or an export extension for production map imagery.",
                    "",
                    "Disclaimer",
                    LegacyDisclaimer.bullets.joined(separator: "\n")
                ].joined(separator: "\n"),
                startY: 104
            )

            if let data = photos.first?.imageData, let image = UIImage(data: data) {
                image.draw(in: CGRect(x: 372, y: 112, width: 180, height: 140))
            }
        }

        return url
    }

    static func makeHistoricalRecordReport(record: HistoricalRecordDraft) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LegacyMapAI-Record-\(UUID().uuidString).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            drawHeader("LegacyMap AI Digitized Record")
            drawBody(
                [
                    "Full name: \(record.fullName)",
                    "Birth year: \(record.birthYear.map(String.init) ?? "Unknown")",
                    "Death year: \(record.deathYear.map(String.init) ?? "Unknown")",
                    "Cemetery: \(record.cemetery)",
                    "Plot placeholder: \(record.plotPlaceholder)",
                    "",
                    "Digitized text",
                    record.digitizedText,
                    "",
                    "Notes",
                    record.notes,
                    "",
                    "Disclaimer",
                    LegacyDisclaimer.bullets.joined(separator: "\n")
                ].joined(separator: "\n"),
                startY: 104
            )
        }

        return url
    }

    private static func drawHeader(_ title: String) {
        UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: 612, height: 76)).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor(red: 0.86, green: 0.78, blue: 0.62, alpha: 1)
        ]
        (title as NSString).draw(in: CGRect(x: 44, y: 26, width: 520, height: 30), withAttributes: attributes)
    }

    private static func drawBody(_ text: String, startY: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor(red: 0.13, green: 0.12, blue: 0.11, alpha: 1)
        ]
        let rect = CGRect(x: 44, y: startY, width: 500, height: 620)
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
    }
}
