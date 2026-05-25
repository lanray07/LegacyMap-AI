import SwiftData
import SwiftUI

struct AddMemorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService
    @Query(sort: \Cemetery.cemeteryName) private var cemeteries: [Cemetery]

    @State private var cemeteryName = ""
    @State private var selectedCemeteryId: UUID?
    @State private var fullName = ""
    @State private var birthYear = ""
    @State private var deathYear = ""
    @State private var inscription = ""
    @State private var notes = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Add Memorial", subtitle: "Create an offline-first local record.", systemImage: "plus.app")

                VStack(alignment: .leading, spacing: 12) {
                    if cemeteries.isEmpty {
                        HStack {
                            TextField("Cemetery name", text: $cemeteryName)
                                .textFieldStyle(.roundedBorder)
                            VoiceDictationButton(text: $cemeteryName, label: "Dictate cemetery", separator: " ")
                        }
                    } else {
                        Picker("Cemetery", selection: $selectedCemeteryId) {
                            Text("New cemetery").tag(UUID?.none)
                            ForEach(cemeteries) { cemetery in
                                Text(cemetery.cemeteryName).tag(Optional(cemetery.id))
                            }
                        }
                        .pickerStyle(.menu)

                        if selectedCemeteryId == nil {
                            HStack {
                                TextField("New cemetery name", text: $cemeteryName)
                                    .textFieldStyle(.roundedBorder)
                                VoiceDictationButton(text: $cemeteryName, label: "Dictate cemetery", separator: " ")
                            }
                        }
                    }

                    HStack {
                        TextField("Full name", text: $fullName)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $fullName, label: "Dictate name", separator: " ")
                    }
                    HStack {
                        TextField("Birth year", text: $birthYear)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Death year", text: $deathYear)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .trailing, spacing: 8) {
                        TextField("Inscription", text: $inscription, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $inscription, label: "Dictate inscription")
                    }
                    VStack(alignment: .trailing, spacing: 8) {
                        TextField("Cemetery notes", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $notes, label: "Dictate notes")
                    }

                    HStack {
                        TextField("Latitude", text: $latitude)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Longitude", text: $longitude)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button {
                        useCurrentLocation()
                    } label: {
                        Label("Use current GPS", systemImage: "location")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())
                }
                .legacyCard()

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                Button("Save memorial") {
                    saveMemorial()
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
            }
            .padding()
        }
        .background(LegacyBackground())
        .navigationTitle("Add Memorial")
    }

    private func useCurrentLocation() {
        locationService.startUpdating()
        guard let coordinate = locationService.currentLocation?.coordinate else {
            errorMessage = "Location is not available yet. Try again after permission is granted."
            return
        }
        latitude = String(format: "%.6f", coordinate.latitude)
        longitude = String(format: "%.6f", coordinate.longitude)
    }

    private func saveMemorial() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Add a name before saving."
            return
        }

        let lat = Double(latitude) ?? locationService.currentLocation?.coordinate.latitude ?? 51.5072
        let lon = Double(longitude) ?? locationService.currentLocation?.coordinate.longitude ?? -0.1276

        let cemetery: Cemetery
        if let selectedCemeteryId, let existing = cemeteries.first(where: { $0.id == selectedCemeteryId }) {
            cemetery = existing
        } else {
            let name = cemeteryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown cemetery" : cemeteryName
            cemetery = Cemetery(cemeteryName: name, latitude: lat, longitude: lon, historicalNotes: "Local history notes pending.")
            modelContext.insert(cemetery)
        }

        let memorial = Memorial(
            cemeteryId: cemetery.id,
            fullName: trimmedName,
            birthYear: DigitizerField.parseYear(birthYear),
            deathYear: DigitizerField.parseYear(deathYear),
            inscription: inscription,
            gpsLatitude: lat,
            gpsLongitude: lon,
            notes: notes,
            isSaved: true
        )
        modelContext.insert(memorial)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
