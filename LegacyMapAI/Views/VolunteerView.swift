import PhotosUI
import SwiftData
import SwiftUI

struct VolunteerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService
    @Query(sort: \Cemetery.cemeteryName) private var cemeteries: [Cemetery]
    @Query(sort: \VolunteerTask.createdAt, order: .reverse) private var tasks: [VolunteerTask]

    @State private var selectedCemeteryId: UUID?
    @State private var newCemeteryName = ""
    @State private var selectedTaskType: VolunteerTaskType = .cleaning
    @State private var notes = ""
    @State private var beforePhoto: PhotosPickerItem?
    @State private var afterPhoto: PhotosPickerItem?
    @State private var status: VolunteerTaskStatus = .open
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Cemetery Volunteer System", subtitle: "Coordinate respectful restoration and documentation work.", systemImage: "hand.raised")

                requestForm

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Volunteer categories", subtitle: "Stone repair remains a placeholder and should involve trained experts.", systemImage: "list.bullet")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(VolunteerTaskType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.legacyPaper)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(.legacyStone.opacity(0.20), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .legacyCard()

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Open restoration requests", subtitle: "\(tasks.count) local tasks", systemImage: "checklist")
                    if tasks.isEmpty {
                        EmptyStateView(title: "No volunteer tasks", message: "Report a neglected grave, request documentation, or create a digitization task.", systemImage: "hand.raised")
                    } else {
                        ForEach(tasks) { task in
                            VolunteerTaskCard(task: task, cemetery: cemeteries.first { $0.id == task.cemeteryId })
                        }
                    }
                }
            }
            .padding()
        }
        .background(LegacyBackground())
    }

    private var requestForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Report neglected grave", subtitle: "Upload before/after photos as placeholders for the workflow.", systemImage: "exclamationmark.bubble")
            Picker("Cemetery", selection: $selectedCemeteryId) {
                Text("New cemetery").tag(UUID?.none)
                ForEach(cemeteries) { cemetery in
                    Text(cemetery.cemeteryName).tag(Optional(cemetery.id))
                }
            }
            .pickerStyle(.menu)

            if selectedCemeteryId == nil {
                HStack {
                    TextField("Cemetery name", text: $newCemeteryName)
                        .textFieldStyle(.roundedBorder)
                    VoiceDictationButton(text: $newCemeteryName, label: "Dictate cemetery", separator: " ")
                }
            }

            Picker("Task type", selection: $selectedTaskType) {
                ForEach(VolunteerTaskType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)

            Picker("Status", selection: $status) {
                ForEach(VolunteerTaskStatus.allCases) { taskStatus in
                    Text(taskStatus.rawValue).tag(taskStatus)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .trailing, spacing: 8) {
                TextField("Maintenance notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                VoiceDictationButton(text: $notes, label: "Dictate notes")
            }

            HStack {
                PhotosPicker(selection: $beforePhoto, matching: .images) {
                    Label("Before", systemImage: "photo")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
                PhotosPicker(selection: $afterPhoto, matching: .images) {
                    Label("After", systemImage: "photo.stack")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
            }

            Button {
                saveTask()
            } label: {
                Label("Create volunteer request", systemImage: "plus")
            }
            .buttonStyle(LegacyPrimaryButtonStyle())
        }
        .legacyCard()
    }

    private func saveTask() {
        let cemetery: Cemetery
        if let selectedCemeteryId, let existing = cemeteries.first(where: { $0.id == selectedCemeteryId }) {
            cemetery = existing
        } else {
            let name = newCemeteryName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                errorMessage = "Add a cemetery name or select an existing cemetery."
                return
            }
            cemetery = Cemetery(cemeteryName: name, latitude: 51.5072, longitude: -0.1276, historicalNotes: "Volunteer history notes pending.")
            modelContext.insert(cemetery)
        }

        let task = VolunteerTask(cemeteryId: cemetery.id, taskType: selectedTaskType.rawValue, notes: notes, status: status.rawValue)
        modelContext.insert(task)
        do {
            try modelContext.save()
            Task {
                await notificationService.scheduleRestorationReminder(
                    title: "Restoration reminder",
                    notes: "\(selectedTaskType.rawValue) at \(cemetery.cemeteryName)"
                )
            }
            notes = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
