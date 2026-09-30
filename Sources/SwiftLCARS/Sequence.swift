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
