import SwiftUI

public enum LCARSControlRole: Sendable {
    case primary, secondary, accent, destructive
    public func fill(in theme: LCARSTheme) -> LCARSColor {
        switch self { case .primary: theme.primary; case .secondary: theme.secondary; case .accent: theme.accent; case .destructive: theme.critical }
    }
}

public struct LCARSButtonStyle: ButtonStyle {
    public var role: LCARSControlRole
    public var ends: LCARSSegment.Ends
    public var horizontalPadding: CGFloat
    public init(_ role: LCARSControlRole = .primary, ends: LCARSSegment.Ends = .both, horizontalPadding: CGFloat = 22) {
        self.role = role; self.ends = ends; self.horizontalPadding = horizontalPadding
    }
    public func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration, role: role, ends: ends, horizontalPadding: horizontalPadding)
    }

    private struct StyledButton: View {
        let configuration: Configuration
        let role: LCARSControlRole
        let ends: LCARSSegment.Ends
        let horizontalPadding: CGFloat
        @Environment(\.lcarsTheme) var theme
        @Environment(\.isEnabled) var enabled
        @Environment(\.isFocused) var focused
        @Environment(\.layoutDirection) var direction
        @Environment(\.accessibilityReduceMotion) var reduceMotion
        @State private var hovered = false
        var body: some View {
            let fill = role.fill(in: theme)
            let shape = LCARSSegment(ends, layoutDirection: direction)
            configuration.label
                .lcarsDisplay(27)
                .labelStyle(LCARSLabelStyle())
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
                .padding(.horizontal, horizontalPadding).padding(.vertical, 9)
                .frame(minWidth: 44, minHeight: 44)
                .foregroundStyle(fill.ink.color)
                .background(fill.color, in: shape)
                .overlay { shape.strokeBorderCompat(focused ? theme.text.color : .clear, width: 3) }
                .overlay { shape.fill(Color.black.opacity(configuration.isPressed ? 0.16 : 0)).allowsHitTesting(false) }
                .overlay { if hovered && enabled { shape.stroke(theme.text.color, lineWidth: 2).allowsHitTesting(false) } }
                .opacity(enabled ? 1 : 0.5)
                .contentShape(shape)
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

private extension Shape {
    func strokeBorderCompat(_ color: Color, width: CGFloat) -> some View {
        stroke(color, lineWidth: width).padding(-3).allowsHitTesting(false)
    }
}

public extension ButtonStyle where Self == LCARSButtonStyle {
    static func lcars(_ role: LCARSControlRole = .primary, ends: LCARSSegment.Ends = .both) -> Self {
        Self(role, ends: ends)
    }
}

/// Keeps the native button action and exposes selection independently of its color.
public struct LCARSNavigationButton: View {
    public let title: String
    public let isSelected: Bool
    public let minimumHeight: CGFloat
    public let action: () -> Void
    @Environment(\.lcarsTheme) private var theme
    public init(_ title: String, isSelected: Bool, minimumHeight: CGFloat = 58, action: @escaping () -> Void) {
        self.title = title; self.isSelected = isSelected; self.minimumHeight = minimumHeight; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if isSelected { Image(systemName: "chevron.right").font(.caption.bold()).accessibilityHidden(true) }
                Spacer(minLength: 0)
                Text(title).lcarsDisplay(24)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(minHeight: max(26, minimumHeight - 18))
        }
        .buttonStyle(LCARSButtonStyle(isSelected ? .primary : .secondary, ends: .square, horizontalPadding: 12))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public struct LCARSToggleStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 12) {
                configuration.label
                Spacer(minLength: 12)
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                Text(configuration.isOn ? "On" : "Off")
            }
        }
        .buttonStyle(.lcars(configuration.isOn ? .primary : .secondary, ends: .square))
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }.toggleStyle(.switch)
        }
    }
}

public extension ToggleStyle where Self == LCARSToggleStyle {
    static var lcars: Self { Self() }
}

public struct LCARSStatus: View {
    @Environment(\.lcarsTheme) private var theme
    @Environment(\.lcarsAlert) private var alert
    public init() {}
    public var body: some View {
        Label(alert.label, systemImage: alert.symbol)
            .font(.callout.weight(.medium))
            .foregroundStyle(alert.tint(in: theme).color)
            .accessibilityElement(children: .combine)
    }
}

/// Symbols use their own point size instead of inheriting the unusually tall
/// display font. Native Label titles keep the enclosing button's typography.
public struct LCARSLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .headline) private var symbolSize: CGFloat = 16
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 10) {
            configuration.icon.font(.system(size: symbolSize, weight: .medium))
                .accessibilityHidden(true)
            configuration.title
        }
    }
}
