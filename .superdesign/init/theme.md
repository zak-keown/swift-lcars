# Theme tokens

SwiftUI, no CSS. Pure black; peach FCC19F; lavender BAA4E5; mauve C082A9; amber EB943A. GTJ3 natural condensed glyphs. Native system body. Spine144 rail36 outer72 inner48 gap6. No gradients or shadows. Compact threshold760.

## Sources/SwiftLCARS/Theme.swift
```swift
import SwiftUI

/// An opaque sRGB token. Color roles remain independent of era names.
public struct LCARSColor: Hashable, Sendable {
    public let hex: UInt32
    public init(_ hex: UInt32) { self.hex = hex & 0xFFFFFF }
    public var red: Double { Double((hex >> 16) & 255) / 255 }
    public var green: Double { Double((hex >> 8) & 255) / 255 }
    public var blue: Double { Double(hex & 255) / 255 }
    public var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }
    public var luminance: Double {
        func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
    public func contrast(with other: Self) -> Double {
        (max(luminance, other.luminance) + 0.05) / (min(luminance, other.luminance) + 0.05)
    }
    /// Chooses the higher-contrast opaque foreground for a filled segment.
    public var ink: Self { contrast(with: .black) >= contrast(with: .white) ? .black : .white }
    public static let black = Self(0x000000)
    public static let white = Self(0xFFFFFF)
}

/// Fan-source palette seeds with project-defined, contrast-conscious roles.
public struct LCARSTheme: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var primary: LCARSColor
    public var secondary: LCARSColor
    public var tertiary: LCARSColor
    public var accent: LCARSColor
    public var background: LCARSColor
    public var text: LCARSColor
    public var mutedText: LCARSColor
    public var critical: LCARSColor
    public var warning: LCARSColor
    public var success: LCARSColor

    public init(id: String, name: String, primary: LCARSColor, secondary: LCARSColor,
                tertiary: LCARSColor, accent: LCARSColor, background: LCARSColor = .black,
                text: LCARSColor = .init(0xF5F5F7), mutedText: LCARSColor = .init(0xC6BCD0),
                critical: LCARSColor = .init(0xFF6565), warning: LCARSColor = .init(0xFFCC66),
                success: LCARSColor = .init(0xA7D8B0)) {
        self.id = id; self.name = name
        self.primary = primary; self.secondary = secondary; self.tertiary = tertiary
        self.accent = accent; self.background = background; self.text = text
        self.mutedText = mutedText; self.critical = critical; self.warning = warning; self.success = success
    }

    public static let classic = Self(id: "classic", name: "Classic / TNG", primary: .init(0xFCC19F), secondary: .init(0xBAA4E5), tertiary: .init(0xC082A9), accent: .init(0xEB943A))
    public static let voyager = Self(id: "voyager", name: "Voyager", primary: .init(0x99CCFF), secondary: .init(0xFFBB33), tertiary: .init(0x55A7FF), accent: .init(0xE98181))
    public static let nemesis = Self(id: "nemesis", name: "Nemesis Blue", primary: .init(0x6699FF), secondary: .init(0x88BBFF), tertiary: .init(0xEBF0FF), accent: .init(0x99CC33))
    public static let lowerDecks = Self(id: "lowerDecks", name: "Lower Decks", primary: .init(0xFFAA44), secondary: .init(0xFFCC99), tertiary: .init(0xFFEECC), accent: .init(0xFF7700))
    public static let lowerDecksPADD = Self(id: "lowerDecksPADD", name: "Lower Decks PADD", primary: .init(0x66CCFF), secondary: .init(0x99CCFF), tertiary: .init(0x5588EE), accent: .init(0x88EEFF))
    public static let picard = Self(id: "picard", name: "Picard", primary: .init(0x37A6D1), secondary: .init(0xD2D5DF), tertiary: .init(0x41C4F7), accent: .init(0xFF6753))
    public static let highContrast = Self(id: "highContrast", name: "High contrast", primary: .white, secondary: .init(0xFFFF99), tertiary: .white, accent: .init(0x99DDFF), text: .white, mutedText: .white)
    public static let presets: [Self] = [.classic, .voyager, .nemesis, .lowerDecks, .lowerDecksPADD, .picard, .highContrast]
}

public enum LCARSAlert: String, CaseIterable, Identifiable, Sendable {
    case normal, caution, critical
    public var id: Self { self }
    public var label: String {
        switch self { case .normal: "Systems normal"; case .caution: "Caution"; case .critical: "Critical alert" }
    }
    public var symbol: String {
        switch self { case .normal: "checkmark.circle"; case .caution: "exclamationmark.triangle"; case .critical: "exclamationmark.octagon" }
    }
    public func tint(in theme: LCARSTheme) -> LCARSColor {
        switch self { case .normal: theme.success; case .caution: theme.warning; case .critical: theme.critical }
    }
}

private struct ThemeKey: EnvironmentKey { static let defaultValue = LCARSTheme.classic }
private struct AlertKey: EnvironmentKey { static let defaultValue = LCARSAlert.normal }
private struct CompactKey: EnvironmentKey { static let defaultValue = false }
public extension EnvironmentValues {
    var lcarsTheme: LCARSTheme { get { self[ThemeKey.self] } set { self[ThemeKey.self] = newValue } }
    var lcarsAlert: LCARSAlert { get { self[AlertKey.self] } set { self[AlertKey.self] = newValue } }
    /// Set by LCARSConsole; custom sidebar content can adapt to compact composition.
    var lcarsIsCompact: Bool { get { self[CompactKey.self] } set { self[CompactKey.self] = newValue } }
}
public extension View {
    func lcarsTheme(_ theme: LCARSTheme) -> some View { environment(\.lcarsTheme, theme) }
    func lcarsAlert(_ alert: LCARSAlert) -> some View { environment(\.lcarsAlert, alert) }
}

```

