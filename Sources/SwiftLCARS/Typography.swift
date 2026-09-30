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
