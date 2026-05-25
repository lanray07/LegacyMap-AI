import CoreLocation
import Foundation
import SwiftData

@Model
final class Cemetery {
    @Attribute(.unique) var id: UUID
    var cemeteryName: String
    var latitude: Double
    var longitude: Double
    var historicalNotes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        cemeteryName: String,
        latitude: Double,
        longitude: Double,
        historicalNotes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.cemeteryName = cemeteryName
        self.latitude = latitude
        self.longitude = longitude
        self.historicalNotes = historicalNotes
        self.createdAt = createdAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@Model
final class Memorial {
    @Attribute(.unique) var id: UUID
    var cemeteryId: UUID
    var fullName: String
    var birthYear: Int?
    var deathYear: Int?
    var inscription: String
    var gpsLatitude: Double
    var gpsLongitude: Double
    var notes: String
    var biographyPlaceholder: String
    var militaryHistoryPlaceholder: String
    var isSaved: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        cemeteryId: UUID,
        fullName: String,
        birthYear: Int? = nil,
        deathYear: Int? = nil,
        inscription: String = "",
        gpsLatitude: Double,
        gpsLongitude: Double,
        notes: String = "",
        biographyPlaceholder: String = "",
        militaryHistoryPlaceholder: String = "",
        isSaved: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.cemeteryId = cemeteryId
        self.fullName = fullName
        self.birthYear = birthYear
        self.deathYear = deathYear
        self.inscription = inscription
        self.gpsLatitude = gpsLatitude
        self.gpsLongitude = gpsLongitude
        self.notes = notes
        self.biographyPlaceholder = biographyPlaceholder
        self.militaryHistoryPlaceholder = militaryHistoryPlaceholder
        self.isSaved = isSaved
        self.createdAt = createdAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: gpsLatitude, longitude: gpsLongitude)
    }

    var yearRange: String {
        let birth = birthYear.map(String.init) ?? "Unknown"
        let death = deathYear.map(String.init) ?? "Unknown"
        return "\(birth)-\(death)"
    }
}

@Model
final class MemorialPhoto {
    @Attribute(.unique) var id: UUID
    var memorialId: UUID
    @Attribute(.externalStorage) var imageData: Data?
    var localImageURL: String?
    var caption: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        memorialId: UUID,
        imageData: Data? = nil,
        localImageURL: String? = nil,
        caption: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.memorialId = memorialId
        self.imageData = imageData
        self.localImageURL = localImageURL
        self.caption = caption
        self.createdAt = createdAt
    }
}

@Model
final class FamilyConnection {
    @Attribute(.unique) var id: UUID
    var memorialId: UUID
    var relatedMemorialId: UUID
    var relationshipType: String

    init(
        id: UUID = UUID(),
        memorialId: UUID,
        relatedMemorialId: UUID,
        relationshipType: String
    ) {
        self.id = id
        self.memorialId = memorialId
        self.relatedMemorialId = relatedMemorialId
        self.relationshipType = relationshipType
    }
}

@Model
final class VolunteerTask {
    @Attribute(.unique) var id: UUID
    var cemeteryId: UUID
    var taskType: String
    var notes: String
    var status: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        cemeteryId: UUID,
        taskType: String,
        notes: String = "",
        status: String = VolunteerTaskStatus.open.rawValue,
        createdAt: Date = .now
    ) {
        self.id = id
        self.cemeteryId = cemeteryId
        self.taskType = taskType
        self.notes = notes
        self.status = status
        self.createdAt = createdAt
    }
}

@Model
final class HistoricalRecord {
    @Attribute(.unique) var id: UUID
    var fullName: String
    var birthYear: Int?
    var deathYear: Int?
    var cemetery: String
    var plotPlaceholder: String
    var digitizedText: String
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        fullName: String,
        birthYear: Int? = nil,
        deathYear: Int? = nil,
        cemetery: String = "",
        plotPlaceholder: String = "",
        digitizedText: String = "",
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.fullName = fullName
        self.birthYear = birthYear
        self.deathYear = deathYear
        self.cemetery = cemetery
        self.plotPlaceholder = plotPlaceholder
        self.digitizedText = digitizedText
        self.notes = notes
        self.createdAt = createdAt
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var plan: String
    var isActive: Bool
    var renewsAt: Date?

    init(
        id: UUID = UUID(),
        plan: String = SubscriptionPlan.free.rawValue,
        isActive: Bool = false,
        renewsAt: Date? = nil
    ) {
        self.id = id
        self.plan = plan
        self.isActive = isActive
        self.renewsAt = renewsAt
    }
}
