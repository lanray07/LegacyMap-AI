import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LegacyMap AI Premium")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.legacyPaper)
                    Text("Preservation tools for deeper cemetery research, OCR restoration, family collections, and exports.")
                        .font(.subheadline)
                        .foregroundStyle(Color.legacyParchment.opacity(0.84))
                }

                ForEach([SubscriptionPlan.free, .premiumMonthly, .premiumYearly, .heritageProMonthly]) { plan in
                    planCard(plan)
                }

                subscriptionDisclosures

                if subscriptionService.isLoading {
                    LoadingStateView(message: "Loading subscription products...")
                }

                if let errorMessage = subscriptionService.errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                Button {
                    Task { await subscriptionService.restorePurchases() }
                } label: {
                    Label("Restore purchases", systemImage: "arrow.clockwise")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
            }
            .padding()
        }
        .background(LegacyBackground())
        .navigationTitle("Upgrade")
        .task {
            await subscriptionService.loadProducts()
        }
    }

    private func planCard(_ plan: SubscriptionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.legacyPaper)
                    Text(priceText(for: plan))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.legacyGold)
                    Text(plan.billingPeriod)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.legacyParchment.opacity(0.84))
                }
                Spacer()
                if subscriptionService.activePlan == plan {
                    StatusPill(text: "Active")
                }
            }

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(Color.legacyParchment.opacity(0.84))

            ForEach(plan.features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark")
                    .font(.caption)
                    .foregroundStyle(Color.legacyPaper.opacity(0.86))
            }

            if plan != .free {
                Text("\(plan.displayName): \(plan.priceDisclosure). Payment is charged to your Apple ID. The subscription renews automatically until canceled in your App Store account settings.")
                    .font(.caption)
                    .foregroundStyle(Color.legacyParchment.opacity(0.82))

                Button {
                    Task { await purchase(plan) }
                } label: {
                    Label("Choose \(plan.displayName)", systemImage: "creditcard")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
            }
        }
        .legacyCard()
    }

    private var subscriptionDisclosures: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Subscription terms",
                subtitle: "Review before starting an auto-renewing plan.",
                systemImage: "doc.text"
            )

            Text("Premium Monthly is \(SubscriptionPlan.premiumMonthly.priceDisclosure), Premium Yearly is \(SubscriptionPlan.premiumYearly.priceDisclosure), and Heritage Pro Monthly is \(SubscriptionPlan.heritageProMonthly.priceDisclosure). Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. You can manage or cancel subscriptions in your App Store account settings.")
                .font(.caption)
                .foregroundStyle(Color.legacyParchment.opacity(0.86))

            VStack(alignment: .leading, spacing: 10) {
                Link(destination: LegacyLegalLinks.privacyPolicy) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                Link(destination: LegacyLegalLinks.termsOfUse) {
                    Label("Terms of Use (EULA)", systemImage: "doc.plaintext")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.legacyGold)
        }
        .legacyCard()
    }

    private func priceText(for plan: SubscriptionPlan) -> String {
        subscriptionService.product(for: plan)?.displayPrice ?? plan.price
    }

    private func purchase(_ plan: SubscriptionPlan) async {
        guard let product = subscriptionService.product(for: plan) else {
            subscriptionService.errorMessage = "Attach the StoreKit configuration in Xcode to test \(plan.displayName)."
            return
        }
        await subscriptionService.purchase(product)
    }
}
