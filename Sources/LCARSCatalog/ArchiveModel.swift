import Foundation
import Combine
import CryptoKit

struct ArchiveCue: Identifiable, Codable, Hashable {
    let id: String
    let start: Double
    let end: Double
    let speaker: String
    let text: String
}
struct ArchiveEpisode: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let code: String
    let artwork: String?
    let cues: [ArchiveCue]
    var duration: Double { max(1, cues.map(\.end).max() ?? 1) }
}
struct ArchiveHit: Identifiable {
    let episode: ArchiveEpisode
    let cue: ArchiveCue
    var id: String { cue.id }
}

@MainActor
final class ArchiveModel: ObservableObject {
    @Published var query = "coffee"
    @Published var episodeFilter = "all"
    @Published var savedOnly = false
    @Published var episodes: [ArchiveEpisode]
    @Published var selectedEpisodeID = "quiet"
    @Published var position: Double = 8
    @Published var isPlaying = false
    @Published var error: String?
    @Published var saved: Set<String> {
        didSet { UserDefaults.standard.set(Array(saved).sorted(), forKey: "lcars.archive.saved") }
    }
    init() {
        saved = Set(UserDefaults.standard.stringArray(forKey: "lcars.archive.saved") ?? [])
        let imported = UserDefaults.standard.data(forKey: "lcars.archive.imported")
            .flatMap { try? JSONDecoder().decode([ArchiveEpisode].self, from: $0) } ?? []
        episodes = Self.fixtures + imported
    }
    var results: [ArchiveHit] {
        episodes.filter { episodeFilter == "all" || $0.id == episodeFilter }.flatMap { episode in
            episode.cues.filter { cue in
                (!savedOnly || saved.contains(cue.id)) &&
                (query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                 "\(cue.text) \(cue.speaker) \(episode.title)".localizedStandardContains(query.trimmingCharacters(in: .whitespacesAndNewlines)))
            }.map { ArchiveHit(episode: episode, cue: $0) }
        }
    }
    var selectedEpisode: ArchiveEpisode? { episodes.first { $0.id == selectedEpisodeID } }
    var activeCue: ArchiveCue? {
        selectedEpisode?.cues.last { $0.start <= position && position < $0.end }
    }
    var exportText: String {
        guard let episode = selectedEpisode else { return "No episode selected." }
        let rows = episode.cues.map { "\(Self.timecode($0.start))  \($0.speaker): \($0.text)" }
        return "\(episode.title) / \(episode.code)\n" + rows.joined(separator: "\n")
    }
    func select(_ hit: ArchiveHit) {
        isPlaying = false; selectedEpisodeID = hit.episode.id; position = hit.cue.start
    }
    func reconcileSearch() {
        isPlaying = false
        if let first = results.first { select(first) }
        else { selectedEpisodeID = ""; position = 0 }
    }
    func moveCue(_ offset: Int) {
        guard let episode = selectedEpisode, !episode.cues.isEmpty else { return }
        let index = episode.cues.lastIndex { $0.start <= position } ?? 0
        let next = min(episode.cues.count - 1, max(0, index + offset))
        isPlaying = false; position = episode.cues[next].start
    }
    func toggleSaved(_ cue: ArchiveCue) {
        if saved.contains(cue.id) { saved.remove(cue.id) } else { saved.insert(cue.id) }
        if savedOnly { reconcileSearch() }
    }
    func importSubtitles(from url: URL) {
        do {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 2_000_000 else { throw ArchiveImportError.tooLarge }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            guard data.count <= 2_000_000 else { throw ArchiveImportError.tooLarge }
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
                throw ArchiveImportError.encoding
            }
            let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let id = "import-" + digest
            if let existing = episodes.first(where: { $0.id == id }) {
                query = ""; savedOnly = false; episodeFilter = existing.id; reconcileSearch(); return
            }
            let cues = try Self.parseSRT(text, episodeID: id)
            let episode = ArchiveEpisode(id: id, title: url.deletingPathExtension().lastPathComponent,
                                         code: "IMPORTED SRT", artwork: nil, cues: cues)
            let imports = episodes.filter { $0.artwork == nil } + [episode]
            guard imports.count <= 20 else { throw ArchiveImportError.libraryFull }
            let encoded = try JSONEncoder().encode(imports)
            UserDefaults.standard.set(encoded, forKey: "lcars.archive.imported")
            episodes.append(episode)
            query = ""; savedOnly = false; episodeFilter = id; reconcileSearch()
        } catch { self.error = error.localizedDescription }
    }
    static func timecode(_ value: Double) -> String {
        let seconds = Int(max(0, value.isFinite ? value : 0))
        if seconds >= 3600 { return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60) }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    static func parseSRT(_ text: String, episodeID: String) throws -> [ArchiveCue] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{feff}", with: "")
        let lines = normalized.components(separatedBy: "\n")
        var cues: [ArchiveCue] = []
        var index = 0
        while index < lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespaces)
            guard line.contains("-->") else { index += 1; continue }
            let times = line.components(separatedBy: "-->")
            guard times.count == 2,
                  let start = timestamp(times[0]), let end = timestamp(times[1]), end > start else {
                throw ArchiveImportError.malformed
            }
            index += 1
            var content: [String] = []
            while index < lines.count && !lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
                content.append(lines[index]); index += 1
            }
            let dialogue = content.joined(separator: " ").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !dialogue.isEmpty {
                cues.append(ArchiveCue(id: "\(episodeID)-\(cues.count)", start: start, end: end, speaker: "Dialogue", text: dialogue))
            }
            guard cues.count <= 10_000 else { throw ArchiveImportError.tooLarge }
        }
        guard !cues.isEmpty else { throw ArchiveImportError.malformed }
        return cues.sorted { $0.start < $1.start }
    }
    private static func timestamp(_ raw: String) -> Double? {
        let token = raw.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).first ?? ""
        let parts = token.replacingOccurrences(of: ",", with: ".").split(separator: ":")
        guard parts.count == 3, let h = Double(parts[0]), let m = Double(parts[1]), let s = Double(parts[2]),
              h.isFinite, m.isFinite, s.isFinite, h >= 0, h < 100, m >= 0, m < 60, s >= 0, s < 60 else { return nil }
        return h * 3600 + m * 60 + s
    }
    private static let fixtures: [ArchiveEpisode] = [
        fixture("quiet", "The Quiet Signal", "DEMO 01", "archive-bridge", [
            ("Vale", "The overnight survey is ready."),
            ("Ives", "Your coffee is getting cold, Commander."),
            ("Vale", "Coffee can wait. That signal can't."),
            ("Ives", "The source is just beyond the outer marker."),
            ("Vale", "Send the probe. Keep the channel open."),
            ("Ives", "Probe telemetry is coming through.")]),
        fixture("watch", "Night Watch", "DEMO 02", "archive-nebula", [
            ("Ren", "The probe has crossed the dust front."),
            ("Ellis", "We have six hours of clear reception."),
            ("Ren", "Then I have time for one more coffee."),
            ("Ellis", "There. The signal repeats every nine seconds."),
            ("Ren", "Record the whole sequence."),
            ("Ellis", "The archive is ready.")]),
        fixture("surface", "Surface Detail", "DEMO 03", "archive-surface", [
            ("Sen", "The ridge is stable. Bring the scanner forward."),
            ("Mora", "I should have packed the coffee."),
            ("Sen", "You packed a full geology lab instead."),
            ("Mora", "The signal is stronger near these rocks."),
            ("Sen", "Mark the coordinates and take a sample."),
            ("Mora", "Surface survey complete.")])
    ]
    private static func fixture(_ id: String, _ title: String, _ code: String, _ art: String,
                                _ dialogue: [(String, String)]) -> ArchiveEpisode {
        ArchiveEpisode(id: id, title: title, code: code, artwork: art,
                       cues: dialogue.enumerated().map { i, line in
                           ArchiveCue(id: "\(id)-\(i)", start: Double(i * 8), end: Double((i + 1) * 8), speaker: line.0, text: line.1)
                       })
    }
}
private enum ArchiveImportError: LocalizedError {
    case tooLarge, encoding, malformed, libraryFull
    var errorDescription: String? {
        switch self {
        case .tooLarge: "Choose an SRT file under 2 MB with at most 10,000 cues."
        case .encoding: "Save the subtitle file as UTF-8 or UTF-16 text, then import it again."
        case .malformed: "No valid SRT transcript was found. Expected numbered cues with start --> end timestamps."
        case .libraryFull: "This sample stores up to 20 imported transcripts."
        }
    }
}
