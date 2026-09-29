# LCARS research

Research date: 2026-09-29. This is a source-backed starting point, not an exhaustive production archive.

## What is established

LCARS expands to Library Computer Access/Retrieval System. Michael Okuda developed its recognizable graphic language for Star Trek. His work spans TNG, DS9 and Voyager; the official 2011 iPad PADD app is a useful precedent for turning that language into an actual touch interface. [StarTrek.com: PADD app](https://www.startrek.com/videos/star-trek-padd-app-available-today), [Okudagram labels](https://www.startrek.com/news/collectible-usable-okudagrams-now-a-reality).

Andrew Jarvis's own Picard season-one portfolio credits his graphics work within the Twisted Media team with Chris Kieffer and Noah Schloss. Use it as a primary visual reference for that production, without assuming it specifies every subsequent Picard season. [Designer showreel](https://andrewjarvis.artstation.com/projects/yJ3X89).

I did not locate a public, authoritative, cross-series LCARS specification defining exact sRGB colors, radii, spacing, type sizes or real software behavior. Fan standards and recreations are useful implementation references, but their precision does not make them production standards. Dimensions proposed in this repository are ours.

## Visual grammar to preserve

The following is a design synthesis from LCARS references, not a quoted studio rulebook:

- Black negative space organizes the composition.
- Thick curved elbows connect vertical spines to horizontal rails.
- Colored segments are separated by crisp black gutters.
- Capsule ends and rectangular segments coexist; every panel need not be a rounded card.
- Condensed uppercase labels create a strong technical rhythm.
- Text frequently aligns with segment ends and structural edges.
- Graphics combine diagrams, numeric readouts, bar arrays and charts.
- Color is structural as well as informational; a lavender segment need not mean a specific system state.
- Classic treatments favor flat color. Avoid adding glow, gradients and glass effects by default.

Our app adaptation must distinguish decorative frame segments from interactive controls. Screen graphics alone are not evidence of usable interaction rules.

## Palette evidence and seeds

These subsets come from the independent [TheLCARS.com color guide](https://www.thelcars.com/colors.php), accessed on the research date. The author maintains and revises these themes; they are fan reconstructions, not official production RGB values. Role assignments are project proposals.

| Theme | Five seed colors |
| --- | --- |
| Classic | `#FCC19F` `#EB943A` `#BAA4E5` `#C082A9` `#8899FF` |
| Voyager | `#99CCFF` `#FFBB33` `#55A7FF` `#E98181` `#E6F2FF` |
| Nemesis Blue | `#6699FF` `#88BBFF` `#EBF0FF` `#99CC33` `#FFCC99` |
| Lower Decks | `#FFAA44` `#FF7700` `#FFEECC` `#FFCC99` `#FF4400` |
| Lower Decks PADD | `#5588EE` `#66CCFF` `#99CCFF` `#88EEFF` `#F3F3FC` |
| Picard | `#37A6D1` `#41C4F7` `#1C3C55` `#D2D5DF` `#FF6753` |

Background `#000000`, neutral text `#F5F5F7` and alert roles in the token file are project choices. Seed colors are not automatically suitable as small text or control backgrounds. Foreground/background pairing needs validation in the native catalog.

## Series and era coverage

| Production family | Treatment in this project | Confidence / remaining work |
| --- | --- | --- |
| The Next Generation | Classic is the initial warm/lavender seed | Production varies within the series; no universal exact palette established |
| Deep Space Nine | Start with Classic for Federation LCARS | A dedicated DS9 palette needs a named console/episode target |
| Voyager | Offer Classic and a cooler Voyager preset | A preset represents a visual direction, not all Voyager screens |
| TNG films | Nemesis Blue is a separate preset | Do not relabel it as a precise First Contact/Insurrection specification |
| Lower Decks | Separate console and PADD presets | Useful fan-source distinction; validate against chosen shots before claiming fidelity |
| Picard | Cyan/slate/coral seed, with season-specific references | Season-one designer source found; later-era variants need separate research |
| TOS / original films | Future sibling theme family | Research physical controls and earlier graphic styles independently |
| Enterprise | Future sibling theme family | Needs its own reference study, rather than recoloring a TNG frame |
| Discovery / Strange New Worlds | Future sibling theme families | Distinct periods and display languages require explicit targets |
| Prodigy | Future theme study | Do not invent a canonical palette without a supported reference set |

DS9 is especially easy to oversimplify. Its Starfleet and Cardassian displays are distinct reference subjects. [Ex Astris Scientia's monitor study](https://www.ex-astris-scientia.org/inconsistencies/monitors_ds9.htm) documents prop and display variations, including Sisko's early Cardassian monitor. Treat it as secondary production analysis.

## Typography

The recognizable quality is extreme horizontal compression and strong uppercase labeling. GTJLCARS identifies Helvetica Ultra Compressed as its original reference and publishes its own LCARS GTJ fonts. That is a fan author's attribution, not a verified universal production type specification. [GTJLCARS font reference](https://www.gtjlcars.de/LCARSindex/LCARSFONTS.htm).

Following the user's typography feedback, the visual studies use LCARS GTJ3, downloaded from its author's page and registered only inside the rendering process. Lettering is outlined for portable previews, without scaling glyph widths. The font binary is not included in this repository. Shipping display typography remains a decision; a condensed system face is only a fallback, not a claim of TNG fidelity. Keep editable text, long explanations and accessibility sizes readable. Prefer tabular figures for live values where supported.

The author permits use of GTJ3 and prohibits renaming, modifying or selling the font files. This project uses the unchanged TTF for rendering. [Author's font page and terms](https://www.gtjlcars.de/LCARSindex/LCARSFONTS.htm). No claim is made that this fan-designed face is the original production font.

## Apple implementation evidence

Apple recommends touch controls with targets of at least 44 × 44 points, layouts that fit their screens and clear text contrast. [UI Design Dos and Don'ts](https://developer.apple.com/design/tips/).

SwiftUI's native Button supplies action and accessibility semantics; icon-only visual labels can retain meaningful accessibility titles. Build LCARS styles on those controls. [SwiftUI Button](https://developer.apple.com/documentation/SwiftUI/Button).

System fonts support Dynamic Type and broad language coverage. Reserve specialized typography for places where it remains readable. [Apple fonts overview](https://developer.apple.com/documentation/technologyoverviews/fonts).

## Further references and open questions

- [Lou Huang's LCARS implementation](https://github.com/louh/lcars): responsive web precedent, not an Apple specification. Study concepts; do not import code without evaluating its license.
- [TheLCARS.com](https://www.thelcars.com/): useful living fan reference for layouts and theme variations.
- [Memory Alpha LCARS overview](https://memory-alpha.fandom.com/wiki/Library_Computer_Access_and_Retrieval_System): secondary reference for in-universe context and alert presentations.
- Build a reference index by production, season, episode, console and frame before claiming a screen-accurate theme.
- Record whether a future color is designer-supplied, sampled from footage, fan-published or project-authored. Sampled footage needs source and color-space metadata; a single frame cannot establish a production color standard.
- Remaining research: authenticated production style sheets, era-specific typography, later Picard consoles, non-Federation geometries and original audio design.
