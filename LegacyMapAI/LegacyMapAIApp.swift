import SwiftData
import SwiftUI

@main
struct LegacyMapAIApp: App {
    @StateObject private var locationService = LocationService()
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var voiceInputService = VoiceInputService()

    private let aiService: any AIService = MockAIService()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.aiService, aiService)
                .environmentObject(locationService)
                .environmentObject(subscriptionService)
                .environmentObject(notificationService)
                .environmentObject(voiceInputService)
                .modelContainer(for: [
                    Cemetery.self,
                    Memorial.self,
                    MemorialPhoto.self,
                    FamilyConnection.self,
                    VolunteerTask.self,
                    HistoricalRecord.self,
                    SubscriptionState.self
                ])
                .task {
                    await subscriptionService.loadProducts()
                    subscriptionService.listenForTransactions()
                    await notificationService.requestAuthorization()
                }
        }
    }
}
