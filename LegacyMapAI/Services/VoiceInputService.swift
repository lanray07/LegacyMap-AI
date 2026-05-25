import AVFoundation
import Foundation
import Speech

@MainActor
final class VoiceInputService: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var authorizationStatus = SFSpeechRecognizer.authorizationStatus()

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_GB"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var canRecord: Bool {
        authorizationStatus == .authorized && speechRecognizer?.isAvailable == true
    }

    func requestPermissions() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        authorizationStatus = speechAllowed

        let microphoneAllowed = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }

        if speechAllowed != .authorized {
            errorMessage = "Speech recognition permission is needed for voice input."
        } else if !microphoneAllowed {
            errorMessage = "Microphone permission is needed for voice input."
        } else if speechRecognizer?.isAvailable != true {
            errorMessage = "Speech recognition is not currently available. Try again later."
        } else {
            errorMessage = nil
        }

        return speechAllowed == .authorized && microphoneAllowed && speechRecognizer?.isAvailable == true
    }

    func startDictation(onTranscript: @escaping (String) -> Void) async {
        guard !isRecording else { return }
        guard await requestPermissions() else { return }

        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true

            recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let result {
                        let text = result.bestTranscription.formattedString
                        self.transcript = text
                        onTranscript(text)
                    }

                    if error != nil || result?.isFinal == true {
                        self.stopDictation()
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            stopDictation()
        }
    }

    func stopDictation() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
