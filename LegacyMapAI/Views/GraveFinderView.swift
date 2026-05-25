import SwiftData
import SwiftUI

struct GraveFinderView: View {
    @Query(sort: \Memorial.fullName) private var memorials: [Memorial]
    @Query(sort: \Cemetery.cemeteryName) private var cemeteries: [Cemetery]

    @State private var searchName = ""
    @State private var birthYear = ""
    @State private var deathYear = ""
    @State private var sectionQuery = ""

    private var filteredMemorials: [Memorial] {
        memorials.filter { memorial in
            let nameMatches = searchName.isEmpty || memorial.fullName.localizedCaseInsensitiveContains(searchName)
            let birthMatches = birthYear.isEmpty || memorial.birthYear.map(String.init)?.contains(birthYear) == true
            let deathMatches = deathYear.isEmpty || memorial.deathYear.map(String.init)?.contains(deathYear) == true
            let sectionMatches = sectionQuery.isEmpty || memorial.notes.localizedCaseInsensitiveContains(sectionQuery)
            return nameMatches && birthMatches && deathMatches && sectionMatches
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Grave Finder", subtitle: "Search memorials by name, dates, and cemetery notes.", systemImage: "magnifyingglass")

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Search full name", text: $searchName)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $searchName, label: "Dictate name", separator: " ")
                    }
                    HStack {
                        TextField("Birth year", text: $birthYear)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Death year", text: $deathYear)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        TextField("Cemetery section or plot placeholder", text: $sectionQuery)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $sectionQuery, label: "Dictate plot", separator: " ")
                    }
                }
                .legacyCard()

                FamilyTreeCardPlaceholder(
                    title: "Family collections",
                    bodyText: "Create family collections by saving memorials, linking relatives, and reviewing surname matches with independent records."
                )

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Results", subtitle: "\(filteredMemorials.count) local memorials", systemImage: "rectangle.stack")
                    if filteredMemorials.isEmpty {
                        EmptyStateView(title: "No grave records found", message: "Add memorials, scan headstones, or digitize records to build the local index.", systemImage: "tray")
                    } else {
                        ForEach(filteredMemorials) { memorial in
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
    }

    private func cemetery(for memorial: Memorial) -> Cemetery? {
        cemeteries.first { $0.id == memorial.cemeteryId }
    }
}
