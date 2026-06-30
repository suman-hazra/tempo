import Testing
import Foundation

// Tests the pure core function weeklyAverages(from: [(day: Date, kg: Double)]) directly —
// no SwiftData container needed.

@Suite("weeklyAverages()")
struct WeeklyAveragesTests {

    // Calendar used throughout — must match production code
    private static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2  // Monday
        return c
    }()

    // Returns the Monday that starts the week containing 'date'
    private static func monday(of date: Date = Date()) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: calendar.startOfDay(for: date))!.start
    }

    // Returns a date offset from a given Monday
    private static func day(_ offset: Int, from weekStart: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: weekStart)!
    }

    // MARK: - Test cases

    @Test("Empty input returns empty output")
    func emptyInput() {
        let result = weeklyAverages(from: [])
        #expect(result.isEmpty)
    }

    @Test("Single day (Monday) → one week, count = 1, average = that weight")
    func singleDay() {
        let mon = Self.monday()
        let result = weeklyAverages(from: [(day: mon, kg: 80.0)])
        #expect(result.count == 1)
        #expect(result[0].count == 1)
        #expect(result[0].average == 80.0)
    }

    @Test("Full week (Mon–Sun), all logged → arithmetic mean, count = 7")
    func fullWeek() {
        let mon = Self.monday()
        let weights: [Double] = [80, 80.2, 79.8, 80.1, 79.9, 80.3, 80.0]
        let pairs = (0..<7).map { (day: Self.day($0, from: mon), kg: weights[$0]) }
        let result = weeklyAverages(from: pairs)
        #expect(result.count == 1)
        #expect(result[0].count == 7)
        let expected = weights.reduce(0, +) / 7
        #expect(abs(result[0].average - expected) < 0.001)
    }

    @Test("Partial week (Mon–Wed only) → mean of 3 logged days, count = 3 (not 7)")
    func partialWeek() {
        let mon = Self.monday()
        let pairs = (0..<3).map { (day: Self.day($0, from: mon), kg: 80.0) }
        let result = weeklyAverages(from: pairs)
        #expect(result.count == 1)
        #expect(result[0].count == 3)
    }

    @Test("Gap week between two logged weeks → two results, gap week omitted")
    func gapWeek() {
        let thisMonday = Self.monday()
        let twoWeeksAgo = Self.calendar.date(byAdding: .weekOfYear, value: -2, to: thisMonday)!
        let pairs: [(day: Date, kg: Double)] = [
            (day: twoWeeksAgo, kg: 82.0),
            (day: thisMonday, kg: 80.0)
        ]
        let result = weeklyAverages(from: pairs)
        #expect(result.count == 2)
        // Results sorted oldest first
        #expect(result[0].average == 82.0)
        #expect(result[1].average == 80.0)
    }

    @Test("Days with no weight entry are excluded — not averaged as zero")
    func missingDaysNotZeroed() {
        let mon = Self.monday()
        // Only log 2 of 7 days; the other 5 days have no entry (not present in pairs)
        let pairs: [(day: Date, kg: Double)] = [
            (day: Self.day(0, from: mon), kg: 80.0),
            (day: Self.day(3, from: mon), kg: 82.0)
        ]
        let result = weeklyAverages(from: pairs)
        #expect(result.count == 1)
        #expect(result[0].count == 2)
        #expect(result[0].average == 81.0)  // (80 + 82) / 2, not (80 + 82) / 7
    }

    @Test("Week crossing a month/year boundary is treated as one week, not split")
    func monthBoundaryCrossing() {
        // Find a Sunday close to month end so the week spans two months.
        // Use a known date: Dec 30 2024 is a Monday (start of week), ends Jan 5 2025.
        var comps = DateComponents(year: 2024, month: 12, day: 30)
        guard let dec30 = Self.calendar.date(from: comps) else { return }
        var jan4Comps = DateComponents(year: 2025, month: 1, day: 4)
        guard let jan4 = Self.calendar.date(from: jan4Comps) else { return }

        let pairs: [(day: Date, kg: Double)] = [
            (day: dec30, kg: 80.0),
            (day: jan4, kg: 82.0)
        ]
        let result = weeklyAverages(from: pairs)
        // Should be ONE week, not two
        #expect(result.count == 1)
        #expect(result[0].count == 2)
        #expect(result[0].average == 81.0)
    }

    @Test("Results are sorted ascending by weekStart")
    func sortedAscending() {
        let thisMonday = Self.monday()
        let lastMonday = Self.calendar.date(byAdding: .weekOfYear, value: -1, to: thisMonday)!
        let pairs: [(day: Date, kg: Double)] = [
            (day: thisMonday, kg: 79.0),   // newer week first in input
            (day: lastMonday, kg: 81.0)
        ]
        let result = weeklyAverages(from: pairs)
        #expect(result.count == 2)
        #expect(result[0].weekStart < result[1].weekStart)
        #expect(result[0].average == 81.0)
        #expect(result[1].average == 79.0)
    }
}
