# Swift LCARS

A design system for building rich, native LCARS-inspired apps on Apple platforms.

**Status: research and design foundation.** No Swift package or working app ships yet. The proposed API and dimensions are design decisions to evaluate in a native component catalog.

The aim is a recognizable LCARS visual language—sweeping elbows, segmented rails, capsule controls, expressive color and technical data displays—with native navigation, accessible controls and layouts that adapt to their content.

## Start here

- [Research and source provenance](Documentation/Research.md)
- [Design system proposal](Documentation/DesignSystem.md)
- [Machine-readable palette seeds](Design/palettes.json)
- [Concept generation brief](Design/ConceptPrompt.txt)

## Selected direction: TNG

Warm, flat TNG-inspired LCARS is the visual anchor. Elbow geometry and typography are the first acceptance gates. The initial generated concept was rejected; the studies below replace it with explicit vector geometry and LCARS GTJ3 lettering at its natural widths.

![Elbow and typography specimen](Design/elbow-type.png)

- [Scalable elbow/type specimen](Design/elbow-type-outlined.svg)
- [Console composition study](Design/tng-console.png)
- [Scalable console study](Design/tng-console-outlined.svg)

These are original static studies, not screenshots of a working app or exact reproductions of a production console. Dimensions remain proposals. The font is a fan-designed reference face; shipping typography is not yet finalized.

## Planned first release

Start with macOS, iOS and iPadOS: a SwiftUI package, six visual themes, native control styles, adaptive console layouts and an Observatory example app. Expand to watchOS, tvOS and visionOS after their interaction models have dedicated examples.

Era styling, interaction state and information density are independent choices. An alert must not change a control's meaning, and changing a theme must not change an app's behavior.

## Attribution

LCARS was created by Michael Okuda for Star Trek. This is an independent, unofficial project. References are linked, not redistributed. The palette file identifies fan-source values and project-defined role assignments separately; none is presented as an official studio specification.
