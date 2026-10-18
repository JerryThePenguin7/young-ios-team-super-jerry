import AVFoundation

/// Reads Thai text aloud with the device's built-in Thai voice. Works offline.
final class SpeechReader {
    /// One voice for the whole app, so two things never talk at once.
    static let shared = SpeechReader()

    private let synthesizer = AVSpeechSynthesizer()   // must stay alive, or speech stops instantly

    func speak(_ text: String) {
        try? AVAudioSession.sharedInstance().setCategory(.playback)   // still plays when the iPhone is on silent
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "th-TH")
        utterance.rate = 0.42   // a bit slower than normal (0.5) for older listeners
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
