import MapKit
import SwiftUI
import UIKit

extension Color {
    static let legacyCharcoal = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let legacyInk = Color(red: 0.16, green: 0.15, blue: 0.14)
    static let legacyParchment = Color(red: 0.83, green: 0.76, blue: 0.62)
    static let legacyPaper = Color(red: 0.94, green: 0.90, blue: 0.80)
    static let legacyStone = Color(red: 0.48, green: 0.48, blue: 0.45)
    static let legacyGold = Color(red: 0.73, green: 0.58, blue: 0.32)
    static let legacyMoss = Color(red: 0.28, green: 0.36, blue: 0.30)
    static let legacySignal = Color(red: 0.22, green: 0.42, blue: 0.48)
}

struct LegacyBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.legacyCharcoal, Color(red: 0.13, green: 0.12, blue: 0.11), Color(red: 0.20, green: 0.19, blue: 0.17)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Rectangle()
                .fill(Color.legacyPaper.opacity(0.06))
                .overlay(alignment: .topLeading) {
                    Canvas { context, size in
                        for index in stride(from: 0, through: Int(size.height), by: 11) {
                            let opacity = index.isMultiple(of: 2) ? 0.035 : 0.018
                            context.stroke(
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: CGFloat(index)))
                                    path.addLine(to: CGPoint(x: size.width, y: CGFloat(index + 4)))
                                },
                                with: .color(Color.legacyPaper.opacity(opacity)),
                                lineWidth: 0.6
                            )
                        }
                    }
                }
        }
        .ignoresSafeArea()
    }
}

struct LegacyCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.legacyParchment.opacity(0.22), lineWidth: 1)
            }
    }
}

extension View {
    func legacyCard() -> some View {
        modifier(LegacyCardModifier())
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String?
    var systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.legacyGold)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.legacyPaper)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.legacyParchment.opacity(0.78))
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.legacyGold)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.legacyPaper)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.legacyParchment.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
        .legacyCard()
    }
}

struct QuickActionTile<Destination: View>: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.legacyGold)
                    .frame(width: 34, height: 34)
                    .background(Color.legacyGold.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.legacyPaper)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.legacyParchment.opacity(0.78))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .legacyCard()
        }
        .buttonStyle(.plain)
    }
}

struct MemorialCard: View {
    var memorial: Memorial
    var cemetery: Cemetery?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(memorial.fullName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.legacyPaper)
                    Text(memorial.yearRange)
                        .font(.caption)
                        .foregroundStyle(Color.legacyParchment)
                }
                Spacer()
                Image(systemName: memorial.isSaved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(Color.legacyGold)
            }

            if !memorial.inscription.isEmpty {
                Text(memorial.inscription)
                    .font(.subheadline)
                    .foregroundStyle(Color.legacyPaper.opacity(0.82))
                    .lineLimit(3)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(cemetery?.cemeteryName ?? "Unknown cemetery")
                    .lineLimit(1)
                Spacer()
                Text("\(memorial.gpsLatitude, specifier: "%.3f"), \(memorial.gpsLongitude, specifier: "%.3f")")
            }
            .font(.caption)
            .foregroundStyle(Color.legacyParchment.opacity(0.75))
        }
        .legacyCard()
    }
}

struct CemeteryMapCard: View {
    var cemetery: Cemetery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: cemetery.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            ))) {
                Marker(cemetery.cemeteryName, systemImage: "building.columns", coordinate: cemetery.coordinate)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .mapStyle(.standard(elevation: .realistic))

            VStack(alignment: .leading, spacing: 4) {
                Text(cemetery.cemeteryName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.legacyPaper)
                Text(cemetery.historicalNotes.isEmpty ? "Historical notes can be added as cemetery records are digitized." : cemetery.historicalNotes)
                    .font(.caption)
                    .foregroundStyle(Color.legacyParchment.opacity(0.78))
                    .lineLimit(3)
            }
        }
        .legacyCard()
    }
}

struct FamilyTreeCardPlaceholder: View {
    var title: String
    var bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tree")
                    .foregroundStyle(Color.legacyGold)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.legacyPaper)
            }
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(index == 0 ? Color.legacyGold : Color.legacyStone.opacity(0.6))
                            .frame(width: 26, height: 26)
                        Rectangle()
                            .fill(Color.legacyParchment.opacity(0.35))
                            .frame(width: 1, height: 22)
                    }
                    if index < 3 {
                        Rectangle()
                            .fill(Color.legacyParchment.opacity(0.35))
                            .frame(height: 1)
                    }
                }
            }
            Text(bodyText)
                .font(.subheadline)
                .foregroundStyle(Color.legacyParchment.opacity(0.82))
        }
        .legacyCard()
    }
}

