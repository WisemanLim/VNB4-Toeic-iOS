import Foundation

/// Seed-backed mock routing for the guest/offline path (RN `mocks.ts`).
/// Returns encoded JSON `Data` for a given path so the client decodes it uniformly.
enum Mocks {
    static func resolve(path: String, method: String) -> Data? {
        let (route, query) = split(path)
        switch route {
        case "/words":
            let part = Int(query["part"] ?? "")
            let items = part == nil ? Seed.words : Seed.words.filter { $0.part == part }
            return encode(WordList(items: items, nextCursor: nil))

        case "/sentences":
            let part = Int(query["part"] ?? "") ?? 0
            let items = Seed.sentences.filter { $0.part == part }
                .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
            return encode(SentenceList(items: items, nextCursor: nil))

        case "/me/analysis":
            // Guest has not tested → empty gray donut + CTA (RN behaviour).
            return encode(Analysis(avgScore: 0, targetScore: 900, tested: false, segments: []))

        case "/progress/stats":
            // Review-queue count surfaced on home; guest sample size.
            let n = min(30, Seed.words.count)
            return encode([ProgressStat(state: "review", _count: .init(_all: n))])

        case "/progress/due":
            let items = Seed.words.prefix(30).map { Progress(id: $0.id, wordId: $0.id, word: $0) }
            return encode(Array(items))

        case "/lessons":
            // One starter lesson per part from the seed.
            let lessons: [Lesson] = (1...7).map { p in
                let words = Seed.words.filter { $0.part == p }.prefix(20)
                    .map { LessonWord(wordId: $0.id, word: $0) }
                return Lesson(id: "part-\(p)", title: "Part \(p)", part: p, orderIndex: p, words: words)
            }
            return encode(lessons)

        default:
            return nil
        }
    }

    private static func split(_ path: String) -> (String, [String: String]) {
        guard let q = path.firstIndex(of: "?") else { return (path, [:]) }
        let route = String(path[..<q])
        var dict: [String: String] = [:]
        for pair in path[path.index(after: q)...].split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { dict[String(kv[0])] = String(kv[1]) }
        }
        return (route, dict)
    }

    private static func encode<T: Encodable>(_ v: T) -> Data? { try? JSONEncoder().encode(v) }
}

// Response envelopes (RN WordListSchema / SentenceListSchema / progress).
struct WordList: Codable { let items: [Word]; let nextCursor: String? }
struct SentenceList: Codable { let items: [SentenceItem]; let nextCursor: String? }
struct Progress: Codable, Identifiable { let id: String; let wordId: String; let word: Word }
struct ProgressStat: Codable {
    let state: String
    let _count: Count
    struct Count: Codable { let _all: Int }
}
struct Lesson: Codable, Identifiable { let id: String; let title: String?; let part: Int?; let orderIndex: Int?; let words: [LessonWord] }
struct LessonWord: Codable { let wordId: String; let word: Word }

// Word/SentenceItem decode-only inits exist; provide encode by re-deriving from stored props.
// Codable synthesis is unavailable because of custom init(from:), so add encode(to:).
extension Word {
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(word, forKey: .word)
        try c.encode(meaningKo, forKey: .meaningKo)
        try c.encodeIfPresent(pos, forKey: .pos)
        try c.encodeIfPresent(ipa, forKey: .ipa)
        try c.encodeIfPresent(pronKo, forKey: .pronKo)
        try c.encodeIfPresent(exampleEn, forKey: .exampleEn)
        try c.encodeIfPresent(exampleKo, forKey: .exampleKo)
        try c.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(part, forKey: .part)
        try c.encodeIfPresent(topic, forKey: .topic)
        try c.encodeIfPresent(synonyms, forKey: .synonyms)
        try c.encodeIfPresent(frequencyTier, forKey: .frequencyTier)
        try c.encode(audio, forKey: .audio)
    }
}
extension SentenceItem {
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(part, forKey: .part)
        try c.encodeIfPresent(day, forKey: .day)
        try c.encodeIfPresent(order, forKey: .order)
        try c.encode(prompt, forKey: .prompt)
        try c.encode(answer, forKey: .answer)
        try c.encode(fullSentence, forKey: .fullSentence)
        try c.encode(translationKo, forKey: .translationKo)
        try c.encode(tokens, forKey: .tokens)
    }
}
