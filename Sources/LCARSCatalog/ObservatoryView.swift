import SwiftUI
import SwiftLCARS

private struct Observation: Identifiable {
    let id: String
    let code: String
    let method: String
    let range: String
    let position: CGPoint
    let peaks: [Double]
    static let targets = [
        Observation(id: "Terra", code: "SOL-03", method: "Spectrography", range: "04.72", position: CGPoint(x: 0.72, y: 0.66), peaks: [0.28, 0.46, 0.62]),
        Observation(id: "Mars", code: "SOL-04", method: "Surface mapping", range: "02.18", position: CGPoint(x: 0.34, y: 0.35), peaks: [0.21, 0.54, 0.79]),
        Observation(id: "Jupiter", code: "SOL-05", method: "Atmospheric survey", range: "08.36", position: CGPoint(x: 0.16, y: 0.72), peaks: [0.18, 0.38, 0.68])
    ]
}

struct ObservatoryView: View {
    let animated: Bool
    @Binding var scanning: Bool
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsIsCompact) private var compact
    @State private var query = ""
    @State private var selectedID = "Terra"
    @State private var scanProgress = 0.0
    @State private var records: [String] = []
    private var selected: Observation { Observation.targets.first { $0.id == selectedID } ?? Observation.targets[0] }
    private var filtered: [Observation] { Observation.targets.filter { query.isEmpty || $0.id.localizedCaseInsensitiveContains(query) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if compact {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { targetPicker; Spacer(minLength: 0); scanButton }
                    VStack(alignment: .leading, spacing: 12) { targetPicker; scanButton }
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 30) {
                    sector.frame(minWidth: 380)
                    telemetry.frame(minWidth: 300, maxWidth: 390)
                }
                VStack(alignment: .leading, spacing: 24) { sector; telemetry }
            }
            targetDirectory
            if !records.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    LCARSInstrumentHeader("Observation log", identifier: "MEMORY 02")
                    ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                        Text(record).font(.callout.monospacedDigit()).foregroundStyle(theme.secondary.color)
                    }
                }
            }
            Text("Training simulation. Positions, ranges and spectra are illustrative.")
                .font(.caption).foregroundStyle(theme.mutedText.color)
        }
        .task(id: scanning) {
            guard scanning else { return }
            let target = selected
            scanProgress = 0
            for step in 1...24 {
                do { try await Task.sleep(for: .milliseconds(125)) } catch { return }
                guard !Task.isCancelled else { return }
                scanProgress = Double(step) / 24
            }
            records.insert("\(target.code)  /  \(target.method) complete  /  3 peaks resolved", at: 0)
            records = Array(records.prefix(5))
            scanning = false
        }
        .onChange(of: selectedID) { _, _ in scanProgress = 0 }
        .onDisappear { scanning = false }
    }

    private var targetPicker: some View {
        Picker("Target", selection: $selectedID) {
            ForEach(Observation.targets) { Text($0.id).tag($0.id) }
        }.pickerStyle(.menu).tint(theme.primary.color).disabled(scanning)
            .frame(minHeight: 44).accessibilityLabel("Observation target")
    }

    private var sector: some View {
        VStack(alignment: .leading, spacing: 12) {
            LCARSInstrumentHeader("Long range sensors", identifier: "SCI 04")
            HStack(alignment: .firstTextBaseline) {
                Text("SECTOR 001 / SOL").lcarsDisplay(23)
                Spacer()
                Text(selected.code).lcarsDisplay(23)
            }.foregroundStyle(theme.secondary.color)
            OrbitDiagram(selected: selected).frame(height: compact ? 220 : 320)
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(selected.id).textCase(.uppercase).lcarsDisplay(48, relativeTo: .title)
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("SIMULATED RANGE").lcarsDisplay(19, relativeTo: .caption)
                    Text("\(selected.range) AU").lcarsDisplay(32, relativeTo: .title3)
                }
            }.foregroundStyle(theme.primary.color).accessibilityElement(children: .combine)
            LCARSIndicatorTrack(.leftToRight, count: compact ? 12 : 20, animated: animated).frame(height: 8)
            LCARSDataBank(columns: compact ? 5 : 7, rows: 3, seed: 47028, animated: animated)
        }
    }

    private var telemetry: some View {
        VStack(alignment: .leading, spacing: 14) {
            LCARSInstrumentHeader("Sensor telemetry", identifier: "02-158")
            HStack {
                Text("ARRAY")
                Spacer()
                Text("RESOLUTION / STATUS")
            }.lcarsDisplay(19, relativeTo: .caption).foregroundStyle(theme.tertiary.color)
                .accessibilityHidden(true)
            VStack(spacing: 7) {
                sensorRow("Lateral 01", value: "0.0042", state: "Online")
                sensorRow("Lateral 02", value: "0.0038", state: "Online")
                sensorRow("Forward", value: "0.0016", state: scanning ? "Active" : "Ready")
            }
            HStack(spacing: 6) {
                Rectangle().fill(theme.tertiary.color).frame(width: 44)
                LCARSIndicatorTrack(.rightToLeft, count: 14, animated: animated)
            }.frame(height: 10).accessibilityHidden(true)
            LCARSInstrumentHeader("Spectral analysis")
            LCARSSpectrum(samples: spectrum, label: "Simulated spectrum for \(selected.id)",
                          summary: "Three illustrative emission peaks. Horizontal axis is normalized wavelength.")
                .frame(height: 120)
            LCARSMeter("Scan completion", value: scanProgress)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) { scanButton; exportButton }
                VStack(alignment: .leading, spacing: 6) { scanButton; exportButton }
            }
            Text(scanning ? "Acquiring \(selected.method.lowercased())…" : (scanProgress == 1 ? "Scan complete. Record stored below." : "Select a target and run a sensor scan."))
                .font(.caption).foregroundStyle(theme.mutedText.color)
        }
    }

    private var scanButton: some View {
        Button(scanning ? "Cancel scan" : "Run scan") {
            if scanning { scanning = false; scanProgress = 0 }
            else { scanning = true }
        }.buttonStyle(.lcars(.primary, ends: .leading))
    }
    private var exportButton: some View {
        ShareLink(item: "LCARS training simulation\n" + (records.isEmpty ? "No completed scans." : records.joined(separator: "\n"))) {
            Label("Export log", systemImage: "square.and.arrow.up")
        }.buttonStyle(.lcars(.secondary, ends: .trailing)).disabled(records.isEmpty)
    }
    private var spectrum: [Double] {
        (0..<100).map { index in
            let x = Double(index) / 99
            let baseline = 0.08 + 0.035 * abs(sin(x * 91))
            return min(1, baseline + selected.peaks.enumerated().reduce(0) { sum, peak in
                sum + (0.56 + Double(peak.offset) * 0.14) * exp(-pow((x - peak.element) / 0.018, 2))
            })
        }
    }

    private var targetDirectory: some View {
        VStack(alignment: .leading, spacing: 10) {
            LCARSInstrumentHeader("Target directory", identifier: "CATALOG 001")
            TextField("Filter targets", text: $query).textFieldStyle(.plain)
                .padding(10).background(theme.secondary.color.opacity(0.12))
                .overlay(alignment: .bottom) { Rectangle().fill(theme.secondary.color).frame(height: 2) }
                .accessibilityLabel("Filter targets")
            if filtered.isEmpty { ContentUnavailableView.search(text: query) }
            ForEach(filtered) { target in
                Button { selectedID = target.id } label: {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 14) {
                            Text(target.code).frame(width: 62, alignment: .leading)
                            Text(target.id).frame(maxWidth: .infinity, alignment: .leading)
                            Text(target.method)
                            Image(systemName: selectedID == target.id ? "checkmark.circle.fill" : "circle")
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text(target.id); Spacer(); Image(systemName: selectedID == target.id ? "checkmark.circle.fill" : "circle") }
                            Text(target.method).font(.callout)
                        }
                    }
                }
                .buttonStyle(LCARSButtonStyle(selectedID == target.id ? .primary : .secondary, ends: .square, horizontalPadding: 12))
                .accessibilityAddTraits(selectedID == target.id ? .isSelected : [])
                .disabled(scanning)
            }
        }
    }

    private func sensorRow(_ title: String, value: String, state: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(title).textCase(.uppercase); Spacer(minLength: 4)
                Text(value); Text(state).textCase(.uppercase).frame(minWidth: 46, alignment: .trailing)
            }
            VStack(alignment: .leading) { Text(title); Text("\(value) / \(state)") }
        }.lcarsDisplay(25).foregroundStyle(theme.secondary.color).accessibilityElement(children: .combine)
    }
}