## Sources/SwiftLCARS/Typography.swift
```swift
import SwiftUI
import CoreText

public enum LCARSFontMode: String, CaseIterable, Sendable {
    case authentic, readable
}

public enum LCARSTypography {
    /// Registration is process-scoped, lazy, and performed once. The font file is unchanged.
    public static let isDisplayFontAvailable: Bool = {
        guard let url = Bundle.module.url(forResource: "LCARSGTJ3", withExtension: "ttf") else { return false }
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) { return true }
        // A host may already have registered this font.
        let names = CTFontManagerCopyAvailablePostScriptNames() as! [String]
        return names.contains("LCARSGTJ3")
    }()

    /// Font metrics for aligning the visible uppercase letters with a rail.
    public static func capHeight(at size: CGFloat) -> CGFloat {
        _ = isDisplayFontAvailable
        let font = CTFontCreateWithName((isDisplayFontAvailable ? "LCARSGTJ3" : "HelveticaNeue-CondensedBold") as CFString, size, nil)
        return CTFontGetCapHeight(font)
    }

    public static func size(forCapHeight height: CGFloat) -> CGFloat {
        max(1, height) / max(0.01, capHeight(at: 1))
    }

    public static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .headline) -> Font {
        if isDisplayFontAvailable { return .custom("LCARSGTJ3", size: size, relativeTo: style) }
        return .system(style, design: .default).weight(.semibold)
    }
}

private struct FontModeKey: EnvironmentKey { static let defaultValue = LCARSFontMode.authentic }
public extension EnvironmentValues {
    var lcarsFontMode: LCARSFontMode { get { self[FontModeKey.self] } set { self[FontModeKey.self] = newValue } }
}

private struct DisplayType: ViewModifier {
    @Environment(\.lcarsFontMode) var mode
    @Environment(\.dynamicTypeSize) var typeSize
    let size: CGFloat
    let style: Font.TextStyle
    func body(content: Content) -> some View {
        content.font(mode == .readable || typeSize.isAccessibilitySize
                     ? .system(style).weight(.semibold)
                     : LCARSTypography.display(size, relativeTo: style))
    }
}

public extension View {
    /// Uses natural glyph widths. Accessibility sizes use the readable system face.
    func lcarsDisplay(_ size: CGFloat = 26, relativeTo style: Font.TextStyle = .headline) -> some View {
        modifier(DisplayType(size: size, style: style))
    }
    func lcarsFontMode(_ mode: LCARSFontMode) -> some View { environment(\.lcarsFontMode, mode) }
}

```