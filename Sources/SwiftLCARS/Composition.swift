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
    private let metrics: LCARSFrameMetrics
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsAlert) private var alert
    @Environment(\.layoutDirection) private var direction
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.lcarsFontMode) private var fontMode
    @ScaledMetric(relativeTo: .largeTitle) private var titleScale: CGFloat = 1

    public init(title: String, metrics: LCARSFrameMetrics = .console, @ViewBuilder content: () -> Content, @ViewBuilder sidebar: () -> Sidebar) {
        self.title = title; self.metrics = metrics; self.content = content(); self.sidebar = sidebar()
    }

    public var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 760 || typeSize.isAccessibilitySize
            VStack(spacing: compact ? LCARSFrameMetrics.padd.gutter : metrics.gutter) {
                header(compact: compact)
                HStack(alignment: .top, spacing: compact ? 0 : metrics.contentInset) {
                    if !compact {
                        VStack(spacing: metrics.gutter) {
                            sidebar
                            Rectangle().fill(theme.tertiary.color).frame(maxHeight: .infinity)
                                .accessibilityHidden(true)
                        }.frame(width: metrics.elbow.verticalArm)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        if compact { sidebar }
                        content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                footer(compact: compact)
            }
            .padding(.horizontal, compact ? 12 : 20)
            .padding(.top, compact ? 8 : 12)
            .padding(.bottom, compact ? 8 : 16)
            .environment(\.lcarsIsCompact, compact)
            .foregroundStyle(theme.text.color)
            .background(theme.background.color)
        }
    }

    private var frameColor: Color { alert == .normal ? theme.primary.color : alert.tint(in: theme).color }

    @ViewBuilder private func header(compact: Bool) -> some View {
        if compact {
            HStack(alignment: .top, spacing: 8) {
                LCARSElbow(metrics: .init(verticalArm: 28, horizontalArm: 8, outerRadius: 24, innerRadius: 16), layoutDirection: direction)
                    .fill(frameColor).frame(width: 44, height: 44).accessibilityHidden(true)
                Text(title).textCase(.uppercase).lcarsDisplay(36, relativeTo: .largeTitle)
                    .foregroundStyle(theme.primary.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
        } else {
            HStack(alignment: .top, spacing: metrics.gutter) {
                LCARSElbow(metrics: metrics.elbow, layoutDirection: direction).fill(frameColor)
                    .frame(width: metrics.elbowWidth, height: metrics.headerHeight)
                    .accessibilityHidden(true)
                Rectangle().fill(theme.tertiary.color).frame(width: 90, height: metrics.elbow.horizontalArm).accessibilityHidden(true)
                Rectangle().fill(theme.secondary.color).frame(maxWidth: .infinity).frame(height: metrics.elbow.horizontalArm)
                    .accessibilityHidden(true)
                Text(title).textCase(.uppercase)
                    .lcarsDisplay(LCARSTypography.size(forCapHeight: metrics.elbow.horizontalArm), relativeTo: .largeTitle)
                    .alignmentGuide(.top) { dimensions in
                        if fontMode == .authentic && LCARSTypography.isDisplayFontAvailable {
                            // Align visible capitals, not the font's ascender box.
                            return dimensions[.firstTextBaseline] - metrics.elbow.horizontalArm * titleScale
                        }
                        return (dimensions.height - metrics.elbow.horizontalArm) / 2
                    }
                    .foregroundStyle(theme.primary.color).padding(.leading, 16)
                    .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
            }
        }
    }

    private func footer(compact: Bool) -> some View {
        HStack(alignment: .bottom, spacing: compact ? LCARSFrameMetrics.padd.gutter : metrics.gutter) {
            LCARSElbow(.bottomLeading, metrics: compact ? LCARSFrameMetrics.padd.elbow : metrics.elbow, layoutDirection: direction)
                .fill(frameColor).frame(width: compact ? 52 : metrics.elbowWidth, height: compact ? 20 : metrics.footerHeight)
            Rectangle().fill(theme.secondary.color).frame(width: compact ? 44 : 90, height: compact ? 12 : metrics.elbow.horizontalArm)
            LCARSSegment(.trailing, layoutDirection: direction).fill(theme.tertiary.color)
                .frame(height: compact ? 12 : metrics.elbow.horizontalArm)
        }.accessibilityHidden(true)
    }
}

public extension LCARSConsole where Sidebar == EmptyView {
    init(title: String, metrics: LCARSFrameMetrics = .console, @ViewBuilder content: () -> Content) {
        self.init(title: title, metrics: metrics, content: content, sidebar: { EmptyView() })
    }
}

/// A title interrupting a segmented rail. Text determines the height, including
/// in readable font mode; the decorative rule never constrains the label.
public struct LCARSInstrumentHeader: View {
    public var title: String
    public var identifier: String
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.layoutDirection) private var direction
    @Environment(\.dynamicTypeSize) private var typeSize
    public init(_ title: String, identifier: String = "") {
        self.title = title; self.identifier = identifier
    }
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title).textCase(.uppercase).lcarsDisplay(28, relativeTo: .headline)
                .foregroundStyle(theme.primary.color).fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            LCARSSegment(.trailing, layoutDirection: direction).fill(theme.secondary.color)
                .frame(minWidth: 12, maxWidth: .infinity).frame(height: 10)
                .accessibilityHidden(true)
            if !identifier.isEmpty && !typeSize.isAccessibilitySize {
                Text(identifier).lcarsDisplay(22, relativeTo: .caption)
                    .foregroundStyle(theme.secondary.color).accessibilityHidden(true)
            }
        }.accessibilityAddTraits(.isHeader)
    }
}

