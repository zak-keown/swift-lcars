# Native SwiftUI primitives

## Sources/SwiftLCARS/Controls.swift
```swift
import SwiftUI

public enum LCARSControlRole: Sendable {
    case primary, secondary, accent, destructive
    public func fill(in theme: LCARSTheme) -> LCARSColor {
        switch self { case .primary: theme.primary; case .secondary: theme.secondary; case .accent: theme.accent; case .destructive: theme.critical }
    }
}

public struct LCARSButtonStyle: ButtonStyle {
    public var role: LCARSControlRole
    public var ends: LCARSSegment.Ends
    public var horizontalPadding: CGFloat
    public init(_ role: LCARSControlRole = .primary, ends: LCARSSegment.Ends = .both, horizontalPadding: CGFloat = 22) {
        self.role = role; self.ends = ends; self.horizontalPadding = horizontalPadding
    }
    public func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration, role: role, ends: ends, horizontalPadding: horizontalPadding)
    }

    private struct StyledButton: View {
        let configuration: Configuration
        let role: LCARSControlRole
        let ends: LCARSSegment.Ends
        let horizontalPadding: CGFloat
        @Environment(\.lcarsTheme) var theme
        @Environment(\.isEnabled) var enabled
        @Environment(\.isFocused) var focused
        @Environment(\.layoutDirection) var direction
        @Environment(\.accessibilityReduceMotion) var reduceMotion
        @State private var hovered = false
        var body: some View {
            let fill = role.fill(in: theme)
            let shape = LCARSSegment(ends, layoutDirection: direction)
            configuration.label
                .lcarsDisplay(27)
                .labelStyle(LCARSLabelStyle())
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
                .padding(.horizontal, horizontalPadding).padding(.vertical, 9)
                .frame(minWidth: 44, minHeight: 44)
                .foregroundStyle(fill.ink.color)
                .background(fill.color, in: shape)
                .overlay { shape.strokeBorderCompat(focused ? theme.text.color : .clear, width: 3) }
                .overlay { shape.fill(Color.black.opacity(configuration.isPressed ? 0.16 : 0)).allowsHitTesting(false) }
                .overlay { if hovered && enabled { shape.stroke(theme.text.color, lineWidth: 2).allowsHitTesting(false) } }
                .opacity(enabled ? 1 : 0.5)
                .contentShape(shape)
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

private extension Shape {
    func strokeBorderCompat(_ color: Color, width: CGFloat) -> some View {
        stroke(color, lineWidth: width).padding(-3).allowsHitTesting(false)
    }
}

public extension ButtonStyle where Self == LCARSButtonStyle {
    static func lcars(_ role: LCARSControlRole = .primary, ends: LCARSSegment.Ends = .both) -> Self {
        Self(role, ends: ends)
    }
}

/// Keeps the native button action and exposes selection independently of its color.
public struct LCARSNavigationButton: View {
    public let title: String
    public let isSelected: Bool
    public let minimumHeight: CGFloat
    public let action: () -> Void
    @Environment(\.lcarsTheme) private var theme
    public init(_ title: String, isSelected: Bool, minimumHeight: CGFloat = 58, action: @escaping () -> Void) {
        self.title = title; self.isSelected = isSelected; self.minimumHeight = minimumHeight; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if isSelected { Image(systemName: "chevron.right").font(.caption.bold()).accessibilityHidden(true) }
                Spacer(minLength: 0)
                Text(title).lcarsDisplay(24)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(minHeight: max(26, minimumHeight - 18))
        }
        .buttonStyle(LCARSButtonStyle(isSelected ? .primary : .secondary, ends: .square, horizontalPadding: 12))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public struct LCARSToggleStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 12) {
                configuration.label
                Spacer(minLength: 12)
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                Text(configuration.isOn ? "On" : "Off")
            }
        }
        .buttonStyle(.lcars(configuration.isOn ? .primary : .secondary, ends: .square))
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }.toggleStyle(.switch)
        }
    }
}

public extension ToggleStyle where Self == LCARSToggleStyle {
    static var lcars: Self { Self() }
}

public struct LCARSStatus: View {
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsAlert) private var alert
    public init() {}
    public var body: some View {
        Label(alert.label, systemImage: alert.symbol)
            .font(.callout.weight(.medium))
            .foregroundStyle(alert.tint(in: theme).color)
            .accessibilityElement(children: .combine)
    }
}

/// Symbols use their own point size instead of inheriting the unusually tall
/// display font. Native Label titles keep the enclosing button's typography.
public struct LCARSLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .headline) private var symbolSize: CGFloat = 16
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 10) {
            configuration.icon.font(.system(size: symbolSize, weight: .medium))
                .accessibilityHidden(true)
            configuration.title
        }
    }
}

```

## Sources/SwiftLCARS/DataDisplays.swift
```swift
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

```

