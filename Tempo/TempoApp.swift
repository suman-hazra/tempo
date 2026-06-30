import SwiftUI
import SwiftData

@main
struct TempoApp: App {
    let container: ModelContainer

    init() {
        do {
            // Local-only configuration. To enable CloudKit: replace with
            // ModelConfiguration(cloudKitDatabase: .private("iCloud.com.yourname.tempo"))
            // and first remove the missing @Attribute(.unique) note from DayLog.swift (see TODOS.md A1).
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(
                for: DayLog.self, MetricDefinition.self, MetricSample.self, ProgressPhoto.self,
                configurations: config
            )
            seedDefaultDefinitions(in: container.mainContext)
        } catch {
            fatalError("ModelContainer setup failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    // Fetch-first idempotent seeding — safe to call on every launch.
    private func seedDefaultDefinitions(in context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<MetricDefinition>())) ?? []
        if !all.contains(where: { $0.kind == .weight }) {
            context.insert(MetricDefinition(kind: .weight, name: "Weight", isDefault: true, sortOrder: 0))
        }
        if !all.contains(where: { $0.kind == .waist }) {
            context.insert(MetricDefinition(kind: .waist, name: "Waist", isDefault: true, sortOrder: 1))
        }
        try? context.save()
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "chart.line.uptrend.xyaxis") }
            TodayView()
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }
        }
    }
}
