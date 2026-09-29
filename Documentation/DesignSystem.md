# Swift LCARS design proposal

This document preserves the original design proposal. The first SwiftUI implementation now ships; see [Getting Started](GettingStarted.md) for its actual API and supported features. Measurements are project decisions, not canonical LCARS specifications.

User-selected visual anchor: **TNG, warm, flat, screen-faithful intent**. The elbow and font are explicit first priorities. The rejected image-generation board is not an implementation reference. Use the outlined vector studies to review the next direction.

## Product principle

Make a useful app feel like LCARS. Preserve the elbow-and-rail composition while providing readable content, discoverable actions, stable navigation and native accessibility.

Support two presentation intents: everyday applications with generous readable content, and denser exhibition consoles. Both retain keyboard and accessibility support. Density must never override the user's text-size settings.

## Layers

1. **Foundations:** color roles, typography, spacing, geometry, motion and sound policy.
2. **Primitives:** elbow, rail, segment, end cap, divider and framed content region.
3. **Controls:** button styles, toggles, pickers, text fields, search and selection rows using native semantics.
4. **Compositions:** adaptive console, sidebar, section header, inspector and compact navigation.
5. **Data displays:** metrics, labeled meters, timelines, telemetry plots, schematic overlays and event logs.
6. **Recipes:** Observatory, media console, automation dashboard and system monitor examples.

Keep optional plotting and demonstration content out of the core dependency path. The initial implementation should be pure SwiftUI; use vector shapes for scalable geometry.

## Theme model

A theme contains palette, geometry and typography. Alert state is independent. Platform adaptation and information density are also independent.

Roles: `background`, `surface`, `textPrimary`, `textSecondary`, `framePrimary`, `frameSecondary`, `frameTertiary`, `actionFill`, `actionText`, `selection`, `focus`, `warning`, `critical`, `success`, plus an ordered chart series palette.

The JSON file supplies seed swatches, not a fully validated semantic theme. Resolve semantic foreground pairs deliberately. Separate destructive actions from visually orange decorative segments. Include a monochrome/high-contrast treatment.

Changing theme must preserve selection, focus, navigation and chart series identity. An alert changes a dedicated status region and optional frame accents; status remains explicit in text and symbols.

## Proposed geometry

| Token | Initial value / behavior |
| --- | --- |
| Base spacing unit | 4 pt |
| Frame gutter | 4 pt regular; 3 pt compact |
| Content spacing | 8 / 12 / 16 / 24 / 32 pt |
| Rail thickness | 24 pt regular; 16 pt compact, decorative only |
| Sidebar width | 176–240 pt, content-driven; collapses when needed |
| Outer elbow radius | Independently parameterized; form study starts at 72 pt |
| Inner elbow radius | Independently parameterized; form study starts at 48 pt |
| Capsule radius | Half rendered height |
| Touch action target | At least 44 × 44 pt; visible rail thickness is unrelated |
| Default content inset | 16 pt regular; 12 pt compact |

Implement elbow geometry as a continuous shape with explicit orientation and arm widths. LCARS' broad vertical arm and thin horizontal rail do not require concentric arcs. Specify independent inner and outer circular radii and tangent positions. The isolated form study uses a 144 pt vertical arm, 36 pt horizontal rail, outer radius 72 pt and inner radius 48 pt. These are a reviewable starting shape, not official measurements. Use true quarter-circle arcs with tangent horizontal/vertical joins, not an arbitrary quadratic curve or a stretched rounded rectangle. Clamp dimensions to the available rect and keep gaps aligned to the display scale.

Expose leading/trailing directions in layout APIs. Mirror the structure for right-to-left languages when appropriate; never reverse text or scientific charts automatically.

## Typography

Use semantic text styles that scale. Start body content at the platform's body style. Display typography must be an explicitly selected LCARS-appropriate face; a condensed system font is an accessibility fallback, not an accepted TNG fidelity substitute. The current vector studies use LCARS GTJ3 at natural glyph widths and regular weight. Never simulate authenticity by horizontally scaling a generic font. Uppercase display treatment must not alter underlying model strings or accessibility labels. Values should use tabular figures where the selected font supports them. Avoid forced single-line truncation for essential labels.