## Sources/SwiftLCARS/Geometry.swift
```swift
import SwiftUI

/// Independent arm widths and circular radii, matching the approved form study.
public struct LCARSElbowMetrics: Equatable, Sendable {
    public var verticalArm: CGFloat
    public var horizontalArm: CGFloat
    public var outerRadius: CGFloat
    public var innerRadius: CGFloat
    public init(verticalArm: CGFloat = 144, horizontalArm: CGFloat = 36,
                outerRadius: CGFloat = 72, innerRadius: CGFloat = 48) {
        self.verticalArm = verticalArm; self.horizontalArm = horizontalArm
        self.outerRadius = outerRadius; self.innerRadius = innerRadius
    }
    public static let reference = Self()
    public static let compact = Self(verticalArm: 36, horizontalArm: 12, outerRadius: 28, innerRadius: 16)

    public func resolved(in size: CGSize) -> Self {
        func positive(_ n: CGFloat) -> CGFloat { n.isFinite ? max(0, n) : 0 }
        let w = positive(size.width), h = positive(size.height)
        let v = min(positive(verticalArm), w), rail = min(positive(horizontalArm), h)
        return Self(verticalArm: v, horizontalArm: rail,
                    outerRadius: min(positive(outerRadius), v, h),
                    innerRadius: min(positive(innerRadius), w - v, h - rail))
    }
}

public struct LCARSElbow: Shape {
    public enum Corner: CaseIterable, Sendable { case topLeading, topTrailing, bottomLeading, bottomTrailing }
    public var corner: Corner
    public var metrics: LCARSElbowMetrics
    public var layoutDirection: LayoutDirection
    public init(_ corner: Corner = .topLeading, metrics: LCARSElbowMetrics = .reference,
                layoutDirection: LayoutDirection = .leftToRight) {
        self.corner = corner; self.metrics = metrics; self.layoutDirection = layoutDirection
    }

    public func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0, rect.width.isFinite, rect.height.isFinite else { return Path() }
        let m = metrics.resolved(in: rect.size)
        let v = m.verticalArm, h = m.horizontalArm, outer = m.outerRadius, inner = m.innerRadius
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: outer))
        if outer > 0 {
            p.addArc(center: CGPoint(x: outer, y: outer), radius: outer,
                     startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: h))
        p.addLine(to: CGPoint(x: v + inner, y: h))
        if inner > 0 {
            p.addArc(center: CGPoint(x: v + inner, y: h + inner), radius: inner,
                     startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
        }
        p.addLine(to: CGPoint(x: v, y: rect.height))
        p.closeSubpath()
        let trailing = corner == .topTrailing || corner == .bottomTrailing
        let flipX = trailing != (layoutDirection == .rightToLeft)
        let flipY = corner == .bottomLeading || corner == .bottomTrailing
        return p.applying(CGAffineTransform(a: flipX ? -1 : 1, b: 0, c: 0, d: flipY ? -1 : 1,
                                           tx: flipX ? rect.maxX : rect.minX, ty: flipY ? rect.maxY : rect.minY))
    }
}

public struct LCARSSegment: Shape {
    public enum Ends: Sendable { case square, leading, trailing, both }
    public var ends: Ends
    public var layoutDirection: LayoutDirection
    public init(_ ends: Ends = .square, layoutDirection: LayoutDirection = .leftToRight) {
        self.ends = ends; self.layoutDirection = layoutDirection
    }
    public func path(in rect: CGRect) -> Path {
        let radius = max(0, min(rect.width, rect.height) / 2)
        let leading: CGFloat = ends == .leading || ends == .both ? radius : 0
        let trailing: CGFloat = ends == .trailing || ends == .both ? radius : 0
        let left = layoutDirection == .leftToRight ? leading : trailing
        let right = layoutDirection == .leftToRight ? trailing : leading
        return UnevenRoundedRectangle(topLeadingRadius: left, bottomLeadingRadius: left,
                                      bottomTrailingRadius: right, topTrailingRadius: right,
                                      style: .circular).path(in: rect)
    }
}

/// Shared dimensions keep the spine, elbow, rail and content edge aligned.
/// Values derive from the project's approved TNG study, not a studio style sheet.
public struct LCARSFrameMetrics: Equatable, Sendable {
    public var elbow: LCARSElbowMetrics
    public var gutter: CGFloat
    public var contentInset: CGFloat
    public init(elbow: LCARSElbowMetrics = .reference, gutter: CGFloat = 6, contentInset: CGFloat = 26) {
        self.elbow = elbow
        self.gutter = gutter.isFinite ? max(0, gutter) : 6
        self.contentInset = contentInset.isFinite ? max(0, contentInset) : 26
    }
    public static let console = Self()
    public static let padd = Self(elbow: .compact, gutter: 4, contentInset: 12)
    public var elbowWidth: CGFloat { elbow.verticalArm + elbow.innerRadius }
    public var headerHeight: CGFloat { max(elbow.outerRadius, elbow.horizontalArm + elbow.innerRadius) + 20 }
    public var footerHeight: CGFloat { max(elbow.outerRadius, elbow.horizontalArm + elbow.innerRadius) }
}

```