/// A continuous console frame whose content begins inside the elbow's opening.
/// Unlike a stacked header, the elbow and sidebar do not reserve a blank content row.
public struct LCARSWorkspace<Content: View, Sidebar: View>: View {
    private let title: String
    private let content: Content
    private let sidebar: Sidebar
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.layoutDirection) private var direction
    public init(_ title: String, @ViewBuilder content: () -> Content, @ViewBuilder sidebar: () -> Sidebar) {
        self.title = title; self.content = content(); self.sidebar = sidebar()
    }
    public var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 900 || typeSize.isAccessibilitySize
            let arm: CGFloat = compact ? 22 : 132
            let radius: CGFloat = compact ? 22 : 44
            let rail: CGFloat = compact ? 10 : 28
            let elbow = LCARSElbowMetrics(verticalArm: arm, horizontalArm: rail,
                                          outerRadius: compact ? 32 : 76, innerRadius: radius)
            let cap: CGFloat = compact ? 54 : 112
            HStack(alignment: .top, spacing: compact ? 10 : 20) {
                VStack(spacing: 5) {
                    Color.clear.frame(height: cap)
                    if !compact { sidebar }
                    Rectangle().fill(theme.tertiary.color)
                    Color.clear.frame(height: cap)
                }.frame(width: arm).accessibilityHidden(compact)
                VStack(alignment: .leading, spacing: compact ? 8 : 14) {
                    HStack(alignment: .top, spacing: 12) {
                        LCARSSegment(.trailing, layoutDirection: direction).fill(theme.secondary.color)
                            .frame(minWidth: 12, maxWidth: .infinity).frame(height: compact ? 10 : rail)
                            .padding(.leading, compact ? 12 : 30)
                            .accessibilityHidden(true)
                        Text(title).textCase(.uppercase).lcarsDisplay(LCARSTypography.size(forCapHeight: compact ? 22 : 28))
                            .alignmentGuide(.top) { $0[.firstTextBaseline] - (compact ? 22 : 28) }
                            .foregroundStyle(theme.primary.color).fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                    }.frame(minHeight: compact ? 40 : 48)
                    if compact { sidebar }
                    content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    HStack(spacing: 6) {
                        Rectangle().fill(theme.secondary.color).frame(width: compact ? 36 : 100)
                        LCARSSegment(.trailing, layoutDirection: direction).fill(theme.tertiary.color)
                    }.frame(height: rail).accessibilityHidden(true)
                }
            }
            .background(alignment: .topLeading) {
                LCARSElbow(metrics: elbow, layoutDirection: direction).fill(theme.primary.color)
                    .frame(width: arm + radius, height: cap).accessibilityHidden(true)
            }
            .background(alignment: .bottomLeading) {
                LCARSElbow(.bottomLeading, metrics: elbow, layoutDirection: direction).fill(theme.primary.color)
                    .frame(width: arm + radius, height: cap).accessibilityHidden(true)
            }
            .padding(.horizontal, compact ? 12 : 24).padding(.top, 8).padding(.bottom, compact ? 12 : 20)
            .environment(\.lcarsIsCompact, compact)
            .foregroundStyle(theme.text.color)
        }
    }
}
