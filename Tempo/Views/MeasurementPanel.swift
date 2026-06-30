import SwiftUI
import SwiftData

struct MeasurementPanel: View {
    let log: DayLog?

    @AppStorage("lengthUnit") private var lengthUnit: LengthUnit = .cm
    @Query(
        filter: #Predicate<MetricDefinition> { $0.archivedAt == nil },
        sort: \MetricDefinition.sortOrder
    )
    private var definitions: [MetricDefinition]

    private var measurementDefs: [MetricDefinition] {
        definitions.filter { $0.kind != .weight }
    }

    var body: some View {
        if !measurementDefs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(measurementDefs, id: \.id) { def in
                    HStack {
                        Text(def.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let sample = log?.samples.first(where: { $0.metric?.id == def.id }) {
                            Text(TempoUnits.lengthString(sample.value, unit: lengthUnit))
                                .font(.subheadline.weight(.medium))
                        } else {
                            Text("—")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
