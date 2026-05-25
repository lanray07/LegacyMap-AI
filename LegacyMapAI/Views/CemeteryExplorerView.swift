import MapKit
import SwiftData
import SwiftUI

struct CemeteryExplorerView: View {
    @EnvironmentObject private var locationService: LocationService
    @Query(sort: \Cemetery.cemeteryName) private var cemeteries: [Cemetery]
    @Query(sort: \Memorial.fullName) private var memorials: [Memorial]

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var surname = ""
    @State private var year = ""
    @State private var militaryService = ""
    @State private var familyLine = ""

    private var filteredMemorials: [Memorial] {
        memorials.filter { memorial in
            let surnameMatches = surname.isEmpty || memorial.fullName.localizedCaseInsensitiveContains(surname)
            let yearMatches = year.isEmpty || memorial.yearRange.contains(year)
            let militaryMatches = militaryService.isEmpty || memorial.militaryHistoryPlaceholder.localizedCaseInsensitiveContains(militaryService)
            let familyMatches = familyLine.isEmpty || memorial.notes.localizedCaseInsensitiveContains(familyLine)
            return surnameMatches && yearMatches && militaryMatches && familyMatches
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Cemetery Explorer", subtitle: "GPS map, plot markers, and careful historical search.", systemImage: "map")

                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(cemeteries) { cemetery in
                        Marker(cemetery.cemeteryName, systemImage: "building.columns", coordinate: cemetery.coordinate)
                    }
                    ForEach(filteredMemorials) { memorial in
                        Annotation(memorial.fullName, coordinate: memorial.coordinate) {
                            NavigationLink(destination: MemorialDetailView(memorial: memorial)) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.legacyGold)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.legacyParchment.opacity(0.25), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Search filters", subtitle: "Military service and family line search are placeholder fields.", systemImage: "line.3.horizontal.decrease.circle")
                    HStack {
                        TextField("Surname", text: $surname)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $surname, label: "Dictate surname", separator: " ")
                    }
                    HStack {
                        TextField("Birth or death year", text: $year)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Military service placeholder", text: $militaryService)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        TextField("Family line placeholder", text: $familyLine)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $familyLine, label: "Dictate line", separator: " ")
                    }
                }
                .legacyCard()

                HStack {
                    Button {
                        centerOnUser()
                    } label: {
                        Label("Center on GPS", systemImage: "location")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Button {
                        cameraPosition = .automatic
                    } label: {
                        Label("Show all", systemImage: "square.3.layers.3d")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Nearby memorials", subtitle: "Walking directions placeholder available from each marker.", systemImage: "figure.walk")
                    if filteredMemorials.isEmpty {
                        EmptyStateView(title: "No matching memorials", message: "Try a different surname, year, or add local records.", systemImage: "magnifyingglass")
                    } else {
                        ForEach(filteredMemorials.prefix(8)) { memorial in
                            NavigationLink(destination: MemorialDetailView(memorial: memorial)) {
                                MemorialCard(memorial: memorial, cemetery: cemetery(for: memorial))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .background(LegacyBackground())
        .onAppear {
            locationService.startUpdating()
        }
    }

    private func centerOnUser() {
        locationService.startUpdating()
        guard let coordinate = locationService.currentLocation?.coordinate else { return }
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    private func cemetery(for memorial: Memorial) -> Cemetery? {
        cemeteries.first { $0.id == memorial.cemeteryId }
    }
}
