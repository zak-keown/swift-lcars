# TNG science console

The Observatory is an original working TNG-style science console, grounded in the
approved `Design/tng-console-study.svg`. It is not an episode-matched replica.

## Evidence and boundaries

- [Mike and Denise Okuda's 1999 interview](https://trektoday.com/interviews/okuda_qa.shtml)
  explains the intent to organize complicated information clearly, the use of
  Illustrator for static panels and Director for animation, and the additional
  work needed to make an actual usable interface. These statements inform the
  emphasis on composition and task behavior rather than invented canonical rules.
- [StarTrek.com's Okudagram article](https://www.startrek.com/news/collectible-usable-okudagrams-now-a-reality)
  attributes LCARS and the capsule identification labels to Okuda's production work.
- Palette seeds remain fan reconstructions from TheLCARS.com; GTJ3 remains a fan
  font. Sources and terms are in [Research](Research.md) and the third-party notice.
- No newly authenticated studio measurements were found. Elbow dimensions,
  spacing, spectrum data, orbital positions, and motion timings are authored here.
  A future screen-accuracy claim needs a named episode/console and frame-level comparison.

## Composition

The outer spine is 144 points wide, with a 36-point horizontal rail, independent
72/48-point elbow radii, and 6-point black gutters. `LCARSFrameMetrics` supplies
those dimensions to the elbow, spine, and rails together. The compact PADD uses a
36-point arm and 12-point rail. The existing theme palettes remain interchangeable;
this iteration does not claim separate canon layouts for each franchise.

The wide science surface has an annotated sensor map on the left and sensor
resolution, normalized spectrum, and scan controls on the right. Instrument
headers, identifiers, numeric banks, and annotations use the bundled condensed
face at natural glyph widths. Long explanations use native text.

The iPhone surface stacks the instruments and offers a target menu and scan control
above the map. Targets can also be filtered and selected from the directory.
Selection updates the map, range, and spectrum together. A three-second simulation
records completed scans; cancellation creates no completed record. Selection is
locked during acquisition. Export contains completed records only. The log keeps
the latest five records in memory for the current sample screen session.

## Motion

A shared sequence clock drives the sidebar, numerical banks, and indicator tracks.
Idle banks update slowly, with staggered row groups; scanning accelerates the
sequence. Indicators advance, hold, reverse, and hold. All widgets opt in
individually. Global pause, Reduce Motion, and inactive scene handling remain in
place. The new clock retains its elapsed position across pause/resume.

The Motion gallery exposes idle, scanning, processing, and alert presets. Existing
continuous scan and pulse effects remain available for applications that want them.
Decorative motion is hidden from accessibility and never changes scan measurements.

## Build and review status

The updated iOS and macOS targets build successfully. The initial wide Mac and
compact iPhone renders were inspected for composition and typography. No automated
tests were added or run for this iteration. Full accessibility interaction checks,
iPad-specific visual review, and the complete Dynamic Island interaction remain
outstanding. The Live Activity implementation was not changed in this iteration.

## Desktop alignment follow-up

The console title now uses the bundled font’s measured cap height to match the
horizontal rail; alignment uses the text baseline rather than the full ascender
box. `LCARSLabelStyle` gives SF Symbols their own scaled point size, preventing
ShareLink icons from inheriting the tall display font. The corrected desktop
render was inspected, and both app targets rebuilt successfully.
