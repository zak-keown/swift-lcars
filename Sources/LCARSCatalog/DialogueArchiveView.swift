import SwiftUI
import SwiftLCARS
import UniformTypeIdentifiers
import ImageIO

struct DialogueArchiveView: View {
    @StateObject private var model = ArchiveModel()
    @State private var importing = false
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            #if os(macOS)
            GeometryReader { geometry in
                if geometry.size.width >= 900 {
                    ArchiveReferenceDesktop(model: model, importing: $importing)
                } else {
                    ArchivePhone(model:model, importing:$importing)
                }
            }
            #else
            // Keep one view identity and model while the window moves between displays.
            ArchivePhone(model:model, importing:$importing)
            #endif
        }
        .onChange(of: model.query) { _, _ in model.reconcileSearch() }
        .onChange(of: model.episodeFilter) { _, _ in model.reconcileSearch() }
        .onChange(of: model.savedOnly) { _, _ in model.reconcileSearch() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.isPlaying = false } }
        .onDisappear { model.isPlaying = false }
        .task(id: model.isPlaying) {
            guard model.isPlaying else { return }
            let start = Date(); let initial = model.position
            while !Task.isCancelled && model.isPlaying {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                guard !Task.isCancelled, let episode = model.selectedEpisode else { return }
                model.position = min(episode.duration, initial + Date().timeIntervalSince(start))
                if model.position >= episode.duration { model.isPlaying = false }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [UTType(filenameExtension: "srt") ?? .plainText, .plainText]) { result in
            switch result {
            case .success(let url): model.importSubtitles(from: url)
            case .failure(let error): model.error = error.localizedDescription
            }
        }
        .alert("Subtitle import", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
    }

}

private struct ArchiveArtwork: View {
    let name: String?
    var preservesComposition = false
    private static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        .module
        #else
        .main
        #endif
    }
    private static let images: [String: CGImage] = {
        var result: [String: CGImage] = [:]
        for name in ["archive-bridge", "archive-nebula", "archive-surface"] {
            if let url = resourceBundle.url(forResource: name, withExtension: "png"),
               let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let image = CGImageSourceCreateImageAtIndex(source, 0, nil) { result[name] = image }
        }
        return result
    }()
    var body: some View {
        GeometryReader { proxy in
            if let name, let image = Self.images[name] {
                Image(decorative: image, scale: 1).resizable()
                    .aspectRatio(contentMode: preservesComposition ? .fit : .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height).clipped()
            } else {
                Rectangle().fill(Color(white: 0.08)).overlay {
                    Image(systemName: "captions.bubble").font(.largeTitle).foregroundStyle(.secondary)
                }
            }
        }
    }
}


/// The approved desktop study, expressed in its original 1536 × 1024 grid.
/// Kept local until the composition has been reviewed in the rendered app.
private struct ArchiveReferenceDesktop: View {
    @ObservedObject var model: ArchiveModel
    @Binding var importing: Bool
    @Environment(\.lcarsTheme) private var theme
    @State private var episodes = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let s = min(proxy.size.width / 1536, proxy.size.height / 1024)
            canvas(s)
                .frame(width: 1536 * s, height: 1024 * s)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func canvas(_ s: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.black
            // The header and return share exact tangency points with the sidebar.
            LCARSElbow(metrics: .init(verticalArm: 165*s, horizontalArm: 38*s, outerRadius: 88*s, innerRadius: 52*s))
                .fill(theme.primary.color).ref(33,43,258,152,s)
            Rectangle().fill(theme.tertiary.color).ref(298,43,165,38,s)
            LCARSSegment(.trailing).fill(theme.secondary.color).ref(470,43,707,38,s)
            Text("DIALOGUE ARCHIVE").lcarsDisplay(64*s).foregroundStyle(theme.primary.color)
                .alignmentGuide(.top) { dimensions in
                    // Center the visible capitals on the rail, excluding font leading/descent.
                    dimensions[.firstTextBaseline] - LCARSTypography.capHeight(at:64*s) / 2 - 19*s
                }
                .ref(1000,43,503,38,s, alignment: .topTrailing)
            Text("01-447").lcarsDisplay(28*s).foregroundStyle(theme.primary.ink.color)
                .ref(110,142,70,40,s, alignment: .trailing)

            side("SEARCH", y:201, height:112, color:theme.secondary, s:s) { searchFocused = true }
            side("EPISODES", y:319, height:126, color:theme.primary, s:s) { episodes = true }
            side(model.savedOnly ? "ALL LINES" : "SAVED", y:451, height:88, color:theme.tertiary, s:s) { model.savedOnly.toggle() }
            ShareLink(item: model.exportText) {
                Text("EXPORT").lcarsDisplay(30*s).frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.trailing)
                    .padding(.trailing,18*s).foregroundStyle(theme.accent.ink.color).background(theme.accent.color)
            }.buttonStyle(.plain).ref(33,545,165,98,s)
            LCARSElbow(.bottomLeading, metrics:.init(verticalArm:165*s,horizontalArm:30*s,outerRadius:88*s,innerRadius:52*s))
                .fill(theme.primary.color).ref(33,649,258,137,s)
            Rectangle().fill(theme.secondary.color).ref(298,756,128,30,s)
            Rectangle().fill(theme.tertiary.color).ref(433,756,348,30,s)

