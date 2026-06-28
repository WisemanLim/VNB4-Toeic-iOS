import XCTest
@testable import App

final class AppTests: XCTestCase {
    func testEnvFlavorHasDefault() throws {
        // Env.flavor falls back to "Debug" when Info.plist key absent.
        XCTAssertFalse(Env.flavor.isEmpty)
    }

    func testApiBaseHasDefault() throws {
        XCTAssertTrue(Env.apiBase.hasPrefix("http"))
    }

    // MARK: ported decoder relaxations (RN schemas.ts)

    /// `part` arrives as a plain Int from the offline seed.
    func testWordPartAsNumber() throws {
        let json = #"{"id":"w1","word":"pavement","meaningKo":"포장도로","part":1}"#
        let w = try JSONDecoder().decode(Word.self, from: Data(json.utf8))
        XCTAssertEqual(w.part, 1)
        XCTAssertEqual(w.audio.count, 0)   // audio defaults to []
        XCTAssertNil(w.ipa)                // nullish optional
    }

    /// `part` arrives as the backend enum string "P3" → coerced to 3.
    func testWordPartAsEnumString() throws {
        let json = #"{"id":"w2","word":"agenda","meaningKo":"안건","part":"P3","pos":"prep","audio":[{"locale":"en_GB","provider":"tts","url":"https://x/y"}]}"#
        let w = try JSONDecoder().decode(Word.self, from: Data(json.utf8))
        XCTAssertEqual(w.part, 3)
        XCTAssertEqual(w.pos, "prep")      // free-form pos preserved
        XCTAssertEqual(w.audio.first?.bcp47, "en-GB")
    }

    /// SentenceItem accepts `order` (mock) and tokens default.
    func testSentenceDecode() throws {
        let json = #"{"id":"s1","part":1,"order":2,"prompt":"She's ____.","answer":"a b","fullSentence":"She's a b.","translationKo":"x","tokens":["a","b"]}"#
        let s = try JSONDecoder().decode(SentenceItem.self, from: Data(json.utf8))
        XCTAssertEqual(s.part, 1)
        XCTAssertEqual(s.tokens, ["a", "b"])
    }

    /// Word round-trips through encode → decode (Mocks re-encodes seed words).
    func testWordRoundTrip() throws {
        let json = #"{"id":"w3","word":"hello","meaningKo":"안녕","part":2,"audio":[]}"#
        let w = try JSONDecoder().decode(Word.self, from: Data(json.utf8))
        let data = try JSONEncoder().encode(w)
        let again = try JSONDecoder().decode(Word.self, from: data)
        XCTAssertEqual(again.id, "w3")
        XCTAssertEqual(again.part, 2)
    }

    // MARK: iteration 2 — consent gate + persistence

    /// edtech/PIPA §22-2: 만14세 미만 보호자 동의 필요. 입력 없으면 비차단(성인 가정).
    func testGuardianConsentGate() {
        XCTAssertTrue(ConsentGate.requiresGuardianConsent(birthYear: 2015, currentYear: 2026))  // 11세
        XCTAssertFalse(ConsentGate.requiresGuardianConsent(birthYear: 2000, currentYear: 2026)) // 26세
        XCTAssertFalse(ConsentGate.requiresGuardianConsent(birthYear: nil, currentYear: 2026))  // 미입력
        XCTAssertFalse(ConsentGate.requiresGuardianConsent(birthYear: 2012, currentYear: 2026)) // 14세 경계(비차단)
    }

    /// CoreData(프로그래매틱, in-memory) 즐겨찾기 + 진도 영속화 동작.
    @MainActor
    func testLocalStorePersistence() {
        let store = LocalStore(context: Persistence(inMemory: true).context)
        XCTAssertFalse(store.isFavorite("w1"))
        store.toggleFavorite("w1")
        XCTAssertTrue(store.isFavorite("w1"))
        store.toggleFavorite("w1")
        XCTAssertFalse(store.isFavorite("w1"))

        store.recordGrade(wordId: "w2", grade: 4)
        store.recordGrade(wordId: "w2", grade: 1)  // upsert (same row)
        store.recordGrade(wordId: "w3", grade: 4)
        XCTAssertEqual(store.learnedCount, 2)
    }
}
