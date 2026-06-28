import Foundation

/// All-parts offline seed bundled into the app (RN `assets/seed/*.json`).
/// Loaded once from the app bundle. Empty if the resource is missing (build still works).
enum Seed {
    static let words: [Word] = load("words", as: [Word].self) ?? []
    static let sentences: [SentenceItem] = load("sentences", as: [SentenceItem].self) ?? []

    private static func load<T: Decodable>(_ name: String, as: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
