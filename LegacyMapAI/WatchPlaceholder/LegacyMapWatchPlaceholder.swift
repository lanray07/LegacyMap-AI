#if os(watchOS)
import SwiftUI

struct LegacyMapWatchNavigationPlaceholder: View {
    var body: some View {
        List {
            Label("Cemetery navigation", systemImage: "location")
            Label("Memorial alerts", systemImage: "bell")
            Label("Walking directions", systemImage: "figure.walk")
            Label("Saved grave locations", systemImage: "bookmark")
        }
        .navigationTitle("LegacyMap AI")
    }
}
#endif
