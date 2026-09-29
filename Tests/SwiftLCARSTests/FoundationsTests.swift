import XCTest
import SwiftUI
import CoreText
@testable import SwiftLCARS

final class FoundationsTests: XCTestCase {
    func testApprovedElbowSilhouette() {
        let path = LCARSElbow().path(in: CGRect(x: 0, y: 0, width: 512, height: 268))
        // Reference arm interior, horizontal rail, and genuine concave counter.
        XCTAssertTrue(path.contains(CGPoint(x: 70, y: 200)))
        XCTAssertTrue(path.contains(CGPoint(x: 400, y: 18)))
        XCTAssertFalse(path.contains(CGPoint(x: 400, y: 100)))
        XCTAssertFalse(path.contains(CGPoint(x: 2, y: 2)))
        XCTAssertTrue(path.contains(CGPoint(x: 72, y: 3)))
        XCTAssertFalse(path.contains(CGPoint(x: 193, y: 85)))
        XCTAssertTrue(path.contains(CGPoint(x: 145, y: 38)))
    }

    func testElbowMirroringAndNonzeroOrigin() {
        let rect = CGRect(x: 20, y: 30, width: 320, height: 200)
        let leading = LCARSElbow().path(in: rect)
        let trailing = LCARSElbow(.topTrailing).path(in: rect)
        let rtl = LCARSElbow(layoutDirection: .rightToLeft).path(in: rect)
        let bottom = LCARSElbow(.bottomLeading).path(in: rect)
        for x in stride(from: 25.0, to: 335.0, by: 17) {
            for y in stride(from: 35.0, to: 225.0, by: 19) {
                let p = CGPoint(x: x, y: y)
                let expected = leading.contains(p)
                XCTAssertEqual(expected, trailing.contains(CGPoint(x: rect.minX + rect.maxX - x, y: y)))
                XCTAssertEqual(expected, bottom.contains(CGPoint(x: x, y: rect.minY + rect.maxY - y)))
                XCTAssertEqual(trailing.contains(p), rtl.contains(p))
            }
        }
    }

    func testDegenerateAndTinyElbowsStayBounded() {
        for size in [CGSize.zero, CGSize(width: 1, height: 1), CGSize(width: 30, height: 12), CGSize(width: 500, height: 500)] {
            let m = LCARSElbowMetrics(verticalArm: .infinity, horizontalArm: -4, outerRadius: .nan, innerRadius: 10000)
            let resolved = m.resolved(in: size)
            XCTAssertTrue(resolved.outerRadius.isFinite)
            XCTAssertLessThanOrEqual(resolved.innerRadius, size.width)
            XCTAssertLessThanOrEqual(resolved.innerRadius, size.height)
            for corner in LCARSElbow.Corner.allCases {
                let path = LCARSElbow(corner, metrics: .reference).path(in: CGRect(origin: .zero, size: size))
                if !path.isEmpty {
                    XCTAssertGreaterThanOrEqual(path.boundingRect.minX, -0.001)
                    XCTAssertGreaterThanOrEqual(path.boundingRect.minY, -0.001)
                    XCTAssertLessThanOrEqual(path.boundingRect.maxX, size.width + 0.001)
                    XCTAssertLessThanOrEqual(path.boundingRect.maxY, size.height + 0.001)
                }
            }
        }
    }

    func testDefaultPaletteTextPairsMeetNormalTextContrast() {
        for theme in LCARSTheme.presets {
            for fill in [theme.primary, theme.secondary, theme.tertiary, theme.accent, theme.critical] {
                XCTAssertGreaterThanOrEqual(fill.contrast(with: fill.ink), 4.5, theme.name)
            }
            for foreground in [theme.text, theme.mutedText, theme.primary, theme.secondary, theme.success, theme.warning, theme.critical] {
                XCTAssertGreaterThanOrEqual(foreground.contrast(with: theme.background), 4.5, theme.name)
            }
        }
    }

    func testBundledFontRegistersWithExpectedPostScriptName() {
        XCTAssertTrue(LCARSTypography.isDisplayFontAvailable)
        let font = CTFontCreateWithName("LCARSGTJ3" as CFString, 26, nil)
        XCTAssertEqual(CTFontCopyPostScriptName(font) as String, "LCARSGTJ3")
    }

    func testMeterRejectsInvalidMeasurementsAndClamps() {
        XCTAssertEqual(LCARSMeter.fraction(value: -3, total: 100), 0)
        XCTAssertEqual(LCARSMeter.fraction(value: 120, total: 100), 1)
        XCTAssertEqual(LCARSMeter.fraction(value: 50, total: 100), 0.5)
        XCTAssertEqual(LCARSMeter.fraction(value: .nan, total: 100), 0)
        XCTAssertEqual(LCARSMeter.fraction(value: 10, total: 0), 0)
        XCTAssertEqual(LCARSMeter.fraction(value: 10, total: .infinity), 0)
    }

    func testDecorativeNoiseIsDeterministicAndVariesByTick() {
        let first = (0..<20).map { LCARSNoise.value(seed: 1701, index: $0, tick: 1) }
        let again = (0..<20).map { LCARSNoise.value(seed: 1701, index: $0, tick: 1) }
        let next = (0..<20).map { LCARSNoise.value(seed: 1701, index: $0, tick: 2) }
        XCTAssertEqual(first, again)
        XCTAssertNotEqual(first, next)
        XCTAssertTrue((first + next).allSatisfy { (1000...9999).contains($0) })
        XCTAssertEqual(LCARSNoise.phase(at: Date(timeIntervalSinceReferenceDate: 1.5), period: 3), 0.5, accuracy: 0.001)
    }
}
