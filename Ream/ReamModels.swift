import Foundation

/// A child whose school supplies are tracked separately from siblings.
struct Kid: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

/// A trackable school supply item belonging to one kid. Quantity is modeled
/// as a fractional "fill level" from 0 (empty) to 1 (brand new/full ream),
/// which drives the pencil/glue-stick shrink visual.
struct SupplyItem: Identifiable, Codable, Equatable {
    let id: UUID
    var kidID: UUID
    var name: String
    var kind: SupplyKind
    /// 0.0 (empty) ... 1.0 (full/new)
    var level: Double
    /// Fraction below which this item is flagged as needing restock.
    var restockThreshold: Double

    init(id: UUID = UUID(), kidID: UUID, name: String, kind: SupplyKind, level: Double = 1.0, restockThreshold: Double = 0.25) {
        self.id = id
        self.kidID = kidID
        self.name = name
        self.kind = kind
        self.level = level
        self.restockThreshold = restockThreshold
    }

    var needsRestock: Bool { level <= restockThreshold }
    var isEmpty: Bool { level <= 0.001 }

    /// How much a single "Use" tap consumes, tuned per kind so pencils wear
    /// slowly and glue sticks/erasers wear faster.
    var useIncrement: Double {
        switch kind {
        case .pencil: return 0.08
        case .glueStick: return 0.12
        case .eraser: return 0.10
        case .notebook: return 0.05
        case .crayon: return 0.10
        case .other: return 0.10
        }
    }

    mutating func use() {
        level = max(0, level - useIncrement)
    }

    mutating func restock() {
        level = 1.0
    }
}

enum SupplyKind: String, Codable, CaseIterable, Identifiable {
    case pencil = "Pencil"
    case glueStick = "Glue Stick"
    case eraser = "Eraser"
    case notebook = "Notebook"
    case crayon = "Crayon"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .pencil: return "pencil"
        case .glueStick: return "paintbrush.pointed.fill"
        case .eraser: return "square.fill"
        case .notebook: return "book.closed.fill"
        case .crayon: return "scribble.variable"
        case .other: return "shippingbox.fill"
        }
    }
}
