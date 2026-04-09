import AVFoundation
import Observation

@Observable
final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate {
    var isPlaying = false
    var isPaused = false
    var currentParagraphIndex = 0
    var progress: Double = 0

    private let synthesizer = AVSpeechSynthesizer()
    private var paragraphs: [String] = []
    private var pendingParagraphs: [String] = []

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public API

    func speak(paragraphs: [String]) {
        stop()
        self.paragraphs = paragraphs
        guard !paragraphs.isEmpty else { return }
        currentParagraphIndex = 0
        isPlaying = true
        isPaused = false
        configureAudioSession()
        speakParagraph(at: 0)
    }

    func pause() {
        guard isPlaying, !isPaused else { return }
        synthesizer.pauseSpeaking(at: .immediate)
        isPaused = true
    }

    func resume() {
        guard isPlaying, isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentParagraphIndex = 0
        progress = 0
        paragraphs = []
    }

    var totalParagraphs: Int { paragraphs.count }

    // MARK: - Private

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func speakParagraph(at index: Int) {
        guard index < paragraphs.count else {
            // Finished all paragraphs
            isPlaying = false
            isPaused = false
            progress = 1.0
            return
        }
        currentParagraphIndex = index
        updateProgress()

        let utterance = AVSpeechUtterance(string: paragraphs[index])
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.25
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(utterance)
    }

    private func updateProgress() {
        guard !paragraphs.isEmpty else { progress = 0; return }
        progress = Double(currentParagraphIndex) / Double(paragraphs.count)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let nextIndex = currentParagraphIndex + 1
        if nextIndex < paragraphs.count {
            speakParagraph(at: nextIndex)
        } else {
            isPlaying = false
            isPaused = false
            progress = 1.0
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // Handled by stop()
    }
}
