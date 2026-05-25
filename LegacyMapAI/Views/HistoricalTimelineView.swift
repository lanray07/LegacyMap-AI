import Charts
import SwiftData
import SwiftUI

struct HistoricalTimelineView: View {
    @Query(sort: \Cemetery.createdAt, order: .reverse) private var cemeteries: [Cemetery]
    @Query(sort: \Memorial.createdAt, order: .reverse) private var memorials: [Memorial]
    @Query(sort: \HistoricalRecord.createdAt, order: .reverse) private var records: [HistoricalRecord]

    private var oldestMemorials: [Memorial] {
        memorials
            .filter { $0.deathYear != nil }
            .sorted { ($0.deathYear ?? .max) < ($1.deathYear ?? .max) }
            .prefix(8)
            .map { $0 }
    }

    private var decadeCounts: [DecadeCount] {
        let grouped = Dictionary(grouping: memorials.compactMap(\.deathYear)) { year in
            (year / 10) * 10
        }
        return grouped
            .map { DecadeCount(decade: "\($0.key)s", count: $0.value.count) }
            .sorted { $0.decade < $1.decade }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Historical Timeline", subtitle: "Cemetery history, oldest graves, and local context placeholders.", systemImage: "clock")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    QuickActionTile(title: "Family Engine", subtitle: "Link generations", systemImage: "tree", destination: FamilyConnectionView())
                    QuickActionTile(title: "AI Stories", subtitle: "Cautious summaries", systemImage: "text.bubble", destination: AIStoryGeneratorView())
                    QuickActionTile(title: "Nearby Discovery", subtitle: "Historic sites", systemImage: "location.magnifyingglass", destination: NearbyCemeteryDiscoveryView())
                    QuickActionTile(title: "Digitize Records", subtitle: "Archive OCR", systemImage: "doc.text.viewfinder", destination: DeathRecordDigitizerView())
                }

                if !decadeCounts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Swift Charts analytics", subtitle: "Memorials by death decade.", systemImage: "chart.bar")
                        Chart(decadeCounts) { item in
                            BarMark(
                                x: .value("Decade", item.decade),
                                y: .value("Memorials", item.count)
                            )
                            .foregroundStyle(.legacyGold)
                        }
                        .frame(height: 220)
                    }
                    .legacyCard()
                } else {
                    EmptyStateView(title: "No timeline data", message: "Add death years to memorials to populate historical analytics.", systemImage: "chart.bar")
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Oldest graves", subtitle: "Sorted by saved death year.", systemImage: "hourglass")
                    if oldestMemorials.isEmpty {
                        EmptyStateView(title: "No dated memorials", message: "Scan or add records with dates to begin the timeline.", systemImage: "calendar.badge.exclamationmark")
                    } else {
                        ForEach(oldestMemorials) { memorial in
                            HistoricalTimelineCard(
                                title: memorial.fullName,
                                year: memorial.deathYear.map(String.init) ?? "Unknown",
                                detail: memorial.inscription.isEmpty ? "Inscription pending." : memorial.inscription
                            )
                        }
                    }
                }
                .legacyCard()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Cemetery history", subtitle: "Historical notes saved locally.", systemImage: "building.columns")
                    if cemeteries.isEmpty {
                        EmptyStateView(title: "No cemetery history", message: "Add cemetery notes while exploring or digitizing records.", systemImage: "book.closed")
                    } else {
                        ForEach(cemeteries) { cemetery in
                            InsightCard(
                                title: cemetery.cemeteryName,
                                detail: cemetery.historicalNotes.isEmpty ? "Historical notes placeholder." : cemetery.historicalNotes,
                                systemImage: "building.columns"
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Local historical events placeholder", subtitle: "Connect archival records without unsupported claims.", systemImage: "newspaper")
                    InsightCard(title: "Community context", detail: "Saved dates and records can be compared with verified local histories, church records, census material, and historical society archives.", systemImage: "book")
                    InsightCard(title: "Family generations placeholder", detail: "\(records.count) digitized records can support manually verified family timelines.", systemImage: "person.3.sequence")
                }
            }
            .padding()
        }
        .background(LegacyBackground())
    }
}

private struct DecadeCount: Identifiable {
    var id: String { decade }
    var decade: String
    var count: Int
}
