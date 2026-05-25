import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(nanoseconds: 250_000_000)
    }
}

struct DashboardMetric: Identifiable {
    let id = UUID()
    var title: String
    var value: String
    var systemImage: String
}
