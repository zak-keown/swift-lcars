# Dialogue Archive recipe

The sample opens to Archive on Mac, iPhone and iPad. It implements the selected
[Dialogue Archive concept](../Design/AppConcepts/dialogue-archive.png) in native
SwiftUI, alongside the science console and component galleries.

## Working features

- Live case-insensitive dialogue, speaker and episode-title search.
- Episode filter, result count and explicit no-match state.
- Result selection updates the still, caption, timestamp and transcript.
- Native timeline slider, previous/next cue navigation, and timed transcript playback.
- Saved lines persist locally. The Saved filter combines with the current search.
- Export shares the selected episode's full transcript as text.
- Import SRT accepts UTF-8 or UTF-16 text, with standard comma or dot millisecond
  timestamps. HTML-style subtitle tags are removed. Imported dialogue is copied
  into local sample storage; later launches do not need access to the source file.
- Import is bounded to 2 MB / 10,000 cues per transcript and 20 imported transcripts.
  Duplicate files are detected by SHA-256 and reopen the existing import.

The demo contains three original fictional stories and three imagegen stills.
It does not contain television episode footage. **Play transcript** advances
captions and the scrubber against their timestamps; it does not play video or
sound. One illustrative still represents each demo story. Imported transcripts
show an explicit no-media state. Attaching local video and extracting real frames
are future steps, not shipped capabilities.

Imports and bookmarks use app-local UserDefaults for this small recipe. A larger
archive should replace this with a database and full-text index. Query and playback
position are transient. Playback pauses on navigation or an inactive scene.

## Reusable library components

```swift
LCARSSearchField("Search dialogue", text: $query) { runSearch() }

LCARSTimeline(position: $seconds, duration: 120,
              cues: [0, 12, 28, 45]) { editing in
    if editing { pausePlayback() }
}

LCARSPanel("Transcript", identifier: "EPISODE 01") {
    // Native rows or any other SwiftUI content.
}
```

`LCARSSearchField` uses a native editable field and search submission. The timeline
uses a native accessible slider with decorative cue marks. The panel calculates
its secondary elbow and spine together, and content determines its height.

## Design artifacts

The [Superdesign canvas](https://superdesign.dev/teams/d6bf7272-b808-4594-89cb-9ed77f64920c/projects/c6db3c13-ecc7-4239-85aa-3628bb961a6a)
contains the chosen imagegen reference, a font Brand Asset, a reusable frame
component, and a [Gemini 3.1 Pro layout draft](https://p.superdesign.dev/draft/36c5fd42-acba-4794-a87b-d0e323c32f62).
The successful draft cost 20 credits. Canvas HTML is a separate visual study;
the native implementation follows the selected imagegen mockup and the existing
SwiftUI library. No web code is embedded in the app.

The demo images live in `Sources/LCARSCatalog/Resources`. Their exact built-in
imagegen prompts are recorded in [archive-frame-prompts.json](../Design/AppConcepts/archive-frame-prompts.json).

## Build and review

Both iOS and macOS targets compile. Desktop and iPhone renders were inspected;
that review caught and corrected an image loading/layout issue. Automated tests
were not added or run for this iteration. SRT import/export, persistence across
launches, full playback interaction, iPad layout, and full accessibility behavior
still need dedicated verification. The existing Live Activity is unchanged.


## iPhone Duo beta adaptation (2026-09-30)

Build `LCARSCatalog-Duo` with Xcode 27.1 beta and the `DuoDebug` configuration.
The configuration defines `LCARS_DUO_SDK`; regular Debug/Release builds keep their
older SDK compatibility. The deployment minimum remains iOS 17.

The iOS recipe uses horizontal size class rather than the desktop's fixed reference
canvas. In regular width it uses iOS 27.1 `ArrangementView` with split styling for
the player and dialogue index. In compact width the same view exposes Frame,
Results, and Transcript tabs. The ArchiveModel stays above layout changes, so
query, selected cue, playback position, and saved items share the same owner.
Playback controls remain outside the scrolling preview. Image height responds to
available container height. Native toolbar Labels let the system place controls
vertically, and foreground content retains the system's asymmetric safe areas.
The franchise deep link presents the native theme sheet in this configuration.

Sources:
- [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)
- [Strike a pose with adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/)
- [Raise the bar with iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111462/)

Verification: beta build and launch succeeded on the dedicated LCARS iPhone Duo
simulator; the outer display has been inspected. Inner-display, partial-fold,
Split View, and continuity checks remain pending: Device Hub UI automation timed
out. This is beta sample support, not a completed production-readiness claim.
