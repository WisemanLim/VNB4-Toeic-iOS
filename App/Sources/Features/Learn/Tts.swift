import AVFoundation

/// Multinational TTS via the system speech synthesizer (RN used expo-av + remote
/// TTS URLs; PRD §5 decided AVSpeechSynthesizer). Speaks the given text in the
/// requested locale's voice (en-US / en-GB / en-AU), offline.
@MainActor
final class Tts {
    static let shared = Tts()
    private let synth = AVSpeechSynthesizer()

    /// `locale` is BCP-47 ("en-US"). Falls back to en-US when unavailable.
    func speak(_ text: String, locale: String = "en-US") {
        guard !text.isEmpty else { return }
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: locale)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        synth.speak(u)
    }
}