## Sources/SwiftLCARS/Sequence.swift
```swift
import SwiftUI

/// Authored animation choreography, not a reproduction of production timing.
public enum LCARSSequenceMode: String, CaseIterable, Sendable {
    case idle, scanning, processing, alert
}

public struct LCARSSequenceFrame: Equatable, Sendable {
    public var tick: Int
    public var mode: LCARSSequenceMode
    public init(tick: Int = 0, mode: LCARSSequenceMode = .idle) {
        self.tick = max(0, tick); self.mode = mode
    }

    /// Related cells refresh in staggered banks, with a quiet interval between passes.
    public func generation(forBank bank: Int) -> UInt64 {
        let interval: Int
        switch mode {
        case .idle: interval = 24
        case .scanning: interval = 8
        case .processing: interval = 12
        case .alert: interval = 16
        }
        return UInt64(max(0, tick - abs(bank % 8)) / interval)
    }

    public func activeSegment(count: Int) -> Int {
        let count = max(1, min(64, count))
        let step = tick / (mode == .idle ? 3 : 1)
        let cycle = count * 2 + 8
        let position = step % cycle
        if position < count { return position }
        if position < count + 4 { return count - 1 }
        if position < count * 2 + 4 { return count * 2 + 3 - position }
        return 0
    }
}

private struct SequenceFrameKey: EnvironmentKey { static let defaultValue = LCARSSequenceFrame() }
public extension EnvironmentValues {
    var lcarsSequence: LCARSSequenceFrame {
        get { self[SequenceFrameKey.self] }
        set { self[SequenceFrameKey.self] = newValue }
    }
}

/// One clock for a whole console. Pausing preserves its position; offscreen and
/// Reduce Motion pause it too. Ordinary app data never depends on this clock.
public struct LCARSSequence<Content: View>: View {
    public let mode: LCARSSequenceMode
    public let animated: Bool
    private let content: Content
    @Environment(\.lcarsMotionEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    @State private var resumedAt = Date()
    @State private var accumulated: TimeInterval = 0
    private var active: Bool { animated && enabled && !reduceMotion && visible && scenePhase == .active }

    public init(_ mode: LCARSSequenceMode = .idle, animated: Bool = false,
                @ViewBuilder content: () -> Content) {
        self.mode = mode; self.animated = animated; self.content = content()
    }
    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: !active)) { context in
            let elapsed = accumulated + (active ? max(0, context.date.timeIntervalSince(resumedAt)) : 0)
            content.environment(\.lcarsSequence, LCARSSequenceFrame(tick: Int(elapsed * 4), mode: mode))
        }
        .onAppear { visible = true }
        .onDisappear { visible = false }
        .onChange(of: active) { _, running in
            if running { resumedAt = Date() }
            else { accumulated += max(0, Date().timeIntervalSince(resumedAt)) }
        }
    }
}

/// Synthetic activity, with row-by-row refresh and stable identity. Hidden from VoiceOver.
public struct LCARSDataBank: View {
    public var columns: Int
    public var rows: Int
    public var seed: UInt64
    public var animated: Bool
    @Environment(\.lcarsMotionEnabled) private var motionEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.lcarsSequence) private var sequence
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    public init(columns: Int = 5, rows: Int = 3, seed: UInt64 = 1701, animated: Bool = false) {
        self.columns = columns; self.rows = rows; self.seed = seed; self.animated = animated
    }
    public var body: some View {
        let count = typeSize.isAccessibilitySize ? min(3, max(1, columns)) : min(12, max(1, columns))
        Grid(horizontalSpacing: 12, verticalSpacing: 3) {
            ForEach(0..<min(12, max(1, rows)), id: \.self) { row in
                GridRow {
                    ForEach(0..<count, id: \.self) { column in
                        let value = LCARSNoise.value(seed: seed, index: row * count + column,
                                                    tick: animated && motionEnabled && !reduceMotion ? sequence.generation(forBank: row + column / 3) : 0)
                        Text(String(format: "%04llu", value))
                            .lcarsDisplay(24, relativeTo: .caption)
                            .foregroundStyle((column == 0 ? theme.primary : theme.secondary).color)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }.accessibilityHidden(true).allowsHitTesting(false)
    }
}

/// Discrete advance / hold / reverse / hold sequence, driven by LCARSSequence.
public struct LCARSIndicatorTrack: View {
    public var direction: LCARSScanDirection
    public var count: Int
    public var animated: Bool
    @Environment(\.lcarsMotionEnabled) private var motionEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.lcarsSequence) private var sequence
    @Environment(\.lcarsTheme) private var theme
    public init(_ direction: LCARSScanDirection = .leftToRight, count: Int = 12, animated: Bool = false) {
        self.direction = direction; self.count = count; self.animated = animated
    }
    public var body: some View {
        let count = min(64, max(1, count))
        let active = animated && motionEnabled && !reduceMotion ? sequence.activeSegment(count: count) : 0
        let layout = direction.isVertical ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 4))
        layout {
            ForEach(0..<count, id: \.self) { index in
                let position = direction.isReversed ? count - index - 1 : index
                Rectangle().fill((position == active ? theme.primary : theme.tertiary).color)
                    .opacity(position == active ? 1 : 0.45)
            }
        }.accessibilityHidden(true).allowsHitTesting(false)
    }
}

```