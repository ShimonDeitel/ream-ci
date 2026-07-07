import Foundation
import Combine

@MainActor
final class ReamStore: ObservableObject {
    @Published private(set) var kids: [Kid] = []
    @Published private(set) var items: [SupplyItem] = []

    static let freeSupplyLimit = 5

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("ream_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if kids.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let kid = Kid(name: "Sam")
        kids = [kid]
        items = [
            SupplyItem(kidID: kid.id, name: "No. 2 Pencils", kind: .pencil, level: 0.6),
            SupplyItem(kidID: kid.id, name: "Glue Stick", kind: .glueStick, level: 0.3)
        ]
        save()
    }

    // MARK: - Kids

    func canAddKid(isPro: Bool) -> Bool {
        isPro || kids.count < 1
    }

    @discardableResult
    func addKid(name: String, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddKid(isPro: isPro) else { return false }
        kids.append(Kid(name: trimmed))
        save()
        return true
    }

    func renameKid(_ id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = kids.firstIndex(where: { $0.id == id }) else { return }
        kids[idx].name = trimmed
        save()
    }

    func deleteKid(_ id: UUID) {
        kids.removeAll { $0.id == id }
        items.removeAll { $0.kidID == id }
        save()
    }

    // MARK: - Supplies

    func supplies(for kidID: UUID) -> [SupplyItem] {
        items.filter { $0.kidID == kidID }
    }

    func canAddSupply(isPro: Bool) -> Bool {
        isPro || items.count < Self.freeSupplyLimit
    }

    @discardableResult
    func addSupply(kidID: UUID, name: String, kind: SupplyKind, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddSupply(isPro: isPro) else { return false }
        items.append(SupplyItem(kidID: kidID, name: trimmed, kind: kind))
        save()
        return true
    }

    func updateSupply(_ id: UUID, name: String, kind: SupplyKind, restockThreshold: Double) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].name = trimmed
        items[idx].kind = kind
        items[idx].restockThreshold = restockThreshold
        save()
    }

    func deleteSupply(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func useSupply(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].use()
        save()
    }

    func restockSupply(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].restock()
        save()
    }

    var restockNeededCount: Int {
        items.filter { $0.needsRestock }.count
    }

    func deleteAllData() {
        kids = []
        items = []
        seedDefaults()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var kids: [Kid]
        var items: [SupplyItem]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            kids = decoded.kids
            items = decoded.items
        }
    }

    private func save() {
        let snapshot = Snapshot(kids: kids, items: items)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
