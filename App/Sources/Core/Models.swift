import Foundation

// API payload models — ported from RN `src/core/schemas.ts` (Zod single source).
// Lenient decoding mirrors the Zod relaxations:
//   • `part` arrives as Int (offline seed) OR "P1".."P7" (backend enum) → coerce to Int.
//   • optional fields are nullish (backend null / mock omitted) → Optionals.
//   • `pos` is free-form (abbreviations like "prep"/"adj") → plain String.
//   • `audio` defaults to [] when absent.

/// Coerce a JSON value that may be Int or "P1"-style String into an Int.
private func flexInt(_ c: KeyedDecodingContainer<Word.CodingKeys>, _ key: Word.CodingKeys) -> Int? {
    if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return i }
    if let s = try? c.decodeIfPresent(String.self, forKey: key) {
        let digits = s.filter { $0.isNumber }
        return Int(digits)
    }
    return nil
}

struct AudioClip: Codable, Hashable {
    let locale: String      // "en_US" | "en_GB" | "en_AU"
    let provider: String?
    let url: String

    /// "en_US" → "en-US" (display + BCP-47 voice lookup).
    var bcp47: String { locale.replacingOccurrences(of: "_", with: "-") }
}

struct Word: Codable, Identifiable, Hashable {
    let id: String
    let word: String
    let meaningKo: String
    let pos: String?
    let ipa: String?
    let pronKo: String?
    let exampleEn: String?
    let exampleKo: String?
    let imageUrl: String?
    let part: Int?
    let topic: [String]?
    let synonyms: [String]?
    let frequencyTier: Int?
    let audio: [AudioClip]

    enum CodingKeys: String, CodingKey {
        case id, word, meaningKo, pos, ipa, pronKo, exampleEn, exampleKo
        case imageUrl, part, topic, synonyms, frequencyTier, audio
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        word = try c.decode(String.self, forKey: .word)
        meaningKo = (try? c.decode(String.self, forKey: .meaningKo)) ?? ""
        pos = try? c.decodeIfPresent(String.self, forKey: .pos)
        ipa = try? c.decodeIfPresent(String.self, forKey: .ipa)
        pronKo = try? c.decodeIfPresent(String.self, forKey: .pronKo)
        exampleEn = try? c.decodeIfPresent(String.self, forKey: .exampleEn)
        exampleKo = try? c.decodeIfPresent(String.self, forKey: .exampleKo)
        imageUrl = try? c.decodeIfPresent(String.self, forKey: .imageUrl)
        part = flexInt(c, .part)
        topic = try? c.decodeIfPresent([String].self, forKey: .topic)
        synonyms = try? c.decodeIfPresent([String].self, forKey: .synonyms)
        frequencyTier = try? c.decodeIfPresent(Int.self, forKey: .frequencyTier)
        audio = (try? c.decodeIfPresent([AudioClip].self, forKey: .audio)) ?? []
    }
}

struct SentenceItem: Codable, Identifiable, Hashable {
    let id: String
    let part: Int
    let day: Int?
    let order: Int?
    let prompt: String
    let answer: String
    let fullSentence: String
    let translationKo: String
    let tokens: [String]

    enum CodingKeys: String, CodingKey {
        case id, part, day, order, orderIndex, prompt, answer, fullSentence, translationKo, tokens
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        if let i = try? c.decode(Int.self, forKey: .part) {
            part = i
        } else if let s = try? c.decode(String.self, forKey: .part) {
            part = Int(s.filter { $0.isNumber }) ?? 0
        } else { part = 0 }
        day = try? c.decodeIfPresent(Int.self, forKey: .day)
        order = (try? c.decodeIfPresent(Int.self, forKey: .order))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .orderIndex)) ?? nil
        prompt = try c.decode(String.self, forKey: .prompt)
        answer = try c.decode(String.self, forKey: .answer)
        fullSentence = try c.decode(String.self, forKey: .fullSentence)
        translationKo = (try? c.decode(String.self, forKey: .translationKo)) ?? ""
        tokens = (try? c.decodeIfPresent([String].self, forKey: .tokens)) ?? []
    }
}

struct AnalysisSegment: Codable, Hashable {
    let label: String
    let value: Double
    let color: String
}

struct Analysis: Codable {
    let avgScore: Double
    let targetScore: Double
    let tested: Bool
    let segments: [AnalysisSegment]

    init(avgScore: Double = 0, targetScore: Double = 900, tested: Bool = false, segments: [AnalysisSegment] = []) {
        self.avgScore = avgScore
        self.targetScore = targetScore
        self.tested = tested
        self.segments = segments
    }
}

struct SessionUser: Codable {
    let id: String
    let email: String
    let role: String
    let name: String?
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: SessionUser?
}
