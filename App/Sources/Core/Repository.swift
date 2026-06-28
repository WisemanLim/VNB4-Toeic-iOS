import Foundation

/// Data access (ported from RN `queries.ts`). Guest path is served offline by `Mocks`;
/// authed path hits the real backend through `APIClient`.
enum Repo {
    static func lessons() async throws -> [Lesson] {
        try await APIClient.shared.request("/lessons", as: [Lesson].self)
    }

    static func sentences(part: Int) async throws -> [SentenceItem] {
        let list = try await APIClient.shared.request("/sentences?part=\(part)&limit=200", as: SentenceList.self)
        return list.items
    }

    static func analysis() async throws -> Analysis {
        try await APIClient.shared.request("/me/analysis", as: Analysis.self)
    }

    static func dueCount() async throws -> Int {
        let isGuest = await !APIClient.shared.isAuthed()
        if isGuest {
            return await MainActor.run { LocalStore.shared.localDueCount }
        }
        let stats = try await APIClient.shared.request("/progress/stats", as: [ProgressStat].self)
        return stats.first { $0.state == "review" }?._count._all ?? 0
    }

    /// "due" → SRS queue; "part-N" → every word of part N (paged); else a lesson by id.
    static func learnQueue(_ lessonId: String) async throws -> [Word] {
        if lessonId == "due" {
            let isGuest = await !APIClient.shared.isAuthed()
            if isGuest {
                let words = await MainActor.run { LocalStore.shared.localDueWords(limit: 30) }
                return words.isEmpty ? Array(Seed.words.prefix(30)) : words
            }
            let prog = try await APIClient.shared.request("/progress/due?limit=30", as: [Progress].self)
            return prog.map(\.word)
        }
        if lessonId.hasPrefix("part-"), let part = Int(lessonId.dropFirst(5)) {
            var out: [Word] = []
            var cursor: String?
            for _ in 0..<100 {
                let qs = "part=\(part)&limit=100" + (cursor.map { "&cursor=\($0)" } ?? "")
                let res = try await APIClient.shared.request("/words?\(qs)", as: WordList.self)
                out.append(contentsOf: res.items)
                guard let next = res.nextCursor else { break }
                cursor = next
            }
            return out
        }
        let lessons = try await APIClient.shared.request("/lessons", as: [Lesson].self)
        return lessons.first { $0.id == lessonId }?.words.map(\.word) ?? []
    }

    /// Grade a word (SRS). Guest/offline has no route → ignored.
    static func grade(wordId: String, grade: Int) async {
        struct Body: Encodable { let wordId: String; let grade: Int }
        _ = try? await APIClient.shared.request(
            "/progress/grade", method: "POST",
            json: Body(wordId: wordId, grade: grade), as: EmptyResponse.self
        )
    }
}

private struct EmptyResponse: Decodable {
    init(from decoder: Decoder) throws {}
}
