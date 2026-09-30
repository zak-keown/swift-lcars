import SwiftUI
import SwiftLCARS

enum CatalogPage: String, CaseIterable, Identifiable {
    case archive = "Archive", observatory = "Observatory", components = "Components", motion = "Motion"
    var id: Self { self }
}

struct CatalogView: View {
    @AppStorage("lcars.theme") private var themeID = "classic"
    @AppStorage("lcars.motion") private var motion = true
    @AppStorage("lcars.readable") private var readable = false
    @State private var page: CatalogPage = .archive
    @State private var alert: LCARSAlert = .normal
    @State private var showThemes = false
    @State private var scanning = false
    #if os(iOS)
    @StateObject private var liveActivity = LiveActivityController()
    #endif
    private var theme: LCARSTheme { LCARSTheme.presets.first { $0.id == themeID } ?? .classic }

    var body: some View {
        Group {
            #if LCARS_DUO_SDK && os(iOS)
            if #available(iOS 27.1, *) {
                NavigationStack {
                    catalogContent
                        .toolbar {
                            ToolbarItem(placement:.topBarLeading) {
                                Menu {
                                    Picker("Section",selection:$page) {
                                        ForEach(CatalogPage.allCases) { Text($0.rawValue).tag($0) }
                                    }
                                } label: { Label("Catalog",systemImage:"line.3.horizontal") }
                            }
                            ToolbarItem(placement:.topBarTrailing) {
                                Menu {
                                    Picker("Franchise",selection:$themeID) {
                                        ForEach(LCARSTheme.presets) { Text($0.name).tag($0.id) }
                                    }
                                } label: { Label("Franchise",systemImage:"paintpalette") }
                            }
                            ToolbarItem(placement:.bottomBar) {
                                Button { motion.toggle() } label: {
                                    Label(motion ? "Pause ambient motion" : "Enable ambient motion",systemImage:motion ? "pause.circle" : "play.circle")
                                }
                            }
                            ToolbarItem(placement:.bottomBar) {
                                Button {
                                    if liveActivity.isRunning { liveActivity.stop() } else { liveActivity.start(theme:theme) }
                                } label: {
                                    Label(liveActivity.isRunning ? "End Live Activity" : "Start Live Activity",systemImage:liveActivity.isRunning ? "stop.circle" : "capsule.inset.filled")
                                }.disabled(liveActivity.isStopping)
                            }
                        }
                        .sheet(isPresented:$showThemes) {
                            NavigationStack {
                                List(LCARSTheme.presets) { option in
                                    Button(option.name) { themeID = option.id; showThemes = false }
                                }.navigationTitle("Change franchise")
                            }
                        }
                        .toolbarBackground(.hidden,for:.navigationBar)
                }.tint(theme.primary.color)
            } else { legacyContent }
            #else
            legacyContent
            #endif
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

    private var legacyContent: some View {
        VStack(spacing:0) { toolbar; catalogContent }
    }
    private var catalogContent: some View {
            LCARSSequence(scanning ? .scanning : .idle, animated: motion) {
                if page == .archive {
                    DialogueArchiveView()
                } else {
                    LCARSConsole(title: page == .observatory ? "Stellar cartography" : "LCARS / \(page.rawValue)") {
                        ScrollView {
                            Group {
                                switch page {
                                case .archive: EmptyView()
                                case .observatory: ObservatoryView(animated: motion, scanning: $scanning)
                                case .components: ComponentGallery(alert: $alert, readable: $readable)
                                case .motion: MotionGallery(animated: $motion)
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 8)
                        }
                    } sidebar: {
                        CatalogNavigation(selection: $page, animated: motion)
                    }
                }
            }
    }

    private var toolbar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                Menu("Catalog") {
                    Picker("Section", selection: $page) {
                        ForEach(CatalogPage.allCases) { Text($0.rawValue).tag($0) }
                    }
                }.menuStyle(.borderlessButton).fixedSize()
                LCARSStatus()
                Spacer(minLength: 8)
                franchiseButton
                Spacer(minLength: 8)
                motionButton
                #if os(iOS)
                liveActivityButton
                #endif
            }
            HStack(spacing: 8) {
                Menu {
                    Picker("Section", selection: $page) {
                        ForEach(CatalogPage.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal").frame(width:44,height:44)
                }.foregroundStyle(theme.secondary.color).accessibilityLabel("Catalog")
                franchiseButton
                Spacer(minLength: 0)
                motionButton
                #if os(iOS)
                liveActivityButton
                #endif
            }
        }
        .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 0)
    }

    private var franchiseButton: some View {
        Button { showThemes.toggle() } label: {
            HStack(spacing: 10) {
                Circle().fill(theme.primary.color).frame(width: 8, height: 8)
                Text(theme.name).lcarsDisplay(24)
                Image(systemName: "chevron.down").font(.caption.bold())
            }
            .padding(.horizontal, 16).frame(minHeight: 44)
            
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
            Menu {
                Picker("Section", selection: $selection) {
                    ForEach(CatalogPage.allCases) { Text($0.rawValue).tag($0) }
                }
            } label: {
                HStack {
                    Text("CATALOG / " + selection.rawValue.uppercased()).lcarsDisplay(20)
                    Spacer()
                    Image(systemName: "chevron.down").font(.caption.bold())
                }.frame(minHeight: 44)
                    .foregroundStyle(theme.secondary.color)
            }.menuStyle(.borderlessButton).buttonStyle(.plain)
                .accessibilityLabel("Catalog section").accessibilityValue(selection.rawValue)
        } else {
            ForEach(CatalogPage.allCases) { item in
                LCARSNavigationButton(item.rawValue, isSelected: selection == item,
                                      minimumHeight: 52) { selection = item }
            }
            LCARSDataBank(columns: 2, rows: 4, animated: animated).padding(.vertical, 14)
            LCARSIndicatorTrack(.bottomToTop, count: 8, animated: animated).frame(height: 80)
        }
    }
}
