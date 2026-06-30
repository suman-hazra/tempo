import Testing
import Foundation

@Suite("TempoUnits")
struct TempoUnitsTests {

    // MARK: - kg ↔ lb

    @Test("toKg: lb → kg conversion")
    func lbToKg() {
        let kg = TempoUnits.toKg(100.0, from: .lb)
        #expect(abs(kg - 45.359237) < 0.0001)
    }

    @Test("toKg: kg passthrough (no conversion)")
    func kgPassthrough() {
        #expect(TempoUnits.toKg(80.0, from: .kg) == 80.0)
    }

    @Test("displayWeight: kg unit rounds to 0.1")
    func displayWeightKg() {
        #expect(TempoUnits.displayWeight(80.12345, unit: .kg) == 80.1)
        #expect(TempoUnits.displayWeight(80.15, unit: .kg) == 80.2)
    }

    @Test("displayWeight: lb unit converts and rounds to 0.1")
    func displayWeightLb() {
        let display = TempoUnits.displayWeight(80.0, unit: .lb)
        // 80 kg * 2.2046226218 = 176.37 lb → rounds to 176.4
        #expect(abs(display - 176.4) < 0.05)
    }

    @Test("Round-trip: lb → kg → lb stays within 0.1")
    func roundTripWeight() {
        let originalLb = 185.5
        let kg = TempoUnits.toKg(originalLb, from: .lb)
        let backToLb = TempoUnits.displayWeight(kg, unit: .lb)
        #expect(abs(backToLb - originalLb) < 0.1)
    }

    // MARK: - cm ↔ inch

    @Test("toCm: inch → cm conversion")
    func inchToCm() {
        let cm = TempoUnits.toCm(1.0, from: .inch)
        #expect(abs(cm - 2.54) < 0.0001)
    }

    @Test("toCm: cm passthrough (no conversion)")
    func cmPassthrough() {
        #expect(TempoUnits.toCm(80.0, from: .cm) == 80.0)
    }

    @Test("displayLength: cm unit rounds to 0.1")
    func displayLengthCm() {
        #expect(TempoUnits.displayLength(75.15, unit: .cm) == 75.2)
        #expect(TempoUnits.displayLength(75.12, unit: .cm) == 75.1)
    }

    @Test("displayLength: inch unit converts and rounds to 0.1")
    func displayLengthInch() {
        let display = TempoUnits.displayLength(25.4, unit: .inch)
        #expect(display == 10.0)  // 25.4 cm = exactly 10 inches
    }

    @Test("Round-trip: inch → cm → inch stays within 0.1")
    func roundTripLength() {
        let originalInch = 31.5
        let cm = TempoUnits.toCm(originalInch, from: .inch)
        let backToInch = TempoUnits.displayLength(cm, unit: .inch)
        #expect(abs(backToInch - originalInch) < 0.1)
    }

    // MARK: - Formatted strings

    @Test("weightString includes unit label")
    func weightStringLabel() {
        let s = TempoUnits.weightString(80.0, unit: .kg)
        #expect(s.hasSuffix("kg"))
    }

    @Test("lengthString includes unit label")
    func lengthStringLabel() {
        let s = TempoUnits.lengthString(80.0, unit: .inch)
        #expect(s.hasSuffix("in"))
    }
}