            TextField("Search dialogue",text:$model.query).textFieldStyle(.plain).lcarsDisplay(64*s)
                .foregroundStyle(theme.secondary.color).focused($searchFocused)
                .onSubmit { model.reconcileSearch() }.accessibilityLabel("Search dialogue")
                .ref(250,107,1058,66,s)
            Rectangle().fill(theme.secondary.color).ref(232,176,1087,4,s)
            action("SEARCH",color:theme.primary,ends:.trailing,s:s) { model.reconcileSearch() }
                .ref(1330,122,172,58,s)
            action(model.episodes.first { $0.id == model.episodeFilter }?.title.uppercased() ?? "ALL EPISODES",
                   color:theme.secondary,ends:.leading,s:s) { episodes.toggle() }
                .ref(232,198,410,36,s)
            action(model.savedOnly ? "SAVED DIALOGUE" : "ALL DIALOGUE",color:theme.tertiary,ends:.square,s:s) { model.savedOnly.toggle() }
                .ref(649,198,432,36,s)
            action("IMPORT SUBTITLES",color:theme.secondary,ends:.trailing,s:s) { importing = true }
                .ref(1088,198,415,36,s)
            Text("\(model.results.count) RESULTS").lcarsDisplay(23*s).foregroundStyle(theme.secondary.color)
                .ref(1300,238,202,28,s,alignment:.trailing)

            ScrollView {
                LazyVStack(spacing:6*s) {
                    ForEach(model.results) { hit in result(hit,s:s) }
                    if model.results.isEmpty {
                        Text("NO MATCHES\nTry another phrase or select all episodes.")
                            .lcarsDisplay(28*s).foregroundStyle(theme.secondary.color).padding(20*s)
                    }
                }
            }.scrollIndicators(.hidden).ref(222,280,564,449,s)

