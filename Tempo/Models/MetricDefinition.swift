import Foundation
import SwiftData

@Model
final class MetricDefinition {
    var id: UUID
    var kind: MetricKind
    var name: String
    // Canonical storage unit is always "kg" for weight, "cm" for all lengths.
    var sortOrder: Int
    var isDefault: Bool
    var archivedAt: Date?

    init(kind: MetricKind, name: String, isDefault: Bool, sortOrder: Int) {
        self.id = UUID()
        self.kind = kind
        self.name = name
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.archivedAt = nil
    }
}
