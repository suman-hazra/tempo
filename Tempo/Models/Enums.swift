import Foundation

enum MetricKind: String, Codable {
    case weight, waist, custom
}

enum PhotoAngle: String, Codable, CaseIterable {
    case front, side, back
}

// Used with @AppStorage — RawRepresentable<String> conformance is automatic
enum WeightUnit: String, CaseIterable {
    case kg, lb
}

enum LengthUnit: String, CaseIterable {
    case cm
    case inch = "in"  // rawValue "in" matches display label; avoids Swift keyword backtick
}
