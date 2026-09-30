# Build LCARS apps with SwiftUI

Requires Swift 5.9 or later, macOS 14 or iOS/iPadOS 17 or later. The library has no external package dependencies.

## Add the package

In Xcode, add `https://github.com/zak-keown/swift-lcars` as a package dependency and select the **SwiftLCARS** product. Until a release is tagged, use the `main` branch.

```swift
import SwiftUI
import SwiftLCARS

struct ControlRoom: View {
    @State private var selected = "Sensors"

    var body: some View {
        LCARSConsole(title: "Control room") {
            ScrollView {
                LCARSSection("Sensor status") {
                    LCARSReadout("Range", value: "4.72", unit: "AU")
                    LCARSMeter("Capacity", value: 0.72)
                    Button("Run scan") { /* start your operation */ }
                        .buttonStyle(.lcars(.primary))
                }
            }
        } sidebar: {
            LCARSNavigationButton("Sensors", isSelected: selected == "Sensors") {
                selected = "Sensors"
            }
        }
        .lcarsTheme(.classic)
    }
}
```

`LCARSConsole` supplies the frame and adapts the sidebar to available width. Your content owns its scrolling. Sidebar content can read `@Environment(\.lcarsIsCompact)` to choose a compact picker or wider navigation buttons. On large accessibility text sizes the console uses its compact composition.

## Use individual components

```swift
LCARSElbow(
    .topLeading,
    metrics: .init(verticalArm: 144, horizontalArm: 36,
                   outerRadius: 72, innerRadius: 48)
)
.fill(LCARSTheme.classic.primary.color)
.frame(width: 280, height: 180)

Button("Archive", action: archive)
    .buttonStyle(.lcars(.secondary, ends: .trailing))

Toggle("Sensor telemetry", isOn: $telemetry)
    .toggleStyle(.lcars)

Text("Library computer access")
    .lcarsDisplay(46, relativeTo: .largeTitle)
```

The elbow uses independent inner/outer circular radii. It clamps invalid or oversized metrics to the available bounds. For a standalone shape in a right-to-left layout, pass the SwiftUI environment's `layoutDirection`; the console handles this itself. Radii and dimensions are project-defined, based on the approved visual specimen.

LCARS GTJ3 is included unchanged and registered lazily inside the app process. It is never installed on the user's system. See [third-party terms](../THIRD-PARTY-NOTICES.md). `.lcarsFontMode(.readable)` switches display labels to system type; accessibility text sizes also use system type. Long prose should use native semantic fonts.

## Themes and status

Presets: `.classic`, `.voyager`, `.nemesis`, `.lowerDecks`, `.lowerDecksPADD`, `.picard`, plus `.highContrast`. These are interpretive palettes, not official production color specifications.

Construct an `LCARSTheme` to supply your own colors. `LCARSColor` exposes relative luminance and a contrast ratio function; its `ink` property selects black or white for solid control fills. Default text pairs are tested at 4.5:1 or better. Custom themes remain the consuming app's responsibility.

`.lcarsAlert(.caution)` or `.lcarsAlert(.critical)` changes status accents. Place `LCARSStatus()` in your interface to display an explicit status label and symbol. Theme and alert changes do not replace your application state.

## Optional animation

Everything is static until explicitly opted in:

```swift
LCARSNumberGrid(columns: 6, rows: 3, animated: true)

LCARSActivityBand(.leftToRight, animated: true)
    .frame(height: 18)

LCARSActivityBand(.bottomToTop, animated: true)
    .frame(width: 32, height: 120)

LCARSElbow()
    .fill(LCARSTheme.classic.primary.color)
    .frame(width: 280, height: 160)
    .lcarsAnimated(.scan(.topToBottom))

Button("Engage", action: engage)
    .buttonStyle(.lcars())
    .lcarsAnimated(.pulse)
```

Directions include left-to-right, right-to-left, top-to-bottom and bottom-to-top. A `period` parameter controls scan speed. `.lcarsMotionEnabled(false)` pauses all LCARS decorative animation below that view. Reduce Motion and inactive scene phases also pause it. No animation timer runs in a library view that has not opted in.

The number grid contains synthetic decorative values and is hidden from accessibility. Real meter values, button labels and readouts never become random. Modifier overlays are noninteractive and hidden from accessibility; they preserve the original action and value. Do not substitute ambient motion for actual progress reporting.

## Run the published sample

Open `LCARSCatalog.xcodeproj`:

- **LCARSCatalog-macOS** runs the Mac app.
- **LCARSCatalog-iOS** runs on iPhone or iPad and embeds the Live Activity extension.

The generated project is checked in, so XcodeGen is optional. To regenerate after editing `project.yml`, run `xcodegen generate`.

For a quick Mac launch without Xcode:

```sh
swift run LCARSCatalog
```

The sample offers a functional simulated scan, target selection, filtering and export; an elbow/typography/control catalog; and an ambient motion gallery. Theme selection, readable type and ambient-motion preferences persist locally.

## Dynamic Island

On an iPhone with Dynamic Island, tap **Start Live Activity** (the capsule icon in the sample toolbar). The activity displays the selected franchise. Tap the system Island to reopen the app with the franchise popover already open. Touch and hold the Island to see its expanded presentation and **Change franchise** link. The same deep link works from the Lock Screen.

The route is `swiftlcars://themes`. Theme changes update the running ActivityKit activity. Tap **End Live Activity** to dismiss it. If the OS disables Live Activities, the app reports that state rather than pretending to start one.

This is a real ActivityKit/WidgetKit extension. It does not draw a fake system Island. iOS launches the app for the picker; there is no arbitrary dropdown layered over system UI. Ambient animation runs inside the app, not as a continuous Live Activity timer. See [Apple's Live Activity deep-link documentation](https://developer.apple.com/documentation/activitykit/launching-your-app-from-a-live-activity).

For simulator review, this project was developed using a dedicated **LCARS iPhone 18 Pro** device running the installed iOS 27 runtime. Other iOS 17+ devices remain supported; hardware profile names are not hard-coded into app behavior. Device installation requires your own signing team in Xcode.

## Scope

Both sample app targets build successfully. The initial seven library tests passed during development. The simulator UI checks exercised franchise selection and Live Activity creation; the complete Island-to-picker-and-dismissal flow remains unconfirmed after the latest lifecycle changes.

This is an initial implementation for Mac, iPhone and iPad. watchOS, tvOS and visionOS-specific composition, app-supplied font families, advanced plotting and full VoiceOver/keyboard audits remain future work. The catalog's charts are illustrative; library controls keep native semantics. No television screenshots or audio effects are included.

## Coordinated console motion

Use one `LCARSSequence` around related displays. It supplies a shared 4 Hz clock;
individual widgets still opt in. Numeric banks refresh in staggered groups and
indicator tracks advance, hold, reverse, and hold again.

```swift
LCARSSequence(isScanning ? .scanning : .idle, animated: true) {
    VStack(spacing: 12) {
        LCARSInstrumentHeader("Long range sensors", identifier: "SCI 04")
        LCARSDataBank(columns: 5, rows: 3, seed: 1701, animated: true)
        LCARSIndicatorTrack(.leftToRight, count: 16, animated: true)
            .frame(height: 12)
    }
}
```

Modes are `.idle`, `.scanning`, `.processing`, and `.alert`. These are authored
choreography presets, not canonical production timings. The sequence preserves
its elapsed position when paused and suspends while offscreen, inactive, or under
Reduce Motion. Its children are static outside a sequence. For custom displays,
read `@Environment(\.lcarsSequence)` and use its `tick`, `mode`,
`generation(forBank:)`, or `activeSegment(count:)`. Avoid binding real measurements
to this decorative clock.

`LCARSFrameMetrics` connects the outer elbow, sidebar width, rail thickness,
gutters, and content inset. Pass custom metrics to `LCARSConsole(title:metrics:)`;
the default `.console` preserves the approved study proportions. Narrow layouts
use the compact PADD treatment. `LCARSInstrumentHeader` places a readable title
within a segmented rule without fixing text height.

`LCARSSpectrum(samples:label:summary:)` draws normalized samples in `0...1`.
It clamps out-of-range values and maps non-finite samples to zero. Supply an
accessible summary describing the actual data and units; the sample app uses
explicitly illustrative spectra.

See [Science console](ScienceConsole.md) for the sample's composition and provenance.

## Dialogue Archive recipe

The sample now opens to **Archive**: search original demo dialogue, select a frame,
move through transcript cues, save lines, share a transcript, or import an SRT file.
`LCARSSearchField`, `LCARSTimeline`, and `LCARSPanel` are reusable library components.
See [Dialogue Archive](DialogueArchive.md) for behavior, API examples and limitations.
