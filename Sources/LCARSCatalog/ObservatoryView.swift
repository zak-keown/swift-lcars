import SwiftUI
import SwiftLCARS

private struct Observation: Identifiable {
    let id: String
    let method: String
    let duration: String
}

struct ObservatoryView: View {
    let animated: Bool
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsIsCompact) private var compact
    @State private var query = ""
    @State private var selected = "Sol / Terra"
    @State private var scanning = false
    @State private var scanProgress = 0.0
    @State private var scansCompleted = 0
    private let observations = [
        Observation(id: "Sol / Terra", method: "Spectrography", duration: "00:04:28"),
        Observation(id: "Sol / Mars", method: "Surface mapping", duration: "00:12:06"),
        Observation(id: "Sol / Jupiter", method: "Atmospheric survey", duration: "00:08:42")
    ]
    private var filtered: [Observation] { observations.filter { query.isEmpty || $0.id.localizedCaseInsensitiveContains(query) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 30) {
                    sector.frame(minWidth: 350)
                    telemetry.frame(minWidth: 300, maxWidth: 420)
                }
                VStack(alignment: .leading, spacing: 28) { sector; telemetry }
            }
            LCARSSection("Observation record") {
                TextField("Filter targets", text: $query).textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Filter targets")
                if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    VStack(spacing: 6) {
                        ForEach(filtered) { observation in
                            Button { selected = observation.id } label: {
                                ViewThatFits(in: .horizontal) {
                                    HStack {
                                        Text(observation.id).frame(maxWidth: .infinity, alignment: .leading)
                                        Text(observation.method).frame(maxWidth: .infinity, alignment: .leading)
                                        Text(observation.duration).monospacedDigit()
                                        Image(systemName: selected == observation.id ? "checkmark.circle.fill" : "circle")
                                    }
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack { Text(observation.id); Spacer(); if selected == observation.id { Image(systemName: "checkmark") } }
                                        Text(observation.method).font(.callout)
                                    }
                                }
                            }
                            .buttonStyle(.lcars(selected == observation.id ? .primary : .secondary, ends: .square))
                            .accessibilityAddTraits(selected == observation.id ? .isSelected : [])
                        }
                    }
                }
                Text("Illustrative observatory data · \(scansCompleted) simulated scans completed")
                    .font(.caption).foregroundStyle(theme.mutedText.color)
            }
        }
        .task(id: scanning) {
            guard scanning else { return }
            scanProgress = 0
            for step in 1...20 {
                do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
                guard !Task.isCancelled else { return }
                scanProgress = Double(step) / 20
            }
            scansCompleted += 1
            scanning = false
        }
        .onDisappear { scanning = false }
    }

    private var sector: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Sector 001 / Sol system").textCase(.uppercase).lcarsDisplay(26)
                Spacer()
                Text("0047.28").lcarsDisplay(26)
            }.foregroundStyle(theme.primary.color)
            OrbitDiagram(selected: selected).frame(height: compact ? 210 : 285)
            HStack(alignment: .top) {
                LCARSReadout("Range", value: "04.72", unit: "AU")
                Spacer(minLength: 10)
                LCARSReadout("Target", value: selected.components(separatedBy: " / ").last ?? "Terra")
            }
            LCARSNumberGrid(columns: compact ? 5 : 7, rows: 2, animated: animated)
        }
    }

    private var telemetry: some View {
        LCARSSection("Sensor telemetry") {
            VStack(spacing: 12) {
                sensorRow("Lateral 01", value: "0.0042", state: "Online")
                sensorRow("Lateral 02", value: "0.0038", state: "Online")
                sensorRow("Forward", value: "0.0016", state: scanning ? "Scanning" : "Ready")
            }
            LCARSActivityBand(.leftToRight, animated: animated).frame(height: 10)
            SpectrumPlot().frame(height: 98)
            LCARSMeter("Scan completion", value: scanProgress)
            HStack(spacing: 8) {
                Button(scanning ? "Cancel scan" : "Run scan") { scanning.toggle() }
                    .buttonStyle(.lcars(.primary))
                ShareLink(item: "LCARS Observatory sample: \(selected), \(scansCompleted) simulated scans completed.") {
                    Label("Export", systemImage: "square.and.arrow.up")
                }.buttonStyle(.lcars(.secondary))
            }
        }
    }
    private func sensorRow(_ title: String, value: String, state: String) -> some View {
        HStack {
            Text(title).textCase(.uppercase).lcarsDisplay(24)
            Spacer()
            Text(value).font(.callout.monospacedDigit())
            Text(state).font(.caption).frame(minWidth: 55, alignment: .trailing)
        }.foregroundStyle(theme.secondary.color).accessibilityElement(children: .combine)
    }
}

