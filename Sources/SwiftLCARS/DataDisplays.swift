import SwiftUI

public struct LCARSReadout: View {
    public let title: String
    public let value: String
    public let unit: String
    @Environment(\.lcarsTheme) private var theme
    public init(_ title: String, value: String, unit: String = "") {
        self.title = title; self.value = value; self.unit = unit
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).textCase(.uppercase).lcarsDisplay(24).foregroundStyle(theme.secondary.color)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) { number; units }
                VStack(alignment: .leading, spacing: 4) { number; units }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title).accessibilityValue("\(value) \(unit)")
    }
    private var number: some View { Text(value).font(.system(.title, design: .rounded).monospacedDigit()).foregroundStyle(theme.primary.color) }
    private var units: some View { Text(unit).font(.callout).foregroundStyle(theme.mutedText.color) }
}

public struct LCARSMeter: View {
    public let title: String
    public let value: Double
    public let total: Double
    @Environment(\.lcarsTheme) private var theme
    public init(_ title: String, value: Double, total: Double = 1) {
        self.title = title; self.value = value; self.total = total
    }
    public static func fraction(value: Double, total: Double) -> Double {
        guard total.isFinite, total > 0, value.isFinite else { return 0 }
        return min(1, max(0, value / total))
    }
    public var body: some View {
        let fraction = Self.fraction(value: value, total: total)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).textCase(.uppercase).lcarsDisplay(24)
                Spacer()
                Text(fraction, format: .percent.precision(.fractionLength(0))).font(.callout.monospacedDigit())
            }.foregroundStyle(theme.primary.color)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle().fill(theme.secondary.color.opacity(0.25))
                    Rectangle().fill(theme.secondary.color).frame(width: proxy.size.width * fraction)
                }
            }.frame(height: 12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(fraction.formatted(.percent.precision(.fractionLength(0))))
    }
}