At large accessibility sizes, stack title and value, increase control height, and remove nonessential frame segments. Offer app-supplied display fonts without requiring them.

## Interaction contract

| State | Required visible behavior |
| --- | --- |
| Resting | Clear action label and consistent control shape |
| Hover | Subtle outline or luminance change; never the only affordance |
| Pressed | Immediate fill/outline response without moving neighboring content |
| Selected | Stable marker plus label or check; independent of hover |
| Focused | High-contrast focus outline, unobscured by rails |
| Disabled | Disabled semantics and distinct styling, with readable text |
| Busy | Named progress state; duplicate submission prevented where appropriate |
| Error | Plain-language message and available recovery action |

Decorative segments are hidden from accessibility. Readout groups have concise labels, values and units. Charts need summaries and an accessible data alternative. Avoid announcing every telemetry sample; announce meaningful transitions.

Keyboard activation, tab order, standard shortcuts, selection and context menus follow platform conventions. Use ButtonStyle and native Toggle/Picker/TextField behavior before inventing custom gesture controls.

Motion should explain state transitions. Initial proposal: 120–180 ms press/selection transitions and 200–300 ms section changes. Respect Reduce Motion. No random blinking in normal app mode. Sound is opt-in, event-based and supplied by the application; the package should not ship extracted television effects.

## Platform adaptation

| Platform | Composition and input |
| --- | --- |
| macOS | Resizable sidebar/content/inspector, keyboard navigation, menus, pointer and visible focus. Preserve native window controls. |
| iPadOS | Split content when space permits, touch targets, keyboard/pointer support and resizable-window adaptation. |
| iOS | Slim elbow header, one primary content column and compact navigation. Content scrolls naturally; do not shrink desktop consoles to fit. |
| watchOS | Single task/readout, short lists and restrained capsule cues; Crown support. Full console shell is inappropriate. |
| tvOS | Large labels and focusable groups with clear remote navigation. Avoid dense tiny telemetry. |
| visionOS | Legible window-based content with comfortable gaze targets. Explore immersive console environments separately. |

Choose layout from measured available space and content needs, not device names alone. Charts can pan or simplify while primary app controls remain reachable.

## Proposed developer experience

Original API sketch (see Getting Started for the implemented API; density and inspector parameters remain future work):

```swift
LCARSConsole(title: "Observatory") {
    ObservationList(observations)
} sidebar: {
    ObservatoryNavigation(selection: $selection)
} inspector: {
    ObservationDetails(selection)
}
.lcarsTheme(.classic)
.lcarsDensity(.comfortable)
.lcarsAlert(.normal)

Button("Start scan", action: startScan)
    .buttonStyle(.lcars(.primary))
```

The important promise is composability: an application can use one button style, a framed panel, or a whole console. Ordinary SwiftUI content can occupy every content slot.

## Implementation order

1. Create the Swift package with foundations, theme injection and shape primitives.
2. Build a native catalog showing all states, themes and compact/regular layouts.
3. Add native control styles and adaptive console composition.
4. Build an Observatory example with real selection, search, filtering and simulated data clearly labeled as such.
5. Add reusable plots/meters and document accessible alternatives.
6. Validate Mac/iPhone/iPad before extending the platform matrix.

## Acceptance criteria for implementation

- Geometry remains continuous at small sizes and differing arm widths.
- Text expansion, localization and large Dynamic Type sizes do not cover actions.
- Every action works with native input and VoiceOver semantics.
- Focus and selection remain distinguishable in every theme.
- Palette foreground pairs are measured for contrast, rather than inferred from swatches.
- Reduce Motion eliminates decorative motion, and sound starts off.
- Theme switching preserves application state.
- The library ships neither production screenshots nor proprietary fonts or audio.

The generated concept board was rejected. The replacement vector studies are still visual exploration, not screenshots of working code; they do not validate these acceptance criteria. Review the elbow silhouette, counter shape, rail joins and glyphs before implementing the rest of the catalog.
