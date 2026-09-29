import SwiftUI

public enum LCARSScanDirection: String, CaseIterable, Sendable {
    case leftToRight, rightToLeft, topToBottom, bottomToTop
    var isVertical: Bool { self == .topToBottom || self == .bottomToTop }
    var isReversed: Bool { self == .rightToLeft || self == .bottomToTop }
}

public enum LCARSAnimation: Equatable, Sendable {
    case pulse
    case scan(LCARSScanDirection)
}

private struct MotionEnabledKey: EnvironmentKey { static let defaultValue = true }
public extension EnvironmentValues {
    /// A master switch. Individual widgets still opt in; nothing animates by default.
    var lcarsMotionEnabled: Bool { get { self[MotionEnabledKey.self] } set { self[MotionEnabledKey.self] = newValue } }
}

public extension View {
    /// Decorative animation never alters the underlying value, label or action.
    func lcarsAnimated(_ animation: LCARSAnimation = .pulse, enabled: Bool = true, period: TimeInterval = 3) -> some View {
        modifier(AmbientAnimation(style: animation, enabled: enabled, period: period))
    }
    func lcarsMotionEnabled(_ enabled: Bool) -> some View { environment(\.lcarsMotionEnabled, enabled) }
}

private struct AmbientAnimation: ViewModifier {
    let style: LCARSAnimation
    let enabled: Bool
    let period: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.lcarsMotionEnabled) private var masterEnabled
    @Environment(\.scenePhase) private var scenePhase
    private var active: Bool { enabled && masterEnabled && !reduceMotion && scenePhase == .active }

    func body(content: Content) -> some View {
        // Keep the content at a stable structural identity when motion is toggled.
        // Only the noninteractive overlay receives timeline updates.
        content.overlay {
            TimelineView(.animation(minimumInterval: 1 / 20, paused: !active)) { context in
                let phase = active ? LCARSNoise.phase(at: context.date, period: period) : 0
                GeometryReader { geometry in
                    switch style {
                    case .pulse:
                        Color.white.opacity(active ? 0.10 * (1 - cos(phase * 2 * .pi)) / 2 : 0)
                    case .scan(let direction):
                        let dimension = direction.isVertical ? geometry.size.height : geometry.size.width
                        let progress = direction.isReversed ? 1 - phase : phase
                        Rectangle().fill(.white.opacity(active ? 0.24 : 0))
                            .frame(width: direction.isVertical ? geometry.size.width : max(2, dimension * 0.12),
                                   height: direction.isVertical ? max(2, dimension * 0.12) : geometry.size.height)
                            .offset(x: direction.isVertical ? 0 : (dimension * 1.12 * progress - dimension * 0.12),
                                    y: direction.isVertical ? (dimension * 1.12 * progress - dimension * 0.12) : 0)
                    }
                }
            }
            .mask(content)
            .allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

enum LCARSNoise {
    static func phase(at date: Date, period: TimeInterval) -> Double {
        let duration = period.isFinite ? max(0.2, period) : 3
        let time = date.timeIntervalSinceReferenceDate
        return ((time.truncatingRemainder(dividingBy: duration) / duration) + 1).truncatingRemainder(dividingBy: 1)
    }
    static func value(seed: UInt64, index: Int, tick: UInt64) -> UInt64 {
        var x = seed &+ UInt64(max(0, index)) &* 0x9E3779B97F4A7C15 &+ tick &* 0xBF58476D1CE4E5B9
        x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9
        x = (x ^ (x >> 27)) &* 0x94D049BB133111EB
        return (x ^ (x >> 31)) % 9000 + 1000
    }
}

/// Synthetic decorative digits. Intentionally absent from the accessibility tree.
/// Never use this widget to represent genuine measurements.
public struct LCARSNumberGrid: View {
    public var columns: Int
    public var rows: Int
    public var seed: UInt64
    public var animated: Bool
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsMotionEnabled) private var masterEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    public init(columns: Int = 6, rows: Int = 3, seed: UInt64 = 1701, animated: Bool = false) {
        self.columns = columns; self.rows = rows; self.seed = seed; self.animated = animated
    }
    public var body: some View {
        let active = animated && masterEnabled && !reduceMotion && scenePhase == .active
        let cols = min(24, max(1, columns)), rows = min(12, max(1, rows))
        TimelineView(.animation(minimumInterval: 0.8, paused: !active)) { context in
            let tick = active ? UInt64(max(0, context.date.timeIntervalSinceReferenceDate / 0.8)) : 0
            Canvas { canvas, size in
                let cellWidth = size.width / CGFloat(cols), cellHeight = size.height / CGFloat(rows)
                for row in 0..<rows {
                    for col in 0..<cols {
                        let index = row * cols + col
                        let digits = String(LCARSNoise.value(seed: seed, index: index, tick: tick))
                        let color = index % 3 == 0 ? theme.primary : (index % 3 == 1 ? theme.secondary : theme.tertiary)
                        let text = Text(digits).font(LCARSTypography.display(min(26, max(10, cellWidth * 0.48))))
                            .foregroundColor(color.color)
                        canvas.draw(text, at: CGPoint(x: cellWidth * (CGFloat(col) + 0.5), y: cellHeight * (CGFloat(row) + 0.5)))
                    }
                }
            }
        }
        .frame(height: CGFloat(rows) * 30).accessibilityHidden(true).allowsHitTesting(false)
    }
}

/// A looping row or column of blocks. Separate from meters that represent real values.
public struct LCARSActivityBand: View {
    public var direction: LCARSScanDirection
    public var animated: Bool
    public var period: TimeInterval
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsMotionEnabled) private var masterEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    public init(_ direction: LCARSScanDirection = .leftToRight, animated: Bool = false, period: TimeInterval = 3) {
        self.direction = direction; self.animated = animated; self.period = period
    }
    public var body: some View {
        let active = animated && masterEnabled && !reduceMotion && scenePhase == .active
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !active)) { context in
            let phase = active ? LCARSNoise.phase(at: context.date, period: period) : 0
            Canvas { canvas, size in
                let length = direction.isVertical ? size.height : size.width
                guard length > 0 else { return }
                let stride = max(12, length / 12)
                let offset = CGFloat(direction.isReversed ? -phase : phase) * stride * 4
                for index in -5...17 {
                    let position = CGFloat(index) * stride + offset
                    let rect = direction.isVertical
                        ? CGRect(x: 0, y: position, width: size.width, height: stride - 4)
                        : CGRect(x: position, y: 0, width: stride - 4, height: size.height)
                    let color = index.isMultiple(of: 4) ? theme.primary : theme.secondary
                    canvas.fill(Path(rect), with: .color(color.color.opacity(index.isMultiple(of: 4) ? 1 : 0.4)))
                }
            }
        }.clipped().accessibilityHidden(true).allowsHitTesting(false)
    }
}
