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
    #if os(iOS)
    @StateObject private var liveActivity = LiveActivityController()
    #endif
    private var theme: LCARSTheme { LCARSTheme.presets.first { $0.id == themeID } ?? .classic }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            LCARSConsole(title: page == .observatory ? "Stellar cartography" : "LCARS / \(page.rawValue)") {
                ScrollView {
                    Group {
                        switch page {
                        case .observatory: ObservatoryView(animated: motion)
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
            LCARSNumberGrid(columns: 2, rows: 4, animated: animated).padding(.vertical, 14)
            LCARSActivityBand(.bottomToTop, animated: animated).frame(height: 80)
        }
    }
}
