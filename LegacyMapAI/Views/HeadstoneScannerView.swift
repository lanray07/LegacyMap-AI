import PhotosUI
import SwiftUI
import UIKit

struct HeadstoneScannerView: View {
    @Environment(\.aiService) private var aiService
    @StateObject private var viewModel = HeadstoneScannerViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var cemeteryName = ""
    @State private var cropNotes = ""
    @State private var showingCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "AI Headstone Scanner", subtitle: "Mock AI OCR restoration is enabled by default.", systemImage: "camera.viewfinder")

                imagePreview

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Cemetery name optional", text: $cemeteryName)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $cemeteryName, label: "Dictate cemetery", separator: " ")
                    }
                    VStack(alignment: .trailing, spacing: 8) {
                        TextField("Crop or faded inscription notes", text: $cropNotes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                        VoiceDictationButton(text: $cropNotes, label: "Dictate notes")
                    }

                    HStack {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Upload photo", systemImage: "photo")
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
                }
                .legacyCard()

                Button {
                    Task {
                        await viewModel.scan(imageData: imageData, cemeteryName: cemeteryName, notes: cropNotes)
                    }
                } label: {
                    Label(viewModel.isScanning ? "Restoring inscription" : "Analyze headstone", systemImage: "wand.and.stars")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
                .disabled(imageData == nil || viewModel.isScanning)

                if viewModel.isScanning {
                    LoadingStateView(message: "Reading possible inscription and preservation clues...")
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                if let result = viewModel.result {
                    OCRResultCard(result: result)
                }

                InsightCard(
                    title: "Cautious language",
                    detail: "Outputs use possible inscription, estimated date, and likely surname because damaged stone OCR must be reviewed by a person.",
                    systemImage: "checkmark.shield"
                )
            }
            .padding()
        }
        .background(LegacyBackground())
        .onAppear {
            viewModel.aiService = aiService
        }
        .onChange(of: photoItem) { _, newItem in
            Task { await loadPhoto(newItem) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(imageData: $imageData)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomLeading) {
                    Text("Crop faded inscription before final OCR in production.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.legacyCharcoal)
                        .padding(8)
                        .background(Color.legacyPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
                        .padding(10)
                }
        } else {
            EmptyStateView(title: "No headstone photo selected", message: "Upload or take a photo to generate a mock OCR restoration result.", systemImage: "camera.viewfinder")
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        imageData = try? await item.loadTransferable(type: Data.self)
    }
}
