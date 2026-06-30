import Foundation

// Named TempoUnits (not UnitConverter) to avoid shadowing Foundation.UnitConverter.
enum TempoUnits {
    // Conversion constants
    static let lbPerKg: Double = 2.2046226218
    static let kgPerLb: Double = 1.0 / 2.2046226218
    static let cmPerInch: Double = 2.54
    static let inchPerCm: Double = 1.0 / 2.54

    // MARK: - Canonical → display

    static func displayWeight(_ kg: Double, unit: WeightUnit) -> Double {
        let raw = unit == .kg ? kg : kg * lbPerKg
        return (raw * 10).rounded() / 10
    }

    static func displayLength(_ cm: Double, unit: LengthUnit) -> Double {
        let raw = unit == .cm ? cm : cm * inchPerCm
        return (raw * 10).rounded() / 10
    }

    // MARK: - User input → canonical metric

    static func toKg(_ value: Double, from unit: WeightUnit) -> Double {
        unit == .kg ? value : value * kgPerLb
    }

    static func toCm(_ value: Double, from unit: LengthUnit) -> Double {
        unit == .cm ? value : value * cmPerInch
    }

    // MARK: - Formatted strings

    static func weightString(_ kg: Double, unit: WeightUnit) -> String {
        String(format: "%.1f %@", displayWeight(kg, unit: unit), unit.rawValue)
    }

    static func lengthString(_ cm: Double, unit: LengthUnit) -> String {
        String(format: "%.1f %@", displayLength(cm, unit: unit), unit.rawValue)
    }

    // MARK: - Unit labels

    static func weightLabel(_ unit: WeightUnit) -> String { unit.rawValue }
    static func lengthLabel(_ unit: LengthUnit) -> String { unit.rawValue }
}
