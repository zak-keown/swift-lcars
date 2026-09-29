# Visual studies

`elbow-type.png` is the focused review target. `tng-console.png` shows those ideas in a larger composition.

The `*-study.svg` files contain editable text. They require the separately obtained LCARSGTJ3 font to display correctly. The `*-outlined.svg` files contain rendered glyph outlines and display without installing fonts. PNGs are previews of those outlined files.

Font reference: [GTJLCARS font page](https://www.gtjlcars.de/LCARSindex/LCARSFONTS.htm). Download the author's archive and retain its font filenames unchanged. The font is not bundled, installed globally, or modified here. `outline-study.swift` registers it only for its own process and renders the text to vector paths using CoreText. This utility supports these controlled study inputs; it is not a general SVG text engine.

Example after separately downloading the font:

```sh
swift Design/outline-study.swift Design/elbow-type-study.svg /path/to/LCARSGTJ3.ttf Design/elbow-type-outlined.svg
```

The first image-generation board was rejected. Its prompt is retained as process context; the generated bitmap is not a project asset. The chosen direction is warm, flat TNG with elbow and typography fidelity prioritized. All geometry dimensions are project proposals pending reference comparison and review.
