import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct DeathRecordDigitizerView: View {
    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DigitizerViewModel()

    @State private var imageData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var rawHistoricalText = ""
    @State private var birthYearText = ""
    @State private var deathYearText = ""
    @State private var shareArtifact: ShareArtifact?
    @State private var savedMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Death Record Digitizer", subtitle: "Photograph old records, draft OCR, correct manually, and export.", systemImage: "doc.text.viewfinder")

                imagePreview

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .trailing, spacing: 8) {
                        TextField("Paste historical text or notes before OCR", text: $rawHistoricalText, axis: .vertical)
                            .lineLimit(4...8)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $rawHistoricalText, label: "Dictate text")
                    }
                    HStack {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Upload document", systemImage: "doc")
                        }
                        .buttonStyle(LegacyPrimaryButtonStyle())

                        Button {
                            showingCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                        }
                        .buttonStyle(LegacyPrimaryButtonStyle())
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    }

                    Button {
                        Task {
                            await viewModel.digitize(imageData: imageData, historicalText: rawHistoricalText)
                            birthYearText = viewModel.draft.birthYear.map(String.init) ?? ""
                            deathYearText = viewModel.draft.deathYear.map(String.init) ?? ""
                        }
                    } label: {
                        Label(viewModel.isProcessing ? "Processing OCR" : "Run AI OCR placeholder", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())
                    .disabled(viewModel.isProcessing)
                }
                .legacyCard()

                if viewModel.isProcessing {
                    LoadingStateView(message: "Drafting a cautious transcription...")
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                correctionForm

                if let savedMessage {
                    InsightCard(title: "Saved", detail: savedMessage, systemImage: "checkmark.seal")
                }
            }
            .padding()
        }
        .background(LegacyBackground())
        .onAppear {
            viewModel.aiService = aiService
        }
        .onChange(of: photoItem) { _, item in
            Task {
                guard let item else { return }
                imageData = try? await item.loadTransferable(type: Data.self)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(imageData: $imageData)
                .ignoresSafeArea()
        }
        .sheet(item: $shareArtifact) { artifact in
            ShareSheet(activityItems: [artifact.url])
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            EmptyStateView(title: "No archive image selected", message: "Upload a death record, church register page, or cemetery document.", systemImage: "doc.badge.plus")
        }
    }

    private var correctionForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Manual correction", subtitle: "Review OCR before saving or export.", systemImage: "pencil.and.outline")
            HStack {
                TextField("Full name", text: $viewModel.draft.fullName)
                    .textFieldStyle(.roundedBorder)
                VoiceDictationButton(text: $viewModel.draft.fullName, label: "Dictate name", separator: " ")
            }
            HStack {
                TextField("Birth year", text: $birthYearText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                TextField("Death year", text: $deathYearText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                TextField("Cemetery", text: $viewModel.draft.cemetery)
                    .textFieldStyle(.roundedBorder)
                VoiceDictationButton(text: $viewModel.draft.cemetery, label: "Dictate cemetery", separator: " ")
            }
            HStack {
                TextField("Plot placeholder", text: $viewModel.draft.plotPlaceholder)
                    .textFieldStyle(.roundedBorder)
                VoiceDictationButton(text: $viewModel.draft.plotPlaceholder, label: "Dictate plot", separator: " ")
            }
            VStack(alignment: .trailing, spacing: 8) {
                TextField("Digitized text", text: $viewModel.draft.digitizedText, axis: .vertical)
                    .lineLimit(4...9)
                    .textFieldStyle(.roundedBorder)
                VoiceDictationButton(text: $viewModel.draft.digitizedText, label: "Dictate record")
            }
            VStack(alignment: .trailing, spacing: 8) {
                TextField("Notes", text: $viewModel.draft.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                VoiceDictationButton(text: $viewModel.draft.notes, label: "Dictate notes")
            }

            HStack {
                Button {
                    saveRecord()
                } label: {
                    Label("Save record", systemImage: "archivebox")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())

                Button {
                    exportRecord()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
            }
        }
        .legacyCard()
    }

    private func currentDraft() -> HistoricalRecordDraft {
        HistoricalRecordDraft(
            fullName: viewModel.draft.fullName,
            birthYear: DigitizerField.parseYear(birthYearText),
            deathYear: DigitizerField.parseYear(deathYearText),
            cemetery: viewModel.draft.cemetery,
            plotPlaceholder: viewModel.draft.plotPlaceholder,
            digitizedText: viewModel.draft.digitizedText,
            notes: viewModel.draft.notes
        )
    }

    private func saveRecord() {
        let draft = currentDraft()
        modelContext.insert(HistoricalRecord(
            fullName: draft.fullName.isEmpty ? "Unnamed record" : draft.fullName,
            birthYear: draft.birthYear,
            deathYear: draft.deathYear,
            cemetery: draft.cemetery,
            plotPlaceholder: draft.plotPlaceholder,
            digitizedText: draft.digitizedText,
            notes: draft.notes
        ))
        do {
            try modelContext.save()
            savedMessage = "Historical record saved locally. Review source material before citing it."
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func exportRecord() {
        do {
            let url = try PDFExportService.makeHistoricalRecordReport(record: currentDraft())
            shareArtifact = ShareArtifact(url: url)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
