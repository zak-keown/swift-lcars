// Render text using the unchanged, separately downloaded LCARSGTJ3 reference font.
// Usage: swift Design/outline-study.swift input.svg font.ttf output.svg
// Font is registered only for this process, never installed on the system.
import Foundation
import CoreText
import CoreGraphics

let args = CommandLine.arguments
guard args.count == 4 else { fatalError("Expected input SVG, font file, output SVG") }
let fontURL = URL(fileURLWithPath: args[2])
var registrationError: Unmanaged<CFError>?
guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &registrationError) else {
    fatalError("Font registration failed")
}
let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as! [CTFontDescriptor]
guard let descriptor = descriptors.first else { fatalError("No font descriptor") }
var source = try String(contentsOfFile: args[1], encoding: .utf8)
let expression = try NSRegularExpression(pattern: "<text([^>]*)>(.*?)</text>")
let attributeExpression = try NSRegularExpression(pattern: "([\\w-]+)=\"([^\"]*)\"")
func number(_ n: CGFloat) -> String { String(format: "%.3f", Double(n)) }
for match in expression.matches(in: source, range: NSRange(source.startIndex..., in: source)).reversed() {
    let attributes = String(source[Range(match.range(at: 1), in: source)!])
    let content = String(source[Range(match.range(at: 2), in: source)!])
    var a: [String: String] = [:]
    for attribute in attributeExpression.matches(in: attributes, range: NSRange(attributes.startIndex..., in: attributes)) {
        a[String(attributes[Range(attribute.range(at: 1), in: attributes)!])] = String(attributes[Range(attribute.range(at: 2), in: attributes)!])
    }
    let defaults: (CGFloat, String)
    switch a["class"] {
    case "label": defaults = (23, "#000000")
    case "small": defaults = (19, "#FCC19F")
    case "data": defaults = (24, "#BAA4E5")
    default:
        // Explicit text attributes are required outside named classes.
        // Group-class inheritance is normalized before invoking this script.
        defaults = (24, "#BAA4E5")
    }
    let size = CGFloat(Double(a["font-size"] ?? "") ?? Double(defaults.0))
    let font = CTFontCreateWithFontDescriptor(descriptor, size, nil)
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: content, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]))
    let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    let x = CGFloat(Double(a["x"] ?? "0")!) - (a["text-anchor"] == "end" ? width : 0)
    let y = CGFloat(Double(a["y"] ?? "0")!)
    var paths: [String] = []
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let count = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: count)
        var positions = [CGPoint](repeating: .zero, count: count)
        CTRunGetGlyphs(run, CFRange(), &glyphs)
        CTRunGetPositions(run, CFRange(), &positions)
        for index in 0..<count {
            guard let glyphPath = CTFontCreatePathForGlyph(font, glyphs[index], nil) else { continue }
            var transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: x + positions[index].x, ty: y - positions[index].y)
            let transformed = glyphPath.copy(using: &transform)!
            var commands = ""
            func point(_ p: CGPoint) -> String { "\(number(p.x)) \(number(p.y))" }
            transformed.applyWithBlock { pointer in
                let e = pointer.pointee
                switch e.type {
                case .moveToPoint: commands += "M" + point(e.points[0])
                case .addLineToPoint: commands += "L" + point(e.points[0])
                case .addQuadCurveToPoint: commands += "Q" + point(e.points[0]) + " " + point(e.points[1])
                case .addCurveToPoint: commands += "C" + point(e.points[0]) + " " + point(e.points[1]) + " " + point(e.points[2])
                case .closeSubpath: commands += "Z"
                @unknown default: break
                }
            }
            paths.append(commands)
        }
    }
    let output = "<g aria-label=\"\(content)\" fill=\"\(a["fill"] ?? defaults.1)\"><path d=\"\(paths.joined())\"/></g>"
    source.replaceSubrange(Range(match.range, in: source)!, with: output)
}
try source.write(toFile: args[3], atomically: true, encoding: .utf8)
print("Outlined with \(CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute)!)")
