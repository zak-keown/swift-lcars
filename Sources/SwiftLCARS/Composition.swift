import SwiftUI

public struct LCARSSection<Content: View>: View {
    private let title: String
    private let content: Content
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.layoutDirection) private var direction
    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title).textCase(.uppercase).lcarsDisplay(28, relativeTo: .title3)
                .foregroundStyle(theme.secondary.ink.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(LCARSSegment(.trailing, layoutDirection: direction).fill(theme.secondary.color))
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

/// An adaptive frame; content controls its own scrolling. The sidebar is reflowed,
/// never scaled, and receives `lcarsIsCompact` through the environment.
public struct LCARSConsole<Content: View, Sidebar: View>: View {
    private let title: String
    private let content: Content
    private let sidebar: Sidebar
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsAlert) private var alert
    @Environment(\.layoutDirection) private var direction
    @Environment(\.dynamicTypeSize) private var typeSize

    public init(title: String, @ViewBuilder content: () -> Content, @ViewBuilder sidebar: () -> Sidebar) {
        self.title = title; self.content = content(); self.sidebar = sidebar()
    }

    public var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 760 || typeSize.isAccessibilitySize
            VStack(spacing: 6) {
                header(compact: compact)
                HStack(alignment: .top, spacing: compact ? 0 : 26) {
                    if !compact {
                        VStack(spacing: 6) {
                            sidebar
                            Rectangle().fill(theme.tertiary.color).frame(maxHeight: .infinity)
                                .accessibilityHidden(true)
                        }.frame(width: 144)
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        if compact { sidebar }
                        content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                footer(compact: compact)
            }
            .padding(compact ? 16 : 24)
            .environment(\.lcarsIsCompact, compact)
            .foregroundStyle(theme.text.color)
            .background(theme.background.color)
        }
    }

    private var frameColor: Color { alert == .normal ? theme.primary.color : alert.tint(in: theme).color }

    @ViewBuilder private func header(compact: Bool) -> some View {
        if compact {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 6) {
                    LCARSElbow(metrics: .compact, layoutDirection: direction)
                        .fill(frameColor).frame(width: 76, height: 48)
                    Rectangle().fill(theme.secondary.color).frame(height: 12)
                    LCARSSegment(.trailing, layoutDirection: direction).fill(theme.tertiary.color)
                        .frame(width: 70, height: 12)
                }.accessibilityHidden(true)
                Text(title).textCase(.uppercase).lcarsDisplay(44, relativeTo: .largeTitle)
                    .foregroundStyle(theme.primary.color).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
        } else {
            HStack(alignment: .top, spacing: 6) {
                LCARSElbow(layoutDirection: direction).fill(frameColor).frame(width: 192, height: 104)
                    .accessibilityHidden(true)
                Rectangle().fill(theme.tertiary.color).frame(width: 90, height: 36).accessibilityHidden(true)
                Rectangle().fill(theme.secondary.color).frame(maxWidth: .infinity).frame(height: 36)
                    .accessibilityHidden(true)
                Text(title).textCase(.uppercase).lcarsDisplay(52, relativeTo: .largeTitle)
                    .foregroundStyle(theme.primary.color).padding(.leading, 16)
                    .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
            }
        }
    }

    private func footer(compact: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            LCARSElbow(.bottomLeading, metrics: compact ? .compact : .reference, layoutDirection: direction)
                .fill(frameColor).frame(width: compact ? 76 : 192, height: compact ? 32 : 88)
            Rectangle().fill(theme.secondary.color).frame(width: compact ? 44 : 90, height: compact ? 12 : 36)
            LCARSSegment(.trailing, layoutDirection: direction).fill(theme.tertiary.color)
                .frame(height: compact ? 12 : 36)
        }.accessibilityHidden(true)
    }
}

public extension LCARSConsole where Sidebar == EmptyView {
    init(title: String, @ViewBuilder content: () -> Content) {
        self.init(title: title, content: content, sidebar: { EmptyView() })
    }
}
