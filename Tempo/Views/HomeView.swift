import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \DayLog.day, order: .reverse) private var allLogs: [DayLog]
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg

    // weeklyAverages() computed once here, passed to both child views — not computed independently.
    private var weeklyAvgs: [WeeklyAverage] { weeklyAverages(from: allLogs) }

    private var latestWeightKg: Double? {
        allLogs.lazy
            .compactMap { $0.samples.first(where: { $0.metric?.kind == .weight })?.value }
            .first
    }

    private var todayLog: DayLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return allLogs.first { $0.day == today }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let kg = latestWeightKg {
                        currentWeightCard(kg: kg)
                    }
                    TrendHeaderView(weeklyAverages: weeklyAvgs)
                    WeightTrendChart(logs: allLogs, weeklyAverages: weeklyAvgs)
                    MeasurementPanel(log: todayLog)
                }
                .padding()
            }
            .navigationTitle("Tempo")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func currentWeightCard(kg: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Current Weight")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(TempoUnits.weightString(kg, unit: weightUnit))
                .font(.system(size: 52, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
