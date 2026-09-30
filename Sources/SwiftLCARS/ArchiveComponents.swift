import SwiftUI

/// Native editable search with LCARS rail styling and keyboard submission.
public struct LCARSSearchField: View {
    @Binding private var text: String
    private let prompt: String
    private let onSubmit: () -> Void
    @Environment(\.lcarsTheme) private var theme
    public init(_ prompt: String = "Search", text: Binding<String>, onSubmit: @escaping () -> Void = {}) {
        self.prompt = prompt; self._text = text; self.onSubmit = onSubmit
    }
    public var body: some View {
        HStack(spacing: 6) {
            TextField(prompt, text: $text)
                .textFieldStyle(.plain).lcarsDisplay(36, relativeTo: .title3)
                .foregroundStyle(theme.secondary.color)
                .padding(.horizontal, 12).frame(minHeight: 44)
                .overlay(alignment: .bottom) { Rectangle().fill(theme.secondary.color).frame(height: 3) }
                .submitLabel(.search).onSubmit(onSubmit).accessibilityLabel(prompt)
            if !text.isEmpty {
                Button { text = ""; onSubmit() } label: {
                    Image(systemName: "xmark.circle.fill").frame(width: 44, height: 44)
                }.buttonStyle(.plain).foregroundStyle(theme.secondary.color).accessibilityLabel("Clear search")
            }
            Button("Search", action: onSubmit).buttonStyle(.lcars(.primary, ends: .trailing))
        }
    }
}

/// A real native slider with stable timestamps and decorative cue marks.
public struct LCARSTimeline: View {
    @Binding private var position: Double
    private let duration: Double
    private let cuePositions: [Double]
    private let onEditingChanged: (Bool) -> Void
    @Environment(\.lcarsTheme) private var theme
    public init(position: Binding<Double>, duration: Double, cues: [Double] = [],
                onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self._position = position
        self.duration = duration.isFinite ? max(1, duration) : 1
        self.cuePositions = cues
        self.onEditingChanged = onEditingChanged
    }
    public var body: some View {
        ZStack {
            GeometryReader { proxy in
                let width = max(0, proxy.size.width - 20)
                let value = position.isFinite ? min(duration, max(0, position)) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.secondary.color).frame(height: 14)
                    ForEach(Array(cuePositions.enumerated()), id: \.offset) { _, cue in
                        if cue.isFinite && cue >= 0 && cue <= duration {
                            Rectangle().fill(theme.background.color).frame(width: 2, height: 14)
                                .offset(x: width * cue / duration)
                        }
                    }
                    Rectangle().fill(theme.primary.color).frame(width: 8, height: 28)
                        .offset(x: max(0, width * value / duration - 4))
                }.padding(.horizontal, 10).frame(height: 44)
            }.accessibilityHidden(true).allowsHitTesting(false)
            Slider(value: Binding(get: { position.isFinite ? min(duration, max(0, position)) : 0 },
                                  set: { position = $0 }), in: 0...duration,
                   onEditingChanged: onEditingChanged)
                .opacity(0.015)
                .accessibilityLabel("Transcript position")
                .accessibilityValue("\(Int(position.isFinite ? max(0, position) : 0)) of \(Int(duration)) seconds")
        }.frame(height: 44)

    }
}

/// A connected secondary frame for transcripts, records, or related content.
/// Content determines height; the spine is background geometry, never a spacer.
public struct LCARSPanel<Content: View>: View {
    private let title: String
    private let identifier: String
    private let content: Content
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsIsCompact) private var compact
    @Environment(\.layoutDirection) private var direction
    public init(_ title: String, identifier: String = "", @ViewBuilder content: () -> Content) {
        self.title = title; self.identifier = identifier; self.content = content()
    }
    private var metrics: LCARSElbowMetrics {
        compact ? .init(verticalArm: 18, horizontalArm: 8, outerRadius: 18, innerRadius: 12)
                : .init(verticalArm: 80, horizontalArm: 12, outerRadius: 48, innerRadius: 28)
    }
    public var body: some View {
        let m = metrics
        VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                LCARSElbow(metrics: m, layoutDirection: direction).fill(theme.secondary.color)
                    .frame(width: m.verticalArm + m.innerRadius, height: compact ? 30 : 50)
                    .accessibilityHidden(true)
                LCARSInstrumentHeader(title, identifier: identifier)
            }
            content.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, m.verticalArm + (compact ? 10 : 16))
                .background(alignment: .leading) {
                    Rectangle().fill(theme.tertiary.color).frame(width: m.verticalArm).accessibilityHidden(true)
                }
            HStack(alignment: .bottom, spacing: 6) {
                LCARSElbow(.bottomLeading, metrics: m, layoutDirection: direction).fill(theme.secondary.color)
                    .frame(width: m.verticalArm + m.innerRadius, height: compact ? 24 : 48)
                LCARSSegment(.trailing, layoutDirection: direction).fill(theme.tertiary.color).frame(height: m.horizontalArm)
            }.accessibilityHidden(true)
        }
    }
}
