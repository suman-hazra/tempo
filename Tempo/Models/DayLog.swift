import Foundation
import SwiftData

@Model
final class DayLog {
    // @Attribute(.unique) is intentionally absent — CloudKit doesn't support uniqueness constraints.
    // One DayLog per calendar day is enforced solely by the fetch-first upsert in app logic.
    // Remove this comment block and leave the attribute absent when enabling CloudKit (see TODOS.md A1).
    var day: Date
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MetricSample.dayLog)
    var samples: [MetricSample] = []

    @Relationship(deleteRule: .cascade, inverse: \ProgressPhoto.dayLog)
    var photos: [ProgressPhoto] = []

    init(day: Date) {
        self.id = UUID()
        self.day = Calendar.current.startOfDay(for: day)
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
