import SwiftData
import SwiftUI

struct FamilyConnectionView: View {
    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memorial.fullName) private var memorials: [Memorial]
    @Query(sort: \FamilyConnection.relationshipType) private var connections: [FamilyConnection]

    @AppStorage("savedSurnames") private var savedSurnames = ""
    @State private var surname = ""
    @State private var selectedMemorialId: UUID?
    @State private var relatedMemorialId: UUID?
    @State private var relationshipType = "Possible relative"
    @State private var suggestions: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Family Connection Engine", subtitle: "Build family links as placeholders until independently verified.", systemImage: "tree")

                FamilyTreeCardPlaceholder(
                    title: "Family tree placeholder",
                    bodyText: "Link memorials, save surnames, and connect generations without claiming confirmed ancestry accuracy."
                )

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Saved surnames", subtitle: savedSurnames.isEmpty ? "No surnames saved yet." : savedSurnames, systemImage: "person.text.rectangle")
                    HStack {
                        TextField("Surname", text: $surname)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $surname, label: "Dictate surname", separator: " ")
                        Button {
                            saveSurname()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(LegacyPrimaryButtonStyle())
                    }
                }
                .legacyCard()

                linkForm

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Nearby family graves", subtitle: "Suggestions are informational only.", systemImage: "sparkles")
                    if suggestions.isEmpty {
                        EmptyStateView(title: "No suggestions yet", message: "Select a memorial and ask mock AI for cautious family connection suggestions.", systemImage: "person.2.badge.gearshape")
                    } else {
                        ForEach(suggestions, id: \.self) { suggestion in
                            InsightCard(title: "Possible connection", detail: suggestion, systemImage: "link")
                        }
                    }
                }

                if isLoading {
                    LoadingStateView(message: "Reviewing saved memorial names...")
                }

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }
            }
            .padding()
        }
        .background(LegacyBackground())
    }

    private var linkForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Link relatives", subtitle: "Relationship links remain placeholders.", systemImage: "link")
            Picker("Memorial", selection: $selectedMemorialId) {
                Text("Select memorial").tag(UUID?.none)
                ForEach(memorials) { memorial in
                    Text(memorial.fullName).tag(Optional(memorial.id))
                }
            }
            .pickerStyle(.menu)

            Picker("Related memorial", selection: $relatedMemorialId) {
                Text("Select related memorial").tag(UUID?.none)
                ForEach(memorials) { memorial in
                    Text(memorial.fullName).tag(Optional(memorial.id))
                }
            }
            .pickerStyle(.menu)

            HStack {
                TextField("Relationship type", text: $relationshipType)
                    .textFieldStyle(.roundedBorder)
                VoiceDictationButton(text: $relationshipType, label: "Dictate relation", separator: " ")
            }

            HStack {
                Button {
                    saveConnection()
                } label: {
                    Label("Save link", systemImage: "checkmark")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())

                Button {
                    Task { await generateSuggestions() }
                } label: {
                    Label("Suggest", systemImage: "wand.and.stars")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
            }

            Text("\(connections.count) saved relationship placeholders.")
                .font(.caption)
                .foregroundStyle(.legacyParchment.opacity(0.76))
        }
        .legacyCard()
    }

    private func saveSurname() {
        let trimmed = surname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let current = savedSurnames.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        if !current.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            savedSurnames = (current + [trimmed]).joined(separator: ", ")
        }
        surname = ""
    }

    private func saveConnection() {
        guard let selectedMemorialId, let relatedMemorialId, selectedMemorialId != relatedMemorialId else {
            errorMessage = "Choose two different memorials before saving a relationship placeholder."
            return
        }
        modelContext.insert(FamilyConnection(
            memorialId: selectedMemorialId,
            relatedMemorialId: relatedMemorialId,
            relationshipType: relationshipType
        ))
        try? modelContext.save()
        errorMessage = nil
    }

    private func generateSuggestions() async {
        guard let selectedMemorialId, let memorial = memorials.first(where: { $0.id == selectedMemorialId }) else {
            errorMessage = "Select a memorial before asking for suggestions."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            suggestions = try await aiService.generateFamilyConnectionSuggestions(memorial: memorial, nearbyMemorials: memorials)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
