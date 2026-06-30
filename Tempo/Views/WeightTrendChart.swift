import SwiftUI
import Charts

enum ChartRange: String, CaseIterable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case all = "All"

    var dayCount: Int? {
        switch self {
        case .oneWeek:      return 7
        case .oneMonth:     return 30
        case .threeMonths:  return 90
        case .all:          return nil
        }
    }
}

struct WeightTrendChart: View {
    let logs: [DayLog]
    let weeklyAverages: [WeeklyAverage]

    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    @State private var selectedRange: ChartRange = .oneMonth

    private var cutoffDate: Date? {
        guard let days = selectedRange.dayCount else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: Date())
    }

    private var filteredLogs: [DayLog] {
        guard let cutoff = cutoffDate else { return logs }
        return logs.filter { $0.day >= cutoff }
    }

    private var filteredWeeklyAvgs: [WeeklyAverage] {
        guard let cutoff = cutoffDate else { return weeklyAverages }
        return weeklyAverages.filter { $0.weekStart >= cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Range", selection: $selectedRange) {
                ForEach(ChartRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            Chart {
                // Daily weight dots — lighter, background series
                ForEach(filteredLogs, id: \.id) { log in
                    if let sample = log.samples.first(where: { $0.metric?.kind == .weight }) {
                        let displayValue = TempoUnits.displayWeight(sample.value, unit: weightUnit)
                        PointMark(
                            x: .value("Date", log.day, unit: .day),
                            y: .value("Weight", displayValue)
                        )
                        .foregroundStyle(.blue.opacity(0.35))
                        .symbolSize(28)
                    }
                }

                // Weekly average line — bold, the headline series
                ForEach(filteredWeeklyAvgs, id: \.weekStart) { wa in
                    let displayValue = TempoUnits.displayWeight(wa.average, unit: weightUnit)
                    LineMark(
                        x: .value("Week", wa.weekStart, unit: .weekOfYear),
                        y: .value("Avg", displayValue)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Week", wa.weekStart, unit: .weekOfYear),
                        y: .value("Avg", displayValue)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(55)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(String(format: "%.0f", v))
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
