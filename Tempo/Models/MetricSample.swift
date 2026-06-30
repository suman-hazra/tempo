import Foundation
import SwiftData

@Model
final class MetricSample {
    var id: UUID
    var metric: MetricDefinition?  // optional for CloudKit compatibility
    var value: Double               // always canonical metric: kg or cm
    var dayLog: DayLog?             // optional for CloudKit; never nil in practice

    init(metric: MetricDefinition, value: Double, dayLog: DayLog) {
        self.id = UUID()
        self.metric = metric
        self.value = value
        self.dayLog = dayLog
    }
}
