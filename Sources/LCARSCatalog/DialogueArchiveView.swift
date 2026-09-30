import SwiftUI
import SwiftLCARS
import UniformTypeIdentifiers
import ImageIO

struct DialogueArchiveView: View {
    @StateObject private var model = ArchiveModel()
    @State private var importing = false
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsIsCompact) private var compact
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            LCARSSearchField("Search dialogue", text: $model.query) { model.reconcileSearch() }
            filters
            if model.results.isEmpty {
                ContentUnavailableView {
                    Label(model.savedOnly ? "No saved matches" : "No dialogue found", systemImage: "text.magnifyingglass")
                } description: {
                    Text("Try another phrase, select all episodes, or clear the saved filter.")
                } actions: {
                    Button("Show all dialogue") {
                        model.query = ""; model.episodeFilter = "all"; model.savedOnly = false
                    }.buttonStyle(.lcars(.secondary))
                }
            } else if compact {
                inspector
                results
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 22) {
                        results.frame(minWidth: 290, maxWidth: 410)
                        inspector.frame(minWidth: 350, maxWidth: .infinity)
                    }
                    VStack(alignment: .leading, spacing: 22) { inspector; results }
                }
            }
            if let episode = model.selectedEpisode {
                LCARSPanel("Transcript", identifier: episode.code) {
                    transcript(episode)
                }
            }
            Text("Original demo stories and AI-generated stills. Play advances the transcript; no video or audio is included. Imported SRT files contain text only.")
                .font(.caption).foregroundStyle(theme.mutedText.color)
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

    private var filters: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { episodePicker; savedFilter; Spacer(minLength: 0); importButton }
            VStack(alignment: .leading, spacing: 8) {
                episodePicker
                HStack { savedFilter; Spacer(minLength: 0); importButton }
            }
        }
    }
    private var episodePicker: some View {
        Picker("Episode", selection: $model.episodeFilter) {
            Text("All episodes").tag("all")
            ForEach(model.episodes) { Text($0.title).tag($0.id) }
        }.pickerStyle(.menu).tint(theme.secondary.color).frame(minHeight: 44)
    }
    private var savedFilter: some View {
        Toggle(isOn: $model.savedOnly) { Label("Saved", systemImage: "bookmark") }
            .toggleStyle(.button).tint(theme.secondary.color).frame(minHeight: 44)
    }
    private var importButton: some View {
        Button { importing = true } label: { Label("Import SRT", systemImage: "square.and.arrow.down") }
            .buttonStyle(.lcars(.secondary, ends: .trailing))
    }
    private var results: some View {
        VStack(alignment: .leading, spacing: 8) {
            LCARSInstrumentHeader("Search results", identifier: "\(model.results.count) MATCHES")
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(model.results) { hit in
                        resultRow(hit)
                    }
                }
            }.frame(maxHeight: compact ? 290 : 390)
        }
    }
    private func resultRow(_ hit: ArchiveHit) -> some View {
        let selected = model.selectedEpisodeID == hit.episode.id && model.activeCue?.id == hit.cue.id
        let fill = selected ? theme.primary : theme.background
        return Button { model.select(hit) } label: {
            HStack(alignment: .top, spacing: 12) {
                ArchiveArtwork(name: hit.episode.artwork).frame(width: 92, height: 60).clipped().accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(hit.episode.title).textCase(.uppercase).lcarsDisplay(25).lineLimit(2)
                    HStack(spacing: 8) {
                        Text(ArchiveModel.timecode(hit.cue.start)).lcarsDisplay(20)
                        if model.saved.contains(hit.id) { Image(systemName: "bookmark.fill").font(.caption) }
                    }
                    Text(hit.cue.text).font(.callout).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.padding(9).foregroundStyle(selected ? fill.ink.color : theme.secondary.color)
                .background(fill.color)
                .overlay(alignment: .bottom) { Rectangle().fill(theme.tertiary.color).frame(height: 1) }
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel("\(hit.episode.title), \(ArchiveModel.timecode(hit.cue.start)), \(hit.cue.text)")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
    @ViewBuilder private var inspector: some View {
        if let episode = model.selectedEpisode {
            VStack(alignment: .leading, spacing: 10) {
                ArchiveArtwork(name: episode.artwork).frame(height: compact ? 160 : 180)
                    .overlay(alignment: .bottomLeading) {
                        Text(episode.artwork == nil ? "TRANSCRIPT ONLY" : "DEMO STORYBOARD")
                            .lcarsDisplay(18, relativeTo: .caption).padding(6)
                            .foregroundStyle(theme.primary.color).background(.black.opacity(0.85))
                    }
                    .accessibilityLabel(episode.artwork == nil ? "No media attached" : "Generated illustration for \(episode.title)")
                HStack(alignment: .firstTextBaseline) {
                    Text(episode.title).textCase(.uppercase).lcarsDisplay(30)
                    Spacer(minLength: 8)
                    Text("\(ArchiveModel.timecode(model.position)) / \(ArchiveModel.timecode(episode.duration))")
                        .lcarsDisplay(22).monospacedDigit()
                }.foregroundStyle(theme.primary.color)
                Text(model.activeCue?.text ?? (model.position >= episode.duration ? "End of transcript" : "…"))
                    .font(.body).foregroundStyle(theme.secondary.color)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                LCARSTimeline(position: $model.position, duration: episode.duration, cues: episode.cues.map(\.start)) { editing in
                    if editing { model.isPlaying = false }
                }
                transport
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) { saveButton; exportButton }
                    VStack(alignment: .leading, spacing: 6) { saveButton; exportButton }
                }
            }
        }
    }
    private var transport: some View {
        HStack(spacing: 6) {
            Button { model.moveCue(-1) } label: {
                Image(systemName: "backward.end.fill").font(.system(size: 16))
            }.buttonStyle(.lcars(.secondary, ends: .leading)).accessibilityLabel("Previous dialogue")
            Button(model.isPlaying ? "Pause" : "Play transcript") {
                if !model.isPlaying, let episode = model.selectedEpisode, model.position >= episode.duration { model.position = 0 }
                model.isPlaying.toggle()
            }.buttonStyle(.lcars(.primary, ends: .square)).frame(maxWidth: .infinity)
            Button { model.moveCue(1) } label: {
                Image(systemName: "forward.end.fill").font(.system(size: 16))
            }.buttonStyle(.lcars(.secondary, ends: .trailing)).accessibilityLabel("Next dialogue")
        }
    }
    private var saveButton: some View {
        let isSaved = model.activeCue.map { model.saved.contains($0.id) } ?? false
        return Button {
            if let cue = model.activeCue { model.toggleSaved(cue) }
        } label: { Label(isSaved ? "Unsave line" : "Save line", systemImage: isSaved ? "bookmark.fill" : "bookmark") }
            .buttonStyle(.lcars(.secondary, ends: .square)).disabled(model.activeCue == nil)
    }
    private var exportButton: some View {
        ShareLink(item: model.exportText) { Label("Export", systemImage: "square.and.arrow.up") }
            .buttonStyle(.lcars(.secondary, ends: .trailing))
    }
    private func transcript(_ episode: ArchiveEpisode) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(episode.cues) { cue in
                        let active = model.activeCue?.id == cue.id
                        Button {
                            model.select(ArchiveHit(episode: episode, cue: cue))
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(ArchiveModel.timecode(cue.start)).lcarsDisplay(22).frame(minWidth: 40, alignment: .leading)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(cue.speaker).textCase(.uppercase).lcarsDisplay(22)
                                    Text(cue.text).font(.callout).multilineTextAlignment(.leading)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                if active { Image(systemName: "play.fill").font(.caption).accessibilityHidden(true) }
                            }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(active ? theme.primary.ink.color : theme.secondary.color)
                                .background(active ? theme.primary.color : theme.background.color)
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityAddTraits(active ? .isSelected : []).id(cue.id)
                    }
                }
            }.frame(height: compact ? 235 : 210)
                .onChange(of: model.activeCue?.id) { _, id in
                    if let id { proxy.scrollTo(id, anchor: .center) }
                }
        }
    }
}

private struct ArchiveArtwork: View {
    let name: String?
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
                Image(decorative: image, scale: 1).resizable().scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height).clipped()
            } else {
                Rectangle().fill(Color(white: 0.08)).overlay {
                    Image(systemName: "captions.bubble").font(.largeTitle).foregroundStyle(.secondary)
                }
            }
        }
    }
}
