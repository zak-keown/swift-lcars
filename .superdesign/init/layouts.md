# Adaptive console and catalog navigation

## Sources/SwiftLCARS/Composition.swift
```swift
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
                .fill(frameColor).frame(width: compact ? 76 : metrics.elbowWidth, height: compact ? 32 : metrics.footerHeight)
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

```

## Sources/LCARSCatalog/CatalogView.swift
```swift
import SwiftUI
import SwiftLCARS

enum CatalogPage: String, CaseIterable, Identifiable {
    case observatory = "Observatory", components = "Components", motion = "Motion"
    var id: Self { self }
}

struct CatalogView: View {
    @AppStorage("lcars.theme") private var themeID = "classic"
    @AppStorage("lcars.motion") private var motion = true
    @AppStorage("lcars.readable") private var readable = false
    @State private var page: CatalogPage = .observatory
    @State private var alert: LCARSAlert = .normal
    @State private var showThemes = false
    @State private var scanning = false
    #if os(iOS)
    @StateObject private var liveActivity = LiveActivityController()
    #endif
    private var theme: LCARSTheme { LCARSTheme.presets.first { $0.id == themeID } ?? .classic }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            LCARSSequence(scanning ? .scanning : .idle, animated: motion) {
                LCARSConsole(title: page == .observatory ? "Stellar cartography" : "LCARS / \(page.rawValue)") {
                    ScrollView {
                        Group {
                            switch page {
                            case .observatory: ObservatoryView(animated: motion, scanning: $scanning)
                            case .components: ComponentGallery(alert: $alert, readable: $readable)
                            case .motion: MotionGallery(animated: $motion)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    }
                } sidebar: {
                    CatalogNavigation(selection: $page, animated: motion)
                }
            }
        }
        .background(theme.background.color)
        .lcarsTheme(theme).lcarsAlert(alert)
        .lcarsFontMode(readable ? .readable : .authentic)
        .lcarsMotionEnabled(motion)
        .onOpenURL { url in
            if url.scheme == "swiftlcars", url.host == "themes" { showThemes = true }
        }
        #if os(iOS)
        .onChange(of: themeID) { _, _ in liveActivity.update(theme: theme) }
        .alert("Live Activity", isPresented: Binding(get: { liveActivity.error != nil }, set: { if !$0 { liveActivity.error = nil } })) {
            Button("OK") { liveActivity.error = nil }
        } message: { Text(liveActivity.error ?? "") }
        #endif
    }

    private var toolbar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                LCARSStatus()
                Spacer(minLength: 8)
                franchiseButton
                Spacer(minLength: 8)
                motionButton
                #if os(iOS)
                liveActivityButton
                #endif
            }
            HStack(spacing: 12) {
                franchiseButton
                Spacer(minLength: 0)
                motionButton
                #if os(iOS)
                liveActivityButton
                #endif
            }
        }
        .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 2)
    }

    private var franchiseButton: some View {
        Button { showThemes.toggle() } label: {
            HStack(spacing: 10) {
                Circle().fill(theme.primary.color).frame(width: 8, height: 8)
                Text(theme.name).lcarsDisplay(24)
                Image(systemName: "chevron.down").font(.caption.bold())
            }
            .padding(.horizontal, 16).frame(minHeight: 44)
            .background(.black, in: Capsule())
            .overlay(Capsule().stroke(theme.secondary.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.primary.color)
        .accessibilityLabel("Change franchise")
        .accessibilityValue(theme.name)
        .popover(isPresented: $showThemes, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Change franchise").font(.title2.bold()).padding(.bottom, 6)
                ForEach(LCARSTheme.presets) { option in
                    Button {
                        themeID = option.id
                        showThemes = false
                    } label: {
                        HStack(spacing: 10) {
                            HStack(spacing: 3) {
                                ForEach(Array([option.primary, option.secondary, option.tertiary].enumerated()), id: \.offset) { _, color in
                                    Rectangle().fill(color.color).frame(width: 16, height: 22)
                                }
                            }.accessibilityHidden(true)
                            Text(option.name).font(.body)
                            Spacer(minLength: 8)
                            if option.id == themeID { Image(systemName: "checkmark") }
                        }.frame(minHeight: 38).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
            .padding(22).frame(minWidth: 290)
            .presentationCompactAdaptation(.popover)
            .preferredColorScheme(.dark)
        }
    }

    private var motionButton: some View {
        Button { motion.toggle() } label: {
            Image(systemName: motion ? "pause.circle" : "play.circle").font(.title2)
                .frame(width: 44, height: 44)
        }.buttonStyle(.plain).foregroundStyle(theme.secondary.color)
            .accessibilityLabel(motion ? "Pause ambient motion" : "Enable ambient motion")
            .help(motion ? "Pause ambient motion" : "Enable ambient motion")
    }

    #if os(iOS)
    private var liveActivityButton: some View {
        Button {
            if liveActivity.isRunning { liveActivity.stop() } else { liveActivity.start(theme: theme) }
        } label: {
            Image(systemName: liveActivity.isRunning ? "stop.circle" : "capsule.inset.filled")
                .font(.title2).frame(width: 44, height: 44)
        }.buttonStyle(.plain).foregroundStyle(theme.secondary.color)
            .accessibilityLabel(liveActivity.isRunning ? "End Live Activity" : "Start Live Activity")
            .disabled(liveActivity.isStopping)
    }
    #endif
}

struct CatalogNavigation: View {
    @Binding var selection: CatalogPage
    let animated: Bool
    @Environment(\.lcarsIsCompact) private var compact
    @Environment(\.lcarsTheme) private var theme
    var body: some View {
        if compact {
            Picker("Section", selection: $selection) {
                ForEach(CatalogPage.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
        } else {
            ForEach(CatalogPage.allCases) { item in
                LCARSNavigationButton(item.rawValue, isSelected: selection == item,
                                      minimumHeight: item == .observatory ? 100 : 58) { selection = item }
            }
            LCARSDataBank(columns: 2, rows: 4, animated: animated).padding(.vertical, 14)
            LCARSIndicatorTrack(.bottomToTop, count: 8, animated: animated).frame(height: 80)
        }
    }
}

```