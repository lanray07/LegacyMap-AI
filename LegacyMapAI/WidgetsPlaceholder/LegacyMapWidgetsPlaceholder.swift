#if LEGACYMAP_WIDGET_EXTENSION
import SwiftUI
import WidgetKit

struct LegacyMapWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let detail: String
}

struct LegacyMapWidgetView: View {
    var entry: LegacyMapWidgetEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.title)
                .font(.headline)
            Text(entry.detail)
                .font(.caption)
        }
    }
}

struct LegacyMapWidgetsPlaceholder: Widget {
    let kind = "LegacyMapWidgetsPlaceholder"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { entry in
            LegacyMapWidgetView(entry: entry)
        }
        .configurationDisplayName("LegacyMap AI")
        .description("Nearby memorial, saved ancestor, restoration reminder, and historical quote placeholders.")
    }
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> LegacyMapWidgetEntry {
        LegacyMapWidgetEntry(date: .now, title: "Nearby memorial", detail: "A saved grave is nearby.")
    }

    func getSnapshot(in context: Context, completion: @escaping (LegacyMapWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LegacyMapWidgetEntry>) -> Void) {
        completion(Timeline(entries: [placeholder(in: context)], policy: .after(.now.addingTimeInterval(3600))))
    }
}
#endif