            if let episode = model.selectedEpisode {
                ArchiveArtwork(name:episode.artwork).ref(802,266,700,332,s)
                    .accessibilityLabel("Generated illustration for \(episode.title)")
                VStack(alignment:.leading,spacing:2*s) {
                    Text(episode.title.uppercased()).lcarsDisplay(30*s)
                    Text("\(ArchiveModel.timecode(model.position)) / \(ArchiveModel.timecode(episode.duration))")
                        .lcarsDisplay(24*s).foregroundStyle(theme.secondary.color)
                }.foregroundStyle(theme.primary.color).ref(802,602,225,66,s)
                Rectangle().fill(theme.secondary.color).ref(1036,612,2,50,s)
                Text(model.activeCue?.text ?? "End of transcript").font(.system(size:22*s,weight:.medium,design:.default).width(.condensed))
                    .foregroundStyle(theme.secondary.color).ref(1060,607,442,60,s)
                LCARSTimeline(position:$model.position,duration:episode.duration,cues:episode.cues.map(\.start)) { editing in
                    if editing { model.isPlaying = false }
                }.ref(792,672,720,44,s)
                HStack(spacing:6*s) {
                    action("PREVIOUS",color:theme.secondary,ends:.leading,s:s) { model.moveCue(-1) }
                    action(model.isPlaying ? "PAUSE" : "PLAY",color:theme.primary,ends:.square,s:s) {
                        if model.position >= episode.duration { model.position = 0 }
                        model.isPlaying.toggle()
                    }
                    action("NEXT",color:theme.tertiary,ends:.square,s:s) { model.moveCue(1) }
                    action(model.activeCue.map { model.saved.contains($0.id) } == true ? "UNSAVE LINE" : "SAVE LINE",
                           color:theme.accent,ends:.trailing,s:s) {
                        if let cue = model.activeCue { model.toggleSaved(cue) }
                    }.disabled(model.activeCue == nil)
                }.ref(802,722,700,52,s)
                transcript(episode,s:s)
            }
        }
        .popover(isPresented:$episodes) {
            VStack(alignment:.leading,spacing:8) {
                Text("Episodes").font(.headline)
                Button("All episodes") { model.episodeFilter = "all"; episodes = false }
                ForEach(model.episodes) { episode in
                    Button(episode.title) { model.episodeFilter = episode.id; episodes = false }
                }
            }.padding(20).frame(minWidth:240)
        }
    }

    private func action(_ title:String,color:LCARSColor,ends:LCARSSegment.Ends,s:CGFloat,action:@escaping ()->Void) -> some View {
        Button(action:action) {
            Text(title).lcarsDisplay(28*s).lineLimit(1)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .foregroundStyle(color.ink.color).background(LCARSSegment(ends).fill(color.color))
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    private func side(_ title:String,y:CGFloat,height:CGFloat,color:LCARSColor,s:CGFloat,action:@escaping ()->Void) -> some View {
        Button(action:action) {
            Text(title).lcarsDisplay(30*s).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.trailing)
                .padding(.trailing,18*s).foregroundStyle(color.ink.color).background(color.color)
        }.buttonStyle(.plain).ref(33,y,165,height,s)
    }
    private func result(_ hit:ArchiveHit,s:CGFloat) -> some View {
        let selected = model.selectedEpisodeID == hit.episode.id && model.activeCue?.id == hit.cue.id
        return Button { model.select(hit) } label: {
            HStack(spacing:18*s) {
                ArchiveArtwork(name:hit.episode.artwork).frame(width:177*s,height:92*s)
                VStack(alignment:.leading,spacing:2*s) {
                    Text(hit.episode.title.uppercased()).lcarsDisplay(23*s).lineLimit(2)
                        .fixedSize(horizontal:false,vertical:true)
                    Text(hit.episode.code).lcarsDisplay(21*s)
                    Text(ArchiveModel.timecode(hit.cue.start)).lcarsDisplay(21*s)
                }.frame(width:104*s,alignment:.leading)
                Rectangle().fill(selected ? theme.primary.ink.color : theme.secondary.color).frame(width:1*s,height:75*s)
                Text(hit.cue.text).font(.system(size:22*s,weight:.medium).width(.condensed))
                    .multilineTextAlignment(.leading).frame(maxWidth:.infinity,alignment:.leading)
            }.padding(9*s).frame(height:108*s)
                .foregroundStyle(selected ? theme.primary.ink.color : theme.secondary.color)
                .background(selected ? theme.primary.color : .black).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func transcript(_ episode:ArchiveEpisode,s:CGFloat) -> some View {
        ZStack(alignment:.topLeading) {
            LCARSElbow(metrics:.init(verticalArm:165*s,horizontalArm:24*s,outerRadius:88*s,innerRadius:52*s))
                .fill(theme.secondary.color).ref(33,805,258,107,s)
            UnevenRoundedRectangle(bottomLeadingRadius:36*s).fill(theme.tertiary.color).ref(33,918,165,78,s)
            Text("02-447").lcarsDisplay(28*s).foregroundStyle(theme.secondary.ink.color).ref(110,866,70,40,s,alignment:.trailing)
            Text("TRANSCRIPT").lcarsDisplay(28*s).foregroundStyle(theme.tertiary.ink.color).ref(45,934,140,42,s,alignment:.trailing)
            Rectangle().fill(theme.primary.color).ref(298,805,707,24,s)
            LCARSSegment(.trailing).fill(theme.secondary.color).ref(1012,805,490,24,s)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing:2*s) {
                        ForEach(episode.cues) { cue in
                            let active = model.activeCue?.id == cue.id
                            Button { model.select(.init(episode:episode,cue:cue)) } label: {
                                HStack(spacing:20*s) {
                                    Text(active ? "▶" : " ").font(.system(size:14*s)).frame(width:22*s)
                                    Text(ArchiveModel.timecode(cue.start)).lcarsDisplay(25*s).frame(width:68*s,alignment:.leading)
                                    Text(cue.speaker.uppercased()).lcarsDisplay(25*s).frame(width:185*s,alignment:.leading)
                                    Rectangle().fill(theme.secondary.color).frame(width:1*s,height:28*s)
                                    Text(cue.text).font(.system(size:21*s,weight:.medium).width(.condensed))
                                        .frame(maxWidth:.infinity,alignment:.leading)
                                }.padding(.horizontal,14*s).frame(height:39*s)
                                    .foregroundStyle(active ? theme.primary.ink.color : theme.secondary.color)
                                    .background(active ? theme.primary.color : .black).contentShape(Rectangle())
                            }.buttonStyle(.plain).id(cue.id).accessibilityAddTraits(active ? .isSelected : [])
                        }
                    }
                }.scrollIndicators(.hidden)
                    .onChange(of:model.activeCue?.id) { _,id in if let id { proxy.scrollTo(id,anchor:.center) } }
            }.ref(231,836,1271,122,s)
            Rectangle().fill(theme.secondary.color).ref(231,967,1271,7,s)
            Text("ORIGINAL DEMO STORIES / ILLUSTRATED FRAMES / TRANSCRIPT PLAYBACK").lcarsDisplay(17*s)
                .foregroundStyle(theme.secondary.color).ref(800,979,702,24,s,alignment:.trailing)
        }
    }
}

