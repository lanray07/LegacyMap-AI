import MapKit
import SwiftData
import SwiftUI

struct NearbyCemeteryDiscoveryView: View {
    @EnvironmentObject private var locationService: LocationService
    @Query(sort: \Cemetery.cemeteryName) private var cemeteries: [Cemetery]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Nearby Cemetery Discovery", subtitle: "Historic cemeteries, notable memorials, and forgotten burial ground placeholders.", systemImage: "location.magnifyingglass")

                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(cemeteries) { cemetery in
                        Marker(cemetery.cemeteryName, systemImage: "building.columns", coordinate: cemetery.coordinate)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 12) {
                    InsightCard(title: "Historic cemeteries", detail: "Saved cemeteries can be tagged with local history, oldest markers, and community notes.", systemImage: "building.columns")
                    InsightCard(title: "Military cemeteries placeholder", detail: "Military service search should be verified against official and family records.", systemImage: "shield")
                    InsightCard(title: "Notable memorials", detail: "Use cautious summaries for public-interest memorials and avoid unsupported claims.", systemImage: "star")
                    InsightCard(title: "Forgotten burial grounds", detail: "Potential locations should be documented respectfully and checked with local authorities or historical societies.", systemImage: "map")
                }

                if cemeteries.isEmpty {
                    EmptyStateView(title: "No nearby cemetery records", message: "Add cemeteries or memorials to populate discovery results.", systemImage: "location.slash")
                } else {
                    ForEach(cemeteries) { cemetery in
                        CemeteryMapCard(cemetery: cemetery)
                    }
                }
            }
            .padding()
        }
        .background(LegacyBackground())
        .onAppear {
            locationService.startUpdating()
            if let coordinate = locationService.currentLocation?.coordinate {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                ))
            }
        }
    }
}
