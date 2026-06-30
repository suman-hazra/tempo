import SwiftUI

struct TrendHeaderView: View {
    let weeklyAverages: [WeeklyAverage]

    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg

    private var thisWeek: WeeklyAverage? { weeklyAverages.last }
    private var lastWeek: WeeklyAverage? {
        weeklyAverages.count >= 2 ? weeklyAverages[weeklyAverages.count - 2] : nil
    }

    private var delta: Double? {
        guard let this = thisWeek, let last = lastWeek else { return nil }
        return this.average - last.average
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Weekly Average")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            if let avg = thisWeek {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(TempoUnits.weightString(avg.average, unit: weightUnit))
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    if let d = delta {
                        deltaLabel(d)
                    }
                }
                Text("\(avg.count) day\(avg.count == 1 ? "" : "s") logged this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Log a few days to see your trend")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func deltaLabel(_ delta: Double) -> some View {
        let displayDelta = TempoUnits.displayWeight(abs(delta), unit: weightUnit)
        let isPositive = delta > 0
        return HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
            Text(String(format: "%.1f", displayDelta))
        }
        .font(.callout.weight(.semibold))
        .foregroundStyle(delta == 0 ? Color.secondary : (isPositive ? .red : .green))
    }
}