private struct OrbitDiagram: View {
    let selected: Observation
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsFontMode) private var fontMode
    var body: some View {
        Canvas { canvas, size in
            let inset: CGFloat = 22
            let plot = CGRect(x: inset, y: 12, width: max(1, size.width - inset * 2), height: size.height - 42)
            let center = CGPoint(x: plot.midX, y: plot.midY)
            for ratio in [0.24, 0.45, 0.68, 0.92] {
                let w = plot.width * ratio, h = plot.height * ratio * 0.88
                canvas.stroke(Path(ellipseIn: CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)),
                              with: .color(theme.secondary.color), lineWidth: 1.4)
            }
            var axes = Path()
            axes.move(to: CGPoint(x: plot.minX, y: center.y)); axes.addLine(to: CGPoint(x: plot.maxX, y: center.y))
            axes.move(to: CGPoint(x: center.x, y: plot.minY)); axes.addLine(to: CGPoint(x: center.x, y: plot.maxY))
            axes.move(to: CGPoint(x: plot.minX + 20, y: plot.minY + 24)); axes.addLine(to: CGPoint(x: plot.maxX - 20, y: plot.maxY - 24))
            canvas.stroke(axes, with: .color(theme.tertiary.color), style: StrokeStyle(lineWidth: 1, dash: [2, 7]))
            var ticks = Path()
            for i in 0...20 {
                let x = plot.minX + plot.width * CGFloat(i) / 20
                ticks.move(to: CGPoint(x: x, y: plot.maxY + 8))
                ticks.addLine(to: CGPoint(x: x, y: plot.maxY + (i % 5 == 0 ? 17 : 12)))
            }
            canvas.stroke(ticks, with: .color(theme.tertiary.color), lineWidth: 1)
            canvas.fill(Path(ellipseIn: CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18)), with: .color(theme.primary.color))
            for target in Observation.targets {
                let point = CGPoint(x: plot.minX + plot.width * target.position.x, y: plot.minY + plot.height * target.position.y)
                canvas.fill(Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)), with: .color(theme.secondary.color))
                if selected.id == target.id {
                    canvas.stroke(Path(ellipseIn: CGRect(x: point.x - 14, y: point.y - 14, width: 28, height: 28)), with: .color(theme.primary.color), lineWidth: 2)
                    let labelY = min(plot.maxY - 8, point.y + 40)
                    let labelX = min(plot.maxX, point.x + 65)
                    var leader = Path()
                    leader.move(to: CGPoint(x: point.x + 14, y: point.y))
                    leader.addLine(to: CGPoint(x: labelX, y: point.y))
                    leader.addLine(to: CGPoint(x: labelX, y: labelY - 16))
                    canvas.stroke(leader, with: .color(theme.primary.color), lineWidth: 1.5)
                    canvas.draw(Text(target.code).font(fontMode == .readable ? .caption : LCARSTypography.display(20)).foregroundColor(theme.primary.color),
                                at: CGPoint(x: labelX, y: labelY), anchor: .trailing)
                }
            }
        }
        .accessibilityLabel("Illustrative solar-system sensor map")
        .accessibilityValue("Selected target: \(selected.id). Three targets. Positions are illustrative and not to scale.")
    }
}
