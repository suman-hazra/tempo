import Foundation

struct WeeklyAverage {
    let weekStart: Date  // Monday 00:00:00 in device locale
    let average: Double  // kg — always canonical metric
    let count: Int
}

// Pure core function — takes simple (day, kg) pairs so it's testable without SwiftData.
// Week definition: Monday–Sunday (Calendar firstWeekday = 2).
// Weeks with no weight entries are omitted, not zeroed.
func weeklyAverages(from weightsByDay: [(day: Date, kg: Double)]) -> [WeeklyAverage] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2  // Monday

    var byWeek: [Date: [Double]] = [:]
    for (day, kg) in weightsByDay {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: day)?.start else { continue }
        byWeek[weekStart, default: []].append(kg)
    }

    return byWeek
        .map { weekStart, values in
            WeeklyAverage(
                weekStart: weekStart,
                average: values.reduce(0, +) / Double(values.count),
                count: values.count
            )
        }
        .sorted { $0.weekStart < $1.weekStart }
}

// SwiftData adapter — bridges DayLog to the pure core function.
func weeklyAverages(from logs: [DayLog]) -> [WeeklyAverage] {
    let pairs: [(day: Date, kg: Double)] = logs.compactMap { log in
        guard let sample = log.samples.first(where: { $0.metric?.kind == .weight }) else { return nil }
        return (log.day, sample.value)
    }
    return weeklyAverages(from: pairs)
}
