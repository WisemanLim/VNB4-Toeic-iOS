import CoreData

/// On-device persistence (PRD: 즐겨찾기/진도 영속화). CoreData with a *programmatic*
/// model — no .xcdatamodeld, no third-party dependency (GRDB would need an SPM fetch).
/// Entities: Favorite(wordId), WordProgress(wordId, grade, updatedAt).
@MainActor
final class Persistence {
    static let shared = Persistence()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Persistence.makeModel()
        container = NSPersistentContainer(name: "VNB4", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, _ in }
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    var context: NSManagedObjectContext { container.viewContext }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let favorite = NSEntityDescription()
        favorite.name = "Favorite"
        favorite.properties = [attr("wordId", .stringAttributeType)]

        let progress = NSEntityDescription()
        progress.name = "WordProgress"
        progress.properties = [
            attr("wordId", .stringAttributeType),
            attr("grade", .integer16AttributeType, optional: false, default: 0),
            attr("updatedAt", .dateAttributeType),
        ]

        model.entities = [favorite, progress]
        return model
    }

    private static func attr(_ name: String, _ type: NSAttributeType, optional: Bool = true, default def: Any? = nil) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        a.defaultValue = def
        return a
    }
}

/// Favorites + learning progress, persisted via CoreData + UserDefaults. Observable for SwiftUI.
@MainActor
final class LocalStore: ObservableObject {
    static let shared = LocalStore()

    @Published private(set) var favorites: Set<String> = []
    @Published private(set) var bookmarkedWords: [Word] = []
    @Published private(set) var bookmarkedSentences: [SentenceItem] = []

    private let ctx: NSManagedObjectContext
    private let ud = UserDefaults.standard

    init(context: NSManagedObjectContext = Persistence.shared.context) {
        ctx = context
        favorites = loadFavorites()
        bookmarkedWords = loadUD([Word].self, key: "bm_words") ?? []
        bookmarkedSentences = loadUD([SentenceItem].self, key: "bm_sentences") ?? []
    }

    // MARK: – Word bookmarks

    func isFavorite(_ wordId: String) -> Bool { favorites.contains(wordId) }

    func toggleFavorite(_ word: Word) {
        if favorites.contains(word.id) {
            deleteFavorite(word.id)
            favorites.remove(word.id)
            bookmarkedWords.removeAll { $0.id == word.id }
        } else {
            insertFavorite(word.id)
            favorites.insert(word.id)
            bookmarkedWords.append(word)
        }
        saveUD(bookmarkedWords, key: "bm_words")
        save()
    }

    // MARK: – Sentence bookmarks

    func isSentenceFavorite(_ id: String) -> Bool {
        bookmarkedSentences.contains { $0.id == id }
    }

    func toggleSentenceFavorite(_ sentence: SentenceItem) {
        if isSentenceFavorite(sentence.id) {
            bookmarkedSentences.removeAll { $0.id == sentence.id }
        } else {
            bookmarkedSentences.append(sentence)
        }
        saveUD(bookmarkedSentences, key: "bm_sentences")
    }

    // MARK: – Learn progress (lessonId → idx)

    func saveProgress(lessonId: String, idx: Int) {
        var map = loadUD([String: Int].self, key: "learn_progress") ?? [:]
        map[lessonId] = idx
        saveUD(map, key: "learn_progress")
    }

    func loadProgress(lessonId: String) -> Int {
        (loadUD([String: Int].self, key: "learn_progress") ?? [:])[lessonId] ?? 0
    }

    // MARK: – SRS due (guest path: words with grade < GRADE_KNOWN=4)

    var localDueCount: Int {
        let req = NSFetchRequest<NSManagedObject>(entityName: "WordProgress")
        req.predicate = NSPredicate(format: "grade < 4")
        return (try? ctx.count(for: req)) ?? 0
    }

    func localDueWords(limit: Int) -> [Word] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "WordProgress")
        req.predicate = NSPredicate(format: "grade < 4")
        req.sortDescriptors = [NSSortDescriptor(key: "grade", ascending: true),
                               NSSortDescriptor(key: "updatedAt", ascending: true)]
        req.fetchLimit = limit
        let rows = (try? ctx.fetch(req)) ?? []
        let ids = rows.compactMap { $0.value(forKey: "wordId") as? String }
        let wordMap = Dictionary(uniqueKeysWithValues: Seed.words.map { ($0.id, $0) })
        return ids.compactMap { wordMap[$0] }
    }

    // MARK: – SRS grade

    func recordGrade(wordId: String, grade: Int) {
        let req = NSFetchRequest<NSManagedObject>(entityName: "WordProgress")
        req.predicate = NSPredicate(format: "wordId == %@", wordId)
        let row = (try? ctx.fetch(req))?.first
            ?? NSEntityDescription.insertNewObject(forEntityName: "WordProgress", into: ctx)
        row.setValue(wordId, forKey: "wordId")
        row.setValue(grade, forKey: "grade")
        row.setValue(Date(), forKey: "updatedAt")
        save()
    }

    var learnedCount: Int {
        let req = NSFetchRequest<NSManagedObject>(entityName: "WordProgress")
        return (try? ctx.count(for: req)) ?? 0
    }

    // MARK: – CoreData helpers

    private func loadFavorites() -> Set<String> {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Favorite")
        let rows = (try? ctx.fetch(req)) ?? []
        return Set(rows.compactMap { $0.value(forKey: "wordId") as? String })
    }

    private func insertFavorite(_ wordId: String) {
        let row = NSEntityDescription.insertNewObject(forEntityName: "Favorite", into: ctx)
        row.setValue(wordId, forKey: "wordId")
    }

    private func deleteFavorite(_ wordId: String) {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Favorite")
        req.predicate = NSPredicate(format: "wordId == %@", wordId)
        (try? ctx.fetch(req))?.forEach { ctx.delete($0) }
    }

    private func save() { if ctx.hasChanges { try? ctx.save() } }

    // MARK: – UserDefaults JSON helpers

    private func loadUD<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = ud.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func saveUD<T: Encodable>(_ value: T, key: String) {
        ud.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
