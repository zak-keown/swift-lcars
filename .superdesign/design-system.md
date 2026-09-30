# SwiftLCARS / Dialogue Archive
Native SwiftUI iOS17/macOS14 library and sample. Canvas output is a visual reference, not production web code.
User chose the Dialogue Archive mockup in Design/AppConcepts/dialogue-archive.png. Preserve that direction.
Pure black #000, warm peach #FCC19F, lavender #BAA4E5, mauve #C082A9, amber #EB943A. NO gradients/glow/shadows/glass/cards.
Font: bundled unchanged LCARSGTJ3 for narrow uppercase labels and headings; system sans for long dialogue. Upload supplied TTF must be used. Do not substitute Antonio or generic wide text.
Geometry: broad spine144, rail36, outer quarter-circle72, independent inner48, gap6, tangent joins. Labels at segment ends. Headers aligned by cap height. SF symbols sized independently at16pt.
Desktop: search and filter rails over result list left / selected frame right; transport and scrubber below frame; lower connected elbow contains transcript.
iPhone: stacked search, selected frame, transport, results/transcript; real44pt touch targets, reflow not screenshot scaling.
App tasks: full text search, episode filter, select result, previous/next cue, timeline position, bookmarks, share transcript, import local SRT. Include no-match and no-media cases. Retain keyboard/VoiceOver support.
Fixture episodes are ORIGINAL: The Quiet Signal, Night Watch, Surface Detail. Fixture dialogue includes coffee, signal, probe. Use supplied original generated stills. Do not invent real episode metadata.
Shared components: elbow frame, search rail, result row, timeline, transcript panel. Decorative numeric motion opt-in, never randomize real data. Reduce Motion and background pause.
Keep franchise switching and sample navigation available but secondary. No fake system Dynamic Island.
