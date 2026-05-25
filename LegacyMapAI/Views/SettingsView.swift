import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var voiceInputService: VoiceInputService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("preferLocalOCR") private var preferLocalOCR = true

    @Query private var cemeteries: [Cemetery]
    @Query private var memorials: [Memorial]
    @Query private var photos: [MemorialPhoto]
    @Query private var connections: [FamilyConnection]
    @Query private var tasks: [VolunteerTask]
    @Query private var records: [HistoricalRecord]

    @State private var exportArtifact: ShareArtifact?
    @State private var statusMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Settings", subtitle: "Subscription, privacy, OCR, and local data controls.", systemImage: "gearshape")

                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink(destination: PaywallView()) {
                        Label("Manage subscription: \(subscriptionService.activePlan.displayName)", systemImage: "creditcard")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Button {
                        locationService.requestAuthorization()
                    } label: {
                        Label("Location permissions: \(locationStatus)", systemImage: "location")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Button {
                        Task {
                            _ = await voiceInputService.requestPermissions()
                        }
                    } label: {
                        Label("Voice input permissions: \(voiceStatus)", systemImage: "mic")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Toggle("Prefer local/mock OCR by default", isOn: $preferLocalOCR)
                        .toggleStyle(.switch)
                        .foregroundStyle(Color.legacyPaper)
                }
                .legacyCard()

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Historical disclaimer", subtitle: "Shown during onboarding and available here.", systemImage: "info.circle")
                    ForEach(LegacyDisclaimer.bullets, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(Color.legacyParchment.opacity(0.86))
                    }
                }
                .legacyCard()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Legal and privacy placeholders", subtitle: "Connect these rows to hosted legal documents before release.", systemImage: "lock.doc")
                    InsightCard(title: "Privacy policy", detail: "Document how location, photos, local records, AI requests, and exports are handled.", systemImage: "hand.raised")
                    InsightCard(title: "Terms of use", detail: "Include limitations around OCR accuracy, genealogy verification, restoration safety, and archival certification.", systemImage: "doc.text")
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Data", subtitle: "Offline-friendly SwiftData storage.", systemImage: "internaldrive")
                    Button {
                        exportData()
                    } label: {
                        Label("Export data", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Button(role: .destructive) {
                        deleteAllData()
                    } label: {
                        Label("Delete all data", systemImage: "trash")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Show onboarding again", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())
                }
                .legacyCard()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Platform placeholders", subtitle: "Architecture hooks for future targets.", systemImage: "app.connected.to.app.below.fill")
                    InsightCard(title: "Widgets", detail: "Nearby memorial, saved ancestor, restoration reminder, and historical quote placeholders are in WidgetsPlaceholder.", systemImage: "square.grid.2x2")
                    InsightCard(title: "Apple Watch", detail: "Cemetery navigation, memorial alerts, walking directions, and saved grave locations placeholders are in WatchPlaceholder.", systemImage: "applewatch")
                }

                if let statusMessage {
                    InsightCard(title: "Status", detail: statusMessage, systemImage: "checkmark.seal")
                }
            }
            .padding()
        }
        .background(LegacyBackground())
        .sheet(item: $exportArtifact) { artifact in
            ShareSheet(activityItems: [artifact.url])
        }
    }

    private var locationStatus: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            "enabled"
        case .denied, .restricted:
            "disabled"
        case .notDetermined:
            "not requested"
        @unknown default:
            "unknown"
        }
    }

    private var voiceStatus: String {
        switch voiceInputService.authorizationStatus {
        case .authorized:
            "enabled"
        case .denied, .restricted:
            "disabled"
        case .notDetermined:
            "not requested"
        @unknown default:
            "unknown"
        }
    }

    private func exportData() {
        let payload = """
        {
          "cemeteries": \(cemeteries.count),
          "memorials": \(memorials.count),
          "photos": \(photos.count),
          "familyConnections": \(connections.count),
          "volunteerTasks": \(tasks.count),
          "historicalRecords": \(records.count),
          "disclaimer": "\(LegacyDisclaimer.bullets.joined(separator: " "))"
        }
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LegacyMapAI-Export-\(UUID().uuidString).json")
        do {
            try payload.write(to: url, atomically: true, encoding: .utf8)
            exportArtifact = ShareArtifact(url: url)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func deleteAllData() {
        cemeteries.forEach { modelContext.delete($0) }
        memorials.forEach { modelContext.delete($0) }
        photos.forEach { modelContext.delete($0) }
        connections.forEach { modelContext.delete($0) }
        tasks.forEach { modelContext.delete($0) }
        records.forEach { modelContext.delete($0) }
        do {
            try modelContext.save()
            statusMessage = "All local cemetery, memorial, volunteer, and record data was deleted."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
