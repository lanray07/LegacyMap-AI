import Foundation
import SwiftUI

enum PrimaryInterest: String, CaseIterable, Identifiable {
    case familyHistory = "Family history"
    case cemeteryExploration = "Cemetery exploration"
    case graveRestoration = "Grave restoration"
    case genealogyResearch = "Genealogy research"
    case localHistory = "Local history"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .familyHistory: "person.3.sequence"
        case .cemeteryExploration: "map"
        case .graveRestoration: "wrench.and.screwdriver"
        case .genealogyResearch: "tree"
        case .localHistory: "building.columns"
        }
    }
}

enum VolunteerTaskType: String, CaseIterable, Identifiable {
    case cleaning = "Cleaning"
    case photoDocumentation = "Photo documentation"
    case grassClearing = "Grass clearing"
    case stoneRepair = "Stone repair placeholder"
    case recordDigitization = "Record digitization"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cleaning: "sparkles"
        case .photoDocumentation: "camera"
        case .grassClearing: "leaf"
        case .stoneRepair: "hammer"
        case .recordDigitization: "doc.text.viewfinder"
        }
    }
}

enum VolunteerTaskStatus: String, CaseIterable, Identifiable {
    case open = "Open"
    case requested = "Requested"
    case inProgress = "In progress"
    case completed = "Completed"

    var id: String { rawValue }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case free = "free"
    case premiumMonthly = "premium_monthly"
    case premiumYearly = "premium_yearly"
    case heritageProMonthly = "heritage_pro_monthly"

    var id: String { rawValue }

    var productID: String? {
        switch self {
        case .free: nil
        case .premiumMonthly: "legacy.premium.monthly"
        case .premiumYearly: "legacy.premium.yearly"
        case .heritageProMonthly: "legacy.heritagepro.monthly"
        }
    }

    var displayName: String {
        switch self {
        case .free: "Free"
        case .premiumMonthly: "Premium Monthly"
        case .premiumYearly: "Premium Yearly"
        case .heritageProMonthly: "Heritage Pro Monthly"
        }
    }

    var price: String {
        switch self {
        case .free: "£0"
        case .premiumMonthly: "£9.99"
        case .premiumYearly: "£79.99"
        case .heritageProMonthly: "£24.99"
        }
    }

    var summary: String {
        switch self {
        case .free:
            "Basic cemetery search, limited scans, limited memorial saves, and 7-day history."
        case .premiumMonthly, .premiumYearly:
            "Unlimited scans, advanced OCR restoration, memorial collections, AI summaries, PDF exports, and advanced filters."
        case .heritageProMonthly:
            "Family archives placeholder, advanced genealogy placeholder, cemetery management placeholder, volunteer coordination placeholder, and premium historical tools."
        }
    }

    var features: [String] {
        switch self {
        case .free:
            ["Basic cemetery search", "Limited scans", "Limited memorial saves", "7-day history"]
        case .premiumMonthly, .premiumYearly:
            ["Unlimited scans", "Advanced OCR restoration", "Memorial collections", "AI summaries", "PDF exports", "Advanced search filters"]
        case .heritageProMonthly:
            ["Family archives placeholder", "Advanced genealogy placeholder", "Cemetery management placeholder", "Volunteer coordination placeholder", "Premium historical tools"]
        }
    }
}

enum LegacyDisclaimer {
    static let title = "Historical and informational disclaimer"

    static let bullets = [
        "LegacyMap AI is an informational historical tool only.",
        "Records may be incomplete, damaged, duplicated, or transcribed from uncertain sources.",
        "OCR may contain inaccuracies and should be manually reviewed.",
        "AI results are informational only and may require independent verification.",
        "Genealogy connections may require independent verification.",
        "LegacyMap AI is not legal identity verification.",
        "LegacyMap AI is not official archival certification."
    ]
}

enum DigitizerField {
    static func parseYear(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : Int(trimmed)
    }
}
