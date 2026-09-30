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

/// A normalized line plot with a caller-supplied accessible interpretation.
/// Non-finite values become zero; values outside 0...1 are clamped.
public struct LCARSSpectrum: View {
    public var samples: [Double]
    public var label: String
    public var summary: String
    @Environment(\.lcarsTheme) private var theme
    public init(samples: [Double], label: String, summary: String) {
        self.samples = samples; self.label = label; self.summary = summary
    }
    public var body: some View {
        VStack(spacing: 4) {
            Canvas { canvas, size in
                var grid = Path()
                for index in 0...4 {
                    let y = size.height * Double(index) / 4
                    grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                    let x = size.width * Double(index) / 4
                    grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                canvas.stroke(grid, with: .color(theme.tertiary.color.opacity(0.5)), lineWidth: 0.5)
                guard samples.count > 1 else { return }
                var trace = Path()
                for (index, sample) in samples.enumerated() {
                    let value = sample.isFinite ? min(1, max(0, sample)) : 0
                    let point = CGPoint(x: size.width * Double(index) / Double(samples.count - 1), y: size.height * (1 - value))
                    if index == 0 { trace.move(to: point) } else { trace.addLine(to: point) }
                }
                canvas.stroke(trace, with: .color(theme.primary.color), lineWidth: 2)
            }
            HStack { Text("0.00"); Spacer(); Text("0.50"); Spacer(); Text("1.00") }
                .lcarsDisplay(18, relativeTo: .caption).foregroundStyle(theme.secondary.color)
        }.accessibilityElement(children: .ignore).accessibilityLabel(label).accessibilityValue(summary)
    }
}
