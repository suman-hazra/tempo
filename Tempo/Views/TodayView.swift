import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context

    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    @AppStorage("lengthUnit") private var lengthUnit: LengthUnit = .cm

    @Query(sort: \DayLog.day, order: .reverse) private var allLogs: [DayLog]
    @Query(
        filter: #Predicate<MetricDefinition> { $0.archivedAt == nil },
        sort: \MetricDefinition.sortOrder
    )
    private var definitions: [MetricDefinition]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var weightInput: String = ""
    @State private var measurementInputs: [UUID: String] = [:]
    @State private var isSaving = false

    // Fetch or create logic uses selectedDate, not always today
    private var existingLog: DayLog? {
        let day = Calendar.current.startOfDay(for: selectedDate)
        return allLogs.first { $0.day == day }
    }

    private var weightDef: MetricDefinition? { definitions.first { $0.kind == .weight } }
    private var measurementDefs: [MetricDefinition] { definitions.filter { $0.kind != .weight } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .onChange(of: selectedDate) { _, _ in loadExisting() }
                }

                Section("Weight") {
                    HStack {
                        TextField("0.0", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .font(.title2.monospacedDigit())
                        Text(weightUnit.rawValue)
                            .foregroundStyle(.secondary)
                    }
                }

                if !measurementDefs.isEmpty {
                    Section("Measurements") {
                        ForEach(measurementDefs, id: \.id) { def in
                            HStack {
                                Text(def.name)
                                    .frame(width: 80, alignment: .leading)
                                TextField("0.0", text: binding(for: def.id))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                Text(lengthUnit.rawValue)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button(action: save) {
                        Group {
                            if isSaving {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Text("Save")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .disabled(weightInput.isEmpty || isSaving)
                }
            }
            .navigationTitle("Log")
            .onAppear { loadExisting() }
        }
    }

    // MARK: - Helpers

    private func binding(for defID: UUID) -> Binding<String> {
        Binding(
            get: { measurementInputs[defID] ?? "" },
            set: { measurementInputs[defID] = $0 }
        )
    }

    private func loadExisting() {
        guard let log = existingLog else {
            // Pre-populate weight from the most recent prior log
            if let priorLog = allLogs.first(where: { $0.day < Calendar.current.startOfDay(for: selectedDate) }),
               let priorSample = priorLog.samples.first(where: { $0.metric?.kind == .weight }) {
                let display = TempoUnits.displayWeight(priorSample.value, unit: weightUnit)
                weightInput = String(display)
            } else {
                weightInput = ""
            }
            measurementInputs = [:]
            return
        }

        // Load existing weight
        if let sample = log.samples.first(where: { $0.metric?.kind == .weight }) {
            weightInput = String(TempoUnits.displayWeight(sample.value, unit: weightUnit))
        }

        // Load existing measurements
        measurementInputs = [:]
        for def in measurementDefs {
            if let sample = log.samples.first(where: { $0.metric?.id == def.id }) {
                measurementInputs[def.id] = String(TempoUnits.displayLength(sample.value, unit: lengthUnit))
            }
        }
    }

    // MARK: - Upsert contract
    // 1. Fetch or create DayLog for selectedDate
    // 2. Set updatedAt = Date()
    // 3. Delete existing sample for metric before inserting updated value
    // 4. Save
    private func save() {
        isSaving = true
        defer { isSaving = false }

        let day = Calendar.current.startOfDay(for: selectedDate)
        let entry: DayLog
        if let existing = existingLog {
            entry = existing
        } else {
            entry = DayLog(day: day)
            context.insert(entry)
        }
        entry.updatedAt = Date()

        // Weight
        if let raw = Double(weightInput), raw > 0, let def = weightDef {
            let kg = TempoUnits.toKg(raw, from: weightUnit)
            entry.samples.filter { $0.metric?.kind == .weight }.forEach { context.delete($0) }
            context.insert(MetricSample(metric: def, value: kg, dayLog: entry))
        }

        // Measurements
        for def in measurementDefs {
            if let inputStr = measurementInputs[def.id], let raw = Double(inputStr), raw > 0 {
                let cm = TempoUnits.toCm(raw, from: lengthUnit)
                entry.samples.filter { $0.metric?.id == def.id }.forEach { context.delete($0) }
                context.insert(MetricSample(metric: def, value: cm, dayLog: entry))
            }
        }

        try? context.save()
    }
}
