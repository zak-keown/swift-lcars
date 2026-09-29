import SwiftUI
import SwiftLCARS

struct ComponentGallery: View {
    @Binding var alert: LCARSAlert
    @Binding var readable: Bool
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.layoutDirection) private var direction
    @State private var outer = 72.0
    @State private var inner = 48.0
    @State private var telemetry = true
    @State private var activations = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            LCARSSection("Elbow geometry") {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 30) { elbow; geometryControls.frame(minWidth: 220) }
                    VStack(alignment: .leading, spacing: 20) { elbow; geometryControls }
                }
            }
            LCARSSection("Typography") {
                Text("Library computer access").textCase(.uppercase).lcarsDisplay(46, relativeTo: .largeTitle)
                    .foregroundStyle(theme.primary.color)
                Text("0123456789 / 1701-D / 47.028").lcarsDisplay(36, relativeTo: .title)
                    .foregroundStyle(theme.secondary.color)
                Toggle("Readable typography", isOn: $readable).toggleStyle(.lcars)
                Text("Natural LCARS GTJ3 letterforms for display. System text for longer reading and accessibility sizes.")
                    .font(.body).foregroundStyle(theme.mutedText.color)
            }
            LCARSSection("Native controls") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), alignment: .leading)], alignment: .leading, spacing: 12) {
                    Button("Primary") { activations += 1 }.buttonStyle(.lcars())
                    Button("Secondary") { activations += 1 }.buttonStyle(.lcars(.secondary))
                    Button("Accent") { activations += 1 }.buttonStyle(.lcars(.accent, ends: .trailing))
                    Button("Disabled") {}.buttonStyle(.lcars()).disabled(true)
                }
                Text("Control activations: \(activations)").font(.callout.monospacedDigit())
                Toggle("Sensor telemetry", isOn: $telemetry).toggleStyle(.lcars)
                Picker("Alert state", selection: $alert) {
                    ForEach(LCARSAlert.allCases) { Text($0.label).tag($0) }
                }.pickerStyle(.menu)
                LCARSStatus()
            }
            LCARSSection("Readouts") {
                LCARSReadout("Sensor range", value: "04.72", unit: "AU")
                LCARSMeter("Available capacity", value: 0.72)
            }
        }
    }
    private var elbow: some View {
        LCARSElbow(metrics: .init(outerRadius: outer, innerRadius: inner), layoutDirection: direction)
            .fill(theme.primary.color).frame(width: 280, height: 180)
            .accessibilityLabel("Elbow geometry preview")
            .accessibilityValue("Outer radius \(Int(outer)), inner radius \(Int(inner)) points")
    }
    private var geometryControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Outer radius: \(Int(outer)) pt").font(.callout.monospacedDigit())
            Slider(value: $outer, in: 0...120, step: 1) { Text("Outer radius") }
            Text("Inner radius: \(Int(inner)) pt").font(.callout.monospacedDigit())
            Slider(value: $inner, in: 0...100, step: 1) { Text("Inner radius") }
            Button("Restore reference") { outer = 72; inner = 48 }.buttonStyle(.lcars(.secondary))
        }
    }
}

struct MotionGallery: View {
    @Binding var animated: Bool
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var counter = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Toggle("Ambient animation", isOn: $animated).toggleStyle(.lcars)
            Text(reduceMotion ? "Reduce Motion is enabled. Decorative animation is paused." : "Decorative displays are synthetic. Turning off ambient animation leaves live controls and real progress updates working.")
                .font(.callout).foregroundStyle(theme.mutedText.color)
            LCARSSection("Cycling numbers") {
                LCARSNumberGrid(columns: 6, rows: 4, animated: animated)
            }
            LCARSSection("Directional indicators") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Left to right").font(.callout)
                    LCARSActivityBand(.leftToRight, animated: animated).frame(height: 24)
                    Text("Right to left").font(.callout)
                    LCARSActivityBand(.rightToLeft, animated: animated).frame(height: 24)
                    HStack(alignment: .top, spacing: 28) {
                        VStack { Text("Up"); LCARSActivityBand(.bottomToTop, animated: animated).frame(width: 36, height: 130) }
                        VStack { Text("Down"); LCARSActivityBand(.topToBottom, animated: animated).frame(width: 36, height: 130) }
                        Spacer()
                    }.font(.callout)
                }
            }
            LCARSSection("Animate any view") {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 20) { animatedElbow; animatedButton }
                    VStack(alignment: .leading, spacing: 20) { animatedElbow; animatedButton }
                }
                Text("Button activations: \(counter)").font(.callout.monospacedDigit())
                Text("The modifier preserves the view’s action and accessibility. Scans follow its visible shape.")
                    .font(.callout).foregroundStyle(theme.mutedText.color)
            }
        }
    }
    private var animatedElbow: some View {
        LCARSElbow(metrics: .init(verticalArm: 72, horizontalArm: 24, outerRadius: 48, innerRadius: 32))
            .fill(theme.primary.color).frame(width: 200, height: 110)
            .lcarsAnimated(.scan(.topToBottom), enabled: animated)
            .accessibilityHidden(true)
    }
    private var animatedButton: some View {
        Button("Pulse / activate") { counter += 1 }.buttonStyle(.lcars(.secondary))
            .lcarsAnimated(.pulse, enabled: animated)
    }
}