struct OCRResultCard: View {
    var result: HeadstoneScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "AI OCR restoration placeholder", subtitle: result.confidenceNote, systemImage: "text.viewfinder")
            Label(result.possibleInscription, systemImage: "quote.opening")
                .font(.subheadline)
                .foregroundStyle(Color.legacyPaper)
            Label(result.likelySurname, systemImage: "person.text.rectangle")
                .font(.subheadline)
                .foregroundStyle(Color.legacyPaper)
            Label(result.conditionEstimate, systemImage: "stone")
                .font(.subheadline)
                .foregroundStyle(Color.legacyPaper)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(result.estimatedDates, id: \.self) { date in
                    Label(date, systemImage: "calendar")
                }
                ForEach(result.preservationSuggestions, id: \.self) { suggestion in
                    Label(suggestion, systemImage: "checkmark.seal")
                }
            }
            .font(.caption)
            .foregroundStyle(Color.legacyParchment.opacity(0.86))
        }
        .legacyCard()
    }
}

struct VolunteerTaskCard: View {
    var task: VolunteerTask
    var cemetery: Cemetery?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hand.raised")
                .foregroundStyle(Color.legacyGold)
                .frame(width: 34, height: 34)
                .background(Color.legacyGold.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.taskType)
                        .font(.headline)
                        .foregroundStyle(Color.legacyPaper)
                    Spacer()
                    StatusPill(text: task.status)
                }
                Text(cemetery?.cemeteryName ?? "Unknown cemetery")
                    .font(.caption)
                    .foregroundStyle(Color.legacyParchment)
                Text(task.notes.isEmpty ? "No maintenance notes yet." : task.notes)
                    .font(.subheadline)
                    .foregroundStyle(Color.legacyPaper.opacity(0.78))
                    .lineLimit(3)
            }
        }
        .legacyCard()
    }
}

struct HistoricalTimelineCard: View {
    var title: String
    var year: String
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.legacyGold)
                    .frame(width: 12, height: 12)
                Rectangle()
                    .fill(Color.legacyParchment.opacity(0.35))
                    .frame(width: 1, height: 58)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(year)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.legacyGold)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.legacyPaper)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.legacyParchment.opacity(0.82))
            }
            Spacer()
        }
    }
}

struct InsightCard: View {
    var title: String
    var detail: String
    var systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.legacyGold)
                .frame(width: 34, height: 34)
                .background(Color.legacyGold.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.legacyPaper)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.legacyParchment.opacity(0.84))
            }
        }
        .legacyCard()
    }
}

struct ReportPreviewView: View {
    var title: String
    var sections: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.legacyPaper)
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.0)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.legacyGold)
                    Text(section.1)
                        .font(.subheadline)
                        .foregroundStyle(Color.legacyParchment.opacity(0.82))
                }
            }
        }
        .legacyCard()
    }
}

struct UpgradeBanner: View {
    var title: String
    var message: String

    var body: some View {
        NavigationLink(destination: PaywallView()) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack")
                    .foregroundStyle(Color.legacyCharcoal)
                    .frame(width: 34, height: 34)
                    .background(Color.legacyPaper, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.legacyCharcoal)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.legacyInk.opacity(0.78))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.legacyCharcoal)
            }
            .padding(14)
            .background(Color.legacyGold, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct StatusPill: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.legacyPaper)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.legacySignal.opacity(0.55), in: Capsule())
    }
}

struct LegacyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(Color.legacyCharcoal)
            .background(configuration.isPressed ? Color.legacyParchment : Color.legacyGold, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct VoiceDictationButton: View {
    @StateObject private var voiceService = VoiceInputService()
    @Binding var text: String

    var label: String = "Voice input"
    var separator: String = "\n"

    var body: some View {
        Button {
            toggleDictation()
        } label: {
            Label(
                voiceService.isRecording ? "Listening" : label,
                systemImage: voiceService.isRecording ? "waveform.circle.fill" : "mic.circle"
            )
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(voiceService.isRecording ? Color.legacyCharcoal : Color.legacyPaper)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(voiceService.isRecording ? Color.legacyGold : Color.legacyStone.opacity(0.28), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.legacyParchment.opacity(0.18), lineWidth: 1)
        }
        .accessibilityLabel(voiceService.isRecording ? "Stop voice input" : label)
        .alert("Voice input", isPresented: Binding(
            get: { voiceService.errorMessage != nil },
            set: { if !$0 { voiceService.errorMessage = nil } }
        )) {
            Button("OK") {
                voiceService.errorMessage = nil
            }
        } message: {
            Text(voiceService.errorMessage ?? "")
        }
    }

    private func toggleDictation() {
        if voiceService.isRecording {
            voiceService.stopDictation()
            return
        }

        let prefix = text.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await voiceService.startDictation { spokenText in
                if prefix.isEmpty {
                    text = spokenText
                } else if spokenText.isEmpty {
                    text = prefix
                } else {
                    text = "\(prefix)\(separator)\(spokenText)"
                }
            }
        }
    }
}

struct VoiceInputErrorHint: View {
    @ObservedObject var voiceService: VoiceInputService

    var body: some View {
        if let errorMessage = voiceService.errorMessage {
            Label(errorMessage, systemImage: "mic.slash")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

struct LoadingStateView: View {
    var message: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(message)
                .font(.subheadline)
        }
        .foregroundStyle(Color.legacyParchment)
        .frame(maxWidth: .infinity)
        .legacyCard()
    }
}

struct ErrorStateView: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .legacyCard()
    }
}
