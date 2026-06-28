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

/// Favorites + learning progress, persisted via CoreData. Observable for SwiftUI.
@MainActor
final class LocalStore: ObservableObject {
    static let shared = LocalStore()

    @Published private(set) var favorites: Set<String> = []
    private let ctx: NSManagedObjectContext

    init(context: NSManagedObjectContext = Persistence.shared.context) {
        ctx = context
        favorites = loadFavorites()
    }

    func isFavorite(_ wordId: String) -> Bool { favorites.contains(wordId) }

    func toggleFavorite(_ wordId: String) {
        if favorites.contains(wordId) { deleteFavorite(wordId); favorites.remove(wordId) }
        else { insertFavorite(wordId); favorites.insert(wordId) }
        save()
    }

    /// Persist an SRS grade locally (guest path; server handles authed grading).
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

    // MARK: CoreData helpers

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
}
