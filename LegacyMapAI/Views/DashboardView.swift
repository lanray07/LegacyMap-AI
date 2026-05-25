import SwiftData
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Query(sort: \Cemetery.createdAt, order: .reverse) private var cemeteries: [Cemetery]
    @Query(sort: \Memorial.createdAt, order: .reverse) private var memorials: [Memorial]
    @Query(sort: \VolunteerTask.createdAt, order: .reverse) private var volunteerTasks: [VolunteerTask]
    @Query(sort: \HistoricalRecord.createdAt, order: .reverse) private var records: [HistoricalRecord]
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                UpgradeBanner(
                    title: subscriptionService.activePlan.displayName,
                    message: subscriptionService.isActive ? "Premium preservation tools are active." : "Upgrade for unlimited scans, AI summaries, and PDF exports."
                )

                metrics

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Quick actions", subtitle: "Start from the field, archive, or family line.", systemImage: "bolt")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        QuickActionTile(title: "Find Grave", subtitle: "Search names and years", systemImage: "magnifyingglass", destination: GraveFinderView())
                        QuickActionTile(title: "Scan Headstone", subtitle: "OCR restoration placeholder", systemImage: "camera.viewfinder", destination: HeadstoneScannerView())
                        QuickActionTile(title: "Add Memorial", subtitle: "Create local record", systemImage: "plus.app", destination: AddMemorialView())
                        QuickActionTile(title: "Explore Cemetery", subtitle: "GPS map and plots", systemImage: "map", destination: CemeteryExplorerView())
                        QuickActionTile(title: "Digitize Record", subtitle: "Archive OCR workflow", systemImage: "doc.text.viewfinder", destination: DeathRecordDigitizerView())
                        QuickActionTile(title: "Volunteer Nearby", subtitle: "Restoration requests", systemImage: "hand.raised", destination: VolunteerView())
                    }
                }

                sectionedDashboardContent
            }
            .padding()
        }
        .background(LegacyBackground())
        .task { await viewModel.refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Every grave has a story waiting to be remembered.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.legacyPaper)
            Text("Map cemeteries, preserve inscriptions, organize family records, and keep historical context close to the source.")
                .font(.subheadline)
                .foregroundStyle(Color.legacyParchment.opacity(0.82))
        }
    }

    private var metrics: some View {
        let values = [
            DashboardMetric(title: "Cemeteries", value: "\(cemeteries.count)", systemImage: "building.columns"),
            DashboardMetric(title: "Memorials", value: "\(memorials.count)", systemImage: "rectangle.stack"),
            DashboardMetric(title: "Records", value: "\(records.count)", systemImage: "doc.text"),
            DashboardMetric(title: "Restoration", value: "\(volunteerTasks.count)", systemImage: "hand.raised")
        ]

        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
            ForEach(values) { metric in
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: metric.systemImage)
                        .foregroundStyle(Color.legacyGold)
                    Text(metric.value)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.legacyPaper)
                    Text(metric.title)
                        .font(.caption)
                        .foregroundStyle(Color.legacyParchment)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .legacyCard()
            }
        }
    }

    private var sectionedDashboardContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Nearby cemeteries", subtitle: "Local records stay available offline.", systemImage: "location")
                if cemeteries.isEmpty {
                    EmptyStateView(title: "No cemeteries yet", message: "Add a memorial or cemetery to begin building a local historical map.", systemImage: "map")
                } else {
                    ForEach(cemeteries.prefix(2)) { cemetery in
                        CemeteryMapCard(cemetery: cemetery)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Recently discovered memorials", subtitle: "Saved inscriptions and locations.", systemImage: "rectangle.stack")
                if memorials.isEmpty {
                    EmptyStateView(title: "No memorials saved", message: "Use Add Memorial or Scan Headstone to preserve the first record.", systemImage: "rectangle.badge.plus")
                } else {
                    ForEach(memorials.prefix(3)) { memorial in
                        NavigationLink(destination: MemorialDetailView(memorial: memorial)) {
                            MemorialCard(memorial: memorial, cemetery: cemetery(for: memorial))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Restoration requests", subtitle: "Volunteer coordination placeholders.", systemImage: "hand.raised")
                if volunteerTasks.isEmpty {
                    EmptyStateView(title: "No open tasks", message: "Report a neglected grave or create a documentation task for volunteers.", systemImage: "checklist")
                } else {
                    ForEach(volunteerTasks.prefix(2)) { task in
                        VolunteerTaskCard(task: task, cemetery: cemeteries.first { $0.id == task.cemeteryId })
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Historical discoveries", subtitle: "Digitized record activity.", systemImage: "book.closed")
                if records.isEmpty {
                    EmptyStateView(title: "No digitized records", message: "Photograph old death records or upload archive documents to draft transcriptions.", systemImage: "doc.text.viewfinder")
                } else {
                    ForEach(records.prefix(3)) { record in
                        InsightCard(title: record.fullName, detail: record.digitizedText.isEmpty ? "Manual correction pending." : record.digitizedText, systemImage: "doc.text")
                    }
                }
            }
        }
    }

    private func cemetery(for memorial: Memorial) -> Cemetery? {
        cemeteries.first { $0.id == memorial.cemeteryId }
    }
}
