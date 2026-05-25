# LegacyMap AI

LegacyMap AI is a SwiftUI iOS app scaffold for cemetery mapping, genealogy research support, memorial preservation, OCR-assisted headstone scanning, death record digitization, volunteer restoration requests, and cautious AI-generated historical summaries.

It also includes voice input for names, inscriptions, cemetery search terms, volunteer notes, memorial summaries, and historical record transcription fields.

Core positioning: Preserve the past. Reconnect forgotten stories.

Important limitations:

- Informational historical tool only.
- OCR may contain inaccuracies.
- AI outputs require review and independent verification.
- Genealogy connections are placeholders until verified.
- Not legal identity verification.
- Not official archival certification.

## App Store Support

Support: https://github.com/lanray07/legacymap-ai/issues

Marketing: https://github.com/lanray07/legacymap-ai

Privacy Policy: https://github.com/lanray07/LegacyMap-AI/blob/main/PRIVACY.md

Terms Of Use: https://github.com/lanray07/LegacyMap-AI/blob/main/TERMS.md

## Run

Open `LegacyMap AI.xcodeproj` in Xcode, select the shared `LegacyMap AI` scheme, and run on an iOS 17+ simulator or device. Mock AI is enabled by default through `MockAIService`.

The StoreKit 2 scaffolding uses placeholder product IDs:

- `legacy.premium.monthly`
- `legacy.premium.yearly`
- `legacy.heritagepro.monthly`

Attach `LegacyMapAI/Resources/StoreKitConfiguration.storekit` to the scheme in Xcode if your Xcode version does not pick up the shared scheme setting automatically.

Remote AI calls are isolated in `RemoteAIService` and point at `https://YOUR_BACKEND_URL.com/legacymap-ai`. Do not store API keys in the app; put provider credentials on your backend.

Voice input uses Apple Speech and microphone permissions. The app includes `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription` strings in the generated target settings.

## GitHub Xcode Build

This repo includes `.github/workflows/ios-xcode.yml`.

- Pull requests and pushes run a macOS GitHub Actions simulator build with code signing disabled.
- Manual workflow runs can archive and upload to App Store Connect/TestFlight when `upload_testflight` is enabled.

For TestFlight upload, configure these GitHub repository secrets:

- `APPLE_TEAM_ID`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `ASC_API_KEY_ID`
- `ASC_API_ISSUER_ID`
- `ASC_API_PRIVATE_KEY_BASE64`
- `KEYCHAIN_PASSWORD` optional

Do not commit Apple certificates, provisioning profiles, or App Store Connect API keys.
