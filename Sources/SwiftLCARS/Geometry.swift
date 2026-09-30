import SwiftUI

/// Independent arm widths and circular radii, matching the approved form study.
public struct LCARSElbowMetrics: Equatable, Sendable {
    public var verticalArm: CGFloat
    public var horizontalArm: CGFloat
    public var outerRadius: CGFloat
    public var innerRadius: CGFloat
    public init(verticalArm: CGFloat = 144, horizontalArm: CGFloat = 36,
                outerRadius: CGFloat = 72, innerRadius: CGFloat = 48) {
        self.verticalArm = verticalArm; self.horizontalArm = horizontalArm
        self.outerRadius = outerRadius; self.innerRadius = innerRadius
    }
    public static let reference = Self()
    public static let compact = Self(verticalArm: 36, horizontalArm: 12, outerRadius: 28, innerRadius: 16)

    public func resolved(in size: CGSize) -> Self {
        func positive(_ n: CGFloat) -> CGFloat { n.isFinite ? max(0, n) : 0 }
        let w = positive(size.width), h = positive(size.height)
        let v = min(positive(verticalArm), w), rail = min(positive(horizontalArm), h)
        return Self(verticalArm: v, horizontalArm: rail,
                    outerRadius: min(positive(outerRadius), v, h),
                    innerRadius: min(positive(innerRadius), w - v, h - rail))
    }
}

public struct LCARSElbow: Shape {
    public enum Corner: CaseIterable, Sendable { case topLeading, topTrailing, bottomLeading, bottomTrailing }
    public var corner: Corner
    public var metrics: LCARSElbowMetrics
    public var layoutDirection: LayoutDirection
    public init(_ corner: Corner = .topLeading, metrics: LCARSElbowMetrics = .reference,
                layoutDirection: LayoutDirection = .leftToRight) {
        self.corner = corner; self.metrics = metrics; self.layoutDirection = layoutDirection
    }

    public func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0, rect.width.isFinite, rect.height.isFinite else { return Path() }
        let m = metrics.resolved(in: rect.size)
        let v = m.verticalArm, h = m.horizontalArm, outer = m.outerRadius, inner = m.innerRadius
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: outer))
        if outer > 0 {
            p.addArc(center: CGPoint(x: outer, y: outer), radius: outer,
                     startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: h))
        p.addLine(to: CGPoint(x: v + inner, y: h))
        if inner > 0 {
            p.addArc(center: CGPoint(x: v + inner, y: h + inner), radius: inner,
                     startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
        }
        p.addLine(to: CGPoint(x: v, y: rect.height))
        p.closeSubpath()
        let trailing = corner == .topTrailing || corner == .bottomTrailing
        let flipX = trailing != (layoutDirection == .rightToLeft)
        let flipY = corner == .bottomLeading || corner == .bottomTrailing
        return p.applying(CGAffineTransform(a: flipX ? -1 : 1, b: 0, c: 0, d: flipY ? -1 : 1,
                                           tx: flipX ? rect.maxX : rect.minX, ty: flipY ? rect.maxY : rect.minY))
    }
}

public struct LCARSSegment: Shape {
    public enum Ends: Sendable { case square, leading, trailing, both }
    public var ends: Ends
    public var layoutDirection: LayoutDirection
    public init(_ ends: Ends = .square, layoutDirection: LayoutDirection = .leftToRight) {
        self.ends = ends; self.layoutDirection = layoutDirection
    }
    public func path(in rect: CGRect) -> Path {
        let radius = max(0, min(rect.width, rect.height) / 2)
        let leading: CGFloat = ends == .leading || ends == .both ? radius : 0
        let trailing: CGFloat = ends == .trailing || ends == .both ? radius : 0
        let left = layoutDirection == .leftToRight ? leading : trailing
        let right = layoutDirection == .leftToRight ? trailing : leading
        return UnevenRoundedRectangle(topLeadingRadius: left, bottomLeadingRadius: left,
                                      bottomTrailingRadius: right, topTrailingRadius: right,
                                      style: .circular).path(in: rect)
    }
}

/// Shared dimensions keep the spine, elbow, rail and content edge aligned.
/// Values derive from the project's approved TNG study, not a studio style sheet.
public struct LCARSFrameMetrics: Equatable, Sendable {
    public var elbow: LCARSElbowMetrics
    public var gutter: CGFloat
    public var contentInset: CGFloat
    public init(elbow: LCARSElbowMetrics = .reference, gutter: CGFloat = 6, contentInset: CGFloat = 26) {
        self.elbow = elbow
        self.gutter = gutter.isFinite ? max(0, gutter) : 6
        self.contentInset = contentInset.isFinite ? max(0, contentInset) : 26
    }
    public static let console = Self()
    /// Dense application chrome, retaining circular elbows and a continuous sidebar.
    public static let workstation = Self(elbow: .init(verticalArm: 120, horizontalArm: 24,
                                                     outerRadius: 48, innerRadius: 24),
                                         gutter: 6, contentInset: 18)
    public static let padd = Self(elbow: .compact, gutter: 4, contentInset: 12)
    public var elbowWidth: CGFloat { elbow.verticalArm + elbow.innerRadius }
    public var headerHeight: CGFloat { max(elbow.outerRadius, elbow.horizontalArm + elbow.innerRadius) + 20 }
    public var footerHeight: CGFloat { max(elbow.outerRadius, elbow.horizontalArm + elbow.innerRadius) }
}
