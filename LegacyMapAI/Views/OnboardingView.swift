import Photos
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var voiceInputService: VoiceInputService
    @State private var selectedInterest: PrimaryInterest = .familyHistory
    @State private var photoStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("LegacyMap AI")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.legacyPaper)
                    Text("Preserve the past. Reconnect forgotten stories.")
                        .font(.title3)
                        .foregroundStyle(.legacyParchment)
                    Text("Every grave has a story waiting to be remembered.")
                        .font(.subheadline)
                        .foregroundStyle(.legacyPaper.opacity(0.82))
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Primary interest", subtitle: "Choose the path closest to today's visit.", systemImage: "sparkles")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(PrimaryInterest.allCases) { interest in
                            Button {
                                selectedInterest = interest
                            } label: {
                                HStack {
                                    Image(systemName: interest.icon)
                                    Text(interest.rawValue)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                }
                                .foregroundStyle(selectedInterest == interest ? .legacyCharcoal : .legacyPaper)
                                .padding(12)
                                .background(selectedInterest == interest ? .legacyGold : .legacyStone.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .legacyCard()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Permissions", subtitle: "You can change these in Settings later.", systemImage: "hand.raised")
                    Button {
                        locationService.requestAuthorization()
                    } label: {
                        Label(locationLabel, systemImage: "location")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Button {
                        requestPhotoAccess()
                    } label: {
                        Label(photoLabel, systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())

                    Button {
                        Task {
                            _ = await voiceInputService.requestPermissions()
                        }
                    } label: {
                        Label(voiceLabel, systemImage: "mic")
                    }
                    .buttonStyle(LegacyPrimaryButtonStyle())
                }
                .legacyCard()

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: LegacyDisclaimer.title, subtitle: "Please review before continuing.", systemImage: "doc.text.magnifyingglass")
                    ForEach(LegacyDisclaimer.bullets, id: \.self) { item in
                        Label(item, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.legacyParchment.opacity(0.86))
                    }
                }
                .legacyCard()

                Button {
                    onComplete()
                } label: {
                    Text("Enter archive")
                }
                .buttonStyle(LegacyPrimaryButtonStyle())
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
    }

    private var locationLabel: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            "Location enabled"
        case .denied, .restricted:
            "Location disabled"
        case .notDetermined:
            "Allow cemetery location"
        @unknown default:
            "Review location access"
        }
    }

    private var photoLabel: String {
        switch photoStatus {
        case .authorized, .limited:
            "Photos enabled"
        case .denied, .restricted:
            "Photos disabled"
        case .notDetermined:
            "Allow photo access"
        @unknown default:
            "Review photo access"
        }
    }

    private var voiceLabel: String {
        switch voiceInputService.authorizationStatus {
        case .authorized:
            "Voice input enabled"
        case .denied, .restricted:
            "Voice input disabled"
        case .notDetermined:
            "Allow voice input"
        @unknown default:
            "Review voice input"
        }
    }

    private func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            Task { @MainActor in
                photoStatus = status
            }
        }
    }
}
