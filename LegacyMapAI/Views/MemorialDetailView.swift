import MapKit
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct MemorialDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cemetery.cemeteryName) private var cemeteries: [Cemetery]
    @Query(sort: \MemorialPhoto.createdAt, order: .reverse) private var allPhotos: [MemorialPhoto]
    @Query(sort: \FamilyConnection.relationshipType) private var connections: [FamilyConnection]

    let memorial: Memorial

    @State private var photoItem: PhotosPickerItem?
    @State private var reportArtifact: ShareArtifact?
    @State private var errorMessage: String?

    private var cemetery: Cemetery? {
        cemeteries.first { $0.id == memorial.cemeteryId }
    }

    private var photos: [MemorialPhoto] {
        allPhotos.filter { $0.memorialId == memorial.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                Map(initialPosition: .region(MKCoordinateRegion(
                    center: memorial.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                ))) {
                    Marker(memorial.fullName, systemImage: "mappin.circle", coordinate: memorial.coordinate)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                ReportPreviewView(
                    title: "Memorial record",
                    sections: [
                        ("Inscription", memorial.inscription.isEmpty ? "No inscription saved." : memorial.inscription),
                        ("Biography placeholder", memorial.biographyPlaceholder.isEmpty ? "Add researched biography notes after verification." : memorial.biographyPlaceholder),
                        ("Family relationships placeholder", familyConnectionText),
                        ("Military history placeholder", memorial.militaryHistoryPlaceholder.isEmpty ? "No military history recorded." : memorial.militaryHistoryPlaceholder),
                        ("Memorial notes", memorial.notes.isEmpty ? "No notes saved." : memorial.notes),
                        ("Flowers and tribute placeholder", "Tribute tools can be connected to moderation and cemetery policy workflows.")
                    ]
                )

                photoSection

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                VStack(spacing: 10) {
                    Button {
                        memorial.isSaved.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(memorial.isSaved ? "Saved memorial" : "Save memorial", systemImage: memorial.isSaved ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Button {
                        exportPDF()
                    } label: {
                        Label("Export PDF memorial report", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())
                }
            }
            .padding()
        }
        .background(LegacyBackground())
        .navigationTitle(memorial.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem) { _, newValue in
            Task { await loadPhoto(newValue) }
        }
        .sheet(item: $reportArtifact) { artifact in
            ShareSheet(activityItems: [artifact.url])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(memorial.fullName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.legacyPaper)
            Text(memorial.yearRange)
                .font(.headline)
                .foregroundStyle(Color.legacyParchment)
            Label(cemetery?.cemeteryName ?? "Unknown cemetery", systemImage: "building.columns")
                .font(.subheadline)
                .foregroundStyle(Color.legacyParchment.opacity(0.82))
            Label("\(memorial.gpsLatitude, specifier: "%.5f"), \(memorial.gpsLongitude, specifier: "%.5f")", systemImage: "location")
                .font(.caption)
                .foregroundStyle(Color.legacyParchment.opacity(0.72))
        }
        .legacyCard()
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Photos", subtitle: "Grave photo and preservation imagery.", systemImage: "photo")

            if photos.isEmpty {
                EmptyStateView(title: "No photos yet", message: "Upload a grave photo, inscription detail, or restoration image.", systemImage: "photo.badge.plus")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos) { photo in
                            if let data = photo.imageData, let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 130)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Add memorial photo", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(LegacyPrimaryButtonStyle())
        }
        .legacyCard()
    }

    private var familyConnectionText: String {
        let related = connections.filter { $0.memorialId == memorial.id || $0.relatedMemorialId == memorial.id }
        if related.isEmpty {
            return "No family links saved. Suggested links must be verified independently."
        }
        return related.map(\.relationshipType).joined(separator: ", ")
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                modelContext.insert(MemorialPhoto(memorialId: memorial.id, imageData: data, caption: "Memorial photo"))
                try modelContext.save()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportPDF() {
        do {
            let url = try PDFExportService.makeMemorialReport(memorial: memorial, cemetery: cemetery, photos: photos)
            reportArtifact = ShareArtifact(url: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
