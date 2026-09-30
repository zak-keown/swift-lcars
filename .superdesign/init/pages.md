# Component dependency trees

Swift files resolve by module; no per-file import paths.

CatalogApp.swift
- CatalogView.swift
  - ObservatoryView.swift
  - Galleries.swift
  - LiveActivityController.swift (iOS only)
    - LCARSActivityAttributes.swift
  - SwiftLCARS module
    - Composition.swift -> Geometry.swift, Theme.swift, Typography.swift
    - Controls.swift -> Geometry.swift, Theme.swift, Typography.swift
    - DataDisplays.swift -> Theme.swift, Typography.swift
    - Sequence.swift -> Animation.swift (LCARSNoise), Theme.swift, Typography.swift
    - Animation.swift -> Theme.swift, Typography.swift

New target Dialogue Archive will reuse the console, controls, fonts and theme. Closest sibling is ObservatoryView, with a two-column responsive instrument composition.