private extension View {
    func ref(_ x:CGFloat,_ y:CGFloat,_ width:CGFloat,_ height:CGFloat,_ scale:CGFloat,alignment:Alignment = .center) -> some View {
        frame(width:width*scale,height:height*scale,alignment:alignment)
            .offset(x:x*scale,y:y*scale)
    }
}


private struct ArchivePhone: View {
    @ObservedObject var model: ArchiveModel
    @Binding var importing: Bool
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var section = 0
    @State private var episodes = false
    private let elbow = LCARSElbowMetrics(verticalArm:24,horizontalArm:12,outerRadius:36,innerRadius:20)
    var body: some View {
        #if LCARS_DUO_SDK && os(iOS)
        if #available(iOS 27.1, *), sizeClass == .regular {
            ArrangementView {
                phoneCanvas
            } secondary: {
                indexPanel
            }.arrangementViewStyle(.split)
        } else {
            phoneCanvas
        }
        #else
        if sizeClass == .regular {
            HStack(spacing:16) { phoneCanvas; indexPanel }
        } else { phoneCanvas }
        #endif
    }
    private var expanded: Bool { sizeClass == .regular }
    private var indexPanel: some View {
        VStack(alignment:.leading,spacing:12) {
            LCARSInstrumentHeader("Dialogue index")
            HStack(spacing:5) {
                tab("RESULTS \(model.results.count)",index:1,ends:.leading)
                tab("TRANSCRIPT",index:2,ends:.trailing)
            }
            ScrollView {
                if section == 2 { transcript } else { matches }
            }.scrollIndicators(.hidden)
            LCARSSegment(.trailing).fill(theme.secondary.color).frame(height:12)
        }.padding(16)
    }
    private var phoneCanvas: some View {
        VStack(spacing: 5) {
            HStack(alignment:.top,spacing:6) {
                LCARSElbow(metrics:elbow).fill(theme.primary.color).frame(width:66,height:58)
                Rectangle().fill(theme.tertiary.color).frame(width:32,height:12)
                Rectangle().fill(theme.secondary.color).frame(maxWidth:.infinity).frame(height:12)
                Text("DIALOGUE ARCHIVE").lcarsDisplay(34).foregroundStyle(theme.primary.color)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .alignmentGuide(.top) { dimensions in
                        dimensions[.firstTextBaseline] - LCARSTypography.capHeight(at:34) / 2 - 6
                    }
            }.accessibilityElement(children:.combine)
            HStack(alignment:.top,spacing:12) {
                VStack(spacing:5) {
                    Rectangle().fill(theme.secondary.color).frame(height:90)
                    Rectangle().fill(theme.primary.color).frame(height:52)
                    Rectangle().fill(theme.tertiary.color)
                }.frame(width:24).accessibilityHidden(true)
                VStack(alignment:.leading,spacing:8) {
                    HStack(spacing:8) {
                        TextField("Search dialogue",text:$model.query).textFieldStyle(.plain).lcarsDisplay(34)
                            .foregroundStyle(theme.secondary.color).submitLabel(.search)
                            .onSubmit { model.reconcileSearch(); section = 1 }
                            .accessibilityLabel("Search dialogue")
                        Button { model.reconcileSearch(); section = 1 } label: {
                            Image(systemName:"magnifyingglass").font(.system(size:18))
                                .frame(width:44,height:44).foregroundStyle(theme.primary.ink.color)
                                .background(LCARSSegment(.trailing).fill(theme.primary.color))
                        }.buttonStyle(.plain).accessibilityLabel("Search")
                    }.frame(minHeight:44)
                        .overlay(alignment:.bottom) { Rectangle().fill(theme.secondary.color).frame(height:2).padding(.trailing,52) }
                    HStack(spacing:6) {
                        Button { episodes = true } label: {
                            HStack(spacing:6) {
                                Text(model.episodes.first { $0.id == model.episodeFilter }?.title.uppercased() ?? "ALL EPISODES")
                                    .lcarsDisplay(22).lineLimit(1)
                                Image(systemName:"chevron.down").font(.system(size:10))
                            }.frame(maxWidth:.infinity,alignment:.leading)
                        }.buttonStyle(.plain)
                        Button { importing = true } label: {
                            Image(systemName:"square.and.arrow.down").frame(width:44,height:44)
                        }.buttonStyle(.plain).accessibilityLabel("Import subtitles")
                    }.foregroundStyle(theme.secondary.color).frame(minHeight:44)
                    if !expanded { HStack(spacing:5) {
                        tab("FRAME",index:0,ends:.leading)
                        tab("RESULTS \(model.results.count)",index:1,ends:.square)
                        tab("TRANSCRIPT",index:2,ends:.trailing)
                    } }
                    GeometryReader { viewport in
                        ScrollView {
                            VStack(alignment:.leading,spacing:10) {
                                if expanded || section == 0 {
                                    preview(availableHeight:viewport.size.height)
                                } else if section == 1 { matches }
                                else { transcript }
                            }.padding(.bottom,8)
                        }.scrollIndicators(.hidden)
                    }
                    if expanded || section == 0 { playbackControls }
                }
            }
            HStack(alignment:.bottom,spacing:6) {
                LCARSElbow(.bottomLeading,metrics:elbow).fill(theme.primary.color).frame(width:66,height:38)
                Rectangle().fill(theme.secondary.color).frame(width:36,height:12)
                LCARSSegment(.trailing).fill(theme.tertiary.color).frame(height:12)
            }.accessibilityHidden(true)
        }.padding(.horizontal,12).padding(.top,10).padding(.bottom,12)
            .popover(isPresented:$episodes) {
                VStack(alignment:.leading,spacing:12) {
                    Button("All episodes") { model.episodeFilter = "all"; episodes = false }
                    ForEach(model.episodes) { episode in
                        Button(episode.title) { model.episodeFilter = episode.id; episodes = false }
                    }
                    Toggle("Saved lines only",isOn:$model.savedOnly)
                }.padding(24).frame(minWidth:260).presentationCompactAdaptation(.popover)
            }
    }
    private func tab(_ title:String,index:Int,ends:LCARSSegment.Ends) -> some View {
        Button { section = index } label: {
            Text(title).lcarsDisplay(20).frame(maxWidth:.infinity).frame(height:44)
                .foregroundStyle((section == index ? theme.primary : theme.secondary).ink.color)
                .background { LCARSSegment(ends).fill((section == index ? theme.primary : theme.secondary).color).frame(height:30) }
        }.buttonStyle(.plain).accessibilityAddTraits(section == index ? .isSelected : [])
    }
    @ViewBuilder private func preview(availableHeight:CGFloat) -> some View {
        if let episode = model.selectedEpisode {
            ArchiveArtwork(name:episode.artwork,preservesComposition:true)
                // Measure the space remaining after navigation and transport controls.
                // Leave room for the episode heading and dialogue before growing the art.
                .frame(height:max(48,min(180,availableHeight - 110)))
                .accessibilityLabel("Illustrated frame for \(episode.title)")
            HStack(alignment:.firstTextBaseline) {
                Text(episode.title.uppercased()).lcarsDisplay(26)
                Spacer(minLength:4)
                Text(ArchiveModel.timecode(model.position)).lcarsDisplay(22).monospacedDigit()
            }.foregroundStyle(theme.primary.color)
            Text(model.activeCue?.text ?? "End of transcript").font(.system(size:17).width(.condensed))
                .foregroundStyle(theme.secondary.color).frame(maxWidth:.infinity,minHeight:40,alignment:.leading)
        } else {
            Text("No matching dialogue. Try another phrase.").foregroundStyle(theme.secondary.color).padding(.vertical,24)
        }
    }
    @ViewBuilder private var playbackControls: some View {
        if let episode = model.selectedEpisode {
            VStack(spacing:8) {
            LCARSTimeline(position:$model.position,duration:episode.duration,cues:episode.cues.map(\.start)) { editing in
                if editing { model.isPlaying = false }
            }
            HStack(spacing:5) {
                control("PREV",color:theme.secondary,ends:.leading) { model.moveCue(-1) }
                control(model.isPlaying ? "PAUSE" : "PLAY",color:theme.primary,ends:.square) {
                    if model.position >= episode.duration { model.position = 0 }
                    model.isPlaying.toggle()
                }
                control("NEXT",color:theme.tertiary,ends:.trailing) { model.moveCue(1) }
            }
            HStack {
                Button {
                    if let cue = model.activeCue { model.toggleSaved(cue) }
                } label: {
                    Label(model.activeCue.map { model.saved.contains($0.id) } == true ? "SAVED" : "SAVE LINE",systemImage:"bookmark")
                }.disabled(model.activeCue == nil)
                Spacer()
                ShareLink(item:model.exportText) { Label("EXPORT",systemImage:"square.and.arrow.up") }
            }.buttonStyle(.plain).labelStyle(LCARSLabelStyle()).lcarsDisplay(20)
                .foregroundStyle(theme.secondary.color).frame(minHeight:44)
            Text("ILLUSTRATED DEMO / TRANSCRIPT PLAYBACK").lcarsDisplay(16).foregroundStyle(theme.mutedText.color)
            }.padding(.top,6).background(theme.background.color)
        }
    }
    private func control(_ title:String,color:LCARSColor,ends:LCARSSegment.Ends,action:@escaping ()->Void) -> some View {
        Button(action:action) {
            Text(title).lcarsDisplay(25).frame(maxWidth:.infinity,minHeight:44)
                .foregroundStyle(color.ink.color).background(LCARSSegment(ends).fill(color.color))
        }.buttonStyle(.plain)
    }
    private var matches: some View {
        LazyVStack(spacing:8) {
            ForEach(model.results) { hit in
                Button { model.select(hit); section = 0 } label: {
                    HStack(alignment:.top,spacing:10) {
                        ArchiveArtwork(name:hit.episode.artwork).frame(width:82,height:60)
                        VStack(alignment:.leading,spacing:4) {
                            Text(hit.episode.title.uppercased()).lcarsDisplay(24)
                            Text(ArchiveModel.timecode(hit.cue.start)).lcarsDisplay(20)
                            Text(hit.cue.text).font(.system(size:16).width(.condensed))
                        }.frame(maxWidth:.infinity,alignment:.leading)
                    }.padding(.vertical,10).foregroundStyle(theme.secondary.color).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            if model.results.isEmpty { Text("No matches").foregroundStyle(theme.secondary.color) }
        }
    }
    private var transcript: some View {
        LazyVStack(alignment:.leading,spacing:6) {
            ForEach(model.selectedEpisode?.cues ?? []) { cue in
                let active = cue.id == model.activeCue?.id
                Button {
                    if let episode = model.selectedEpisode { model.select(.init(episode:episode,cue:cue)) }
                } label: {
                    VStack(alignment:.leading,spacing:6) {
                        HStack {
                            Text(ArchiveModel.timecode(cue.start)); Spacer(); Text(cue.speaker.uppercased())
                        }.lcarsDisplay(22)
                        Text(cue.text).font(.system(size:17).width(.condensed)).multilineTextAlignment(.leading)
                    }.padding(10).frame(maxWidth:.infinity,alignment:.leading)
                        .foregroundStyle(active ? theme.primary.ink.color : theme.secondary.color)
                        .background(active ? theme.primary.color : .black).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityAddTraits(active ? .isSelected : [])
            }
        }
    }
}
