import Foundation
import StoreKit

enum SubscriptionVerificationError: Error {
    case failed
}

@MainActor
final class SubscriptionService: ObservableObject {
    @Published var products: [Product] = []
    @Published var activePlan: SubscriptionPlan = .free
    @Published var isActive = false
    @Published var renewsAt: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let productIDs = [
        "legacy.premium.monthly",
        "legacy.premium.yearly",
        "legacy.heritagepro.monthly"
    ]

    private var transactionListener: Task<Void, Never>?

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            await refreshEntitlements()
        } catch {
            errorMessage = "StoreKit products are unavailable in this build. Attach the StoreKit configuration in Xcode to test purchases."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                activePlan = plan(for: transaction.productID)
                isActive = activePlan != .free
                renewsAt = transaction.expirationDate
                await transaction.finish()
            case .pending:
                errorMessage = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "Purchase could not be completed."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var latestPlan: SubscriptionPlan = .free
        var latestRenewalDate: Date?

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            let plan = plan(for: transaction.productID)
            if plan != .free {
                latestPlan = plan
                latestRenewalDate = transaction.expirationDate
            }
        }

        activePlan = latestPlan
        isActive = latestPlan != .free
        renewsAt = latestRenewalDate
    }

    func listenForTransactions() {
        transactionListener?.cancel()
        transactionListener = Task {
            for await result in Transaction.updates {
                guard let transaction = try? checkVerified(result) else { continue }
                activePlan = plan(for: transaction.productID)
                isActive = activePlan != .free
                renewsAt = transaction.expirationDate
                await transaction.finish()
            }
        }
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        guard let productID = plan.productID else { return nil }
        return products.first { $0.id == productID }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionVerificationError.failed
        case .verified(let safe):
            return safe
        }
    }

    private func plan(for productID: String) -> SubscriptionPlan {
        switch productID {
        case "legacy.premium.monthly":
            .premiumMonthly
        case "legacy.premium.yearly":
            .premiumYearly
        case "legacy.heritagepro.monthly":
            .heritageProMonthly
        default:
            .free
        }
    }
}