private struct OrbitDiagram: View {
    let selected: String
    @Environment(\.lcarsTheme) private var theme
    var body: some View {
        Canvas { canvas, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for ratio in [0.24, 0.45, 0.68, 0.92] {
                let w = size.width * ratio, h = size.height * ratio * 0.75
                canvas.stroke(Path(ellipseIn: CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)), with: .color(theme.secondary.color), lineWidth: 1)
            }
            var axes = Path()
            axes.move(to: CGPoint(x: 0, y: center.y)); axes.addLine(to: CGPoint(x: size.width, y: center.y))
            axes.move(to: CGPoint(x: center.x, y: 0)); axes.addLine(to: CGPoint(x: center.x, y: size.height))
            canvas.stroke(axes, with: .color(theme.tertiary.color), style: StrokeStyle(lineWidth: 1, dash: [2, 8]))
            canvas.fill(Path(ellipseIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)), with: .color(theme.primary.color))
            let planets: [(CGFloat, CGFloat, String)] = [(0.36, 0.41, "Mars"), (0.71, 0.66, "Terra"), (0.15, 0.70, "Jupiter")]
            for (x, y, name) in planets {
                let point = CGPoint(x: size.width * x, y: size.height * y)
                canvas.fill(Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)), with: .color(theme.secondary.color))
                if selected.hasSuffix(name) {
                    canvas.stroke(Path(ellipseIn: CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)), with: .color(theme.primary.color), lineWidth: 2)
                    canvas.draw(Text(name.uppercased()).font(LCARSTypography.display(24)).foregroundColor(theme.primary.color), at: CGPoint(x: point.x + 22, y: point.y + 24), anchor: .leading)
                }
            }
        }
        .accessibilityLabel("Illustrative solar-system diagram")
        .accessibilityValue("Selected target: \(selected). Diagram not to scale.")
    }
}

private struct SpectrumPlot: View {
    @Environment(\.lcarsTheme) private var theme
    let values: [Double] = [0.1,0.1,0.2,0.1,0.1,0.2,0.12,0.5,0.12,0.12,0.72,0.12,0.14,0.95,0.18,0.3,0.12,0.12,0.52,0.12,0.12,0.2,0.1,0.1]
    var body: some View {
        Canvas { canvas, size in
            var baseline = Path()
            baseline.move(to: .zero); baseline.addLine(to: CGPoint(x: 0, y: size.height))
            baseline.addLine(to: CGPoint(x: size.width, y: size.height))
            canvas.stroke(baseline, with: .color(theme.tertiary.color), lineWidth: 1)
            var line = Path()
            for (index, value) in values.enumerated() {
                let point = CGPoint(x: size.width * Double(index) / Double(values.count - 1), y: size.height * (1 - value))
                if index == 0 { line.move(to: point) } else { line.addLine(to: point) }
            }
            canvas.stroke(line, with: .color(theme.primary.color), lineWidth: 2)
        }.accessibilityLabel("Illustrative spectral plot").accessibilityValue("Three prominent peaks; simulated data.")
    }
}
