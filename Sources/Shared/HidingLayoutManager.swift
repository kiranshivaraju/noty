#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Collapses glyphs carrying `.notyHidden` to nothing. This is the only way to
/// hide characters without deleting them: colouring them clear still leaves
/// their width behind, and the caret still walks through them.
final class HidingLayoutManager: NSLayoutManager {
    override func setGlyphs(_ glyphs: UnsafePointer<CGGlyph>,
                            properties props: UnsafePointer<NSLayoutManager.GlyphProperty>,
                            characterIndexes charIndexes: UnsafePointer<Int>,
                            font aFont: PlatformFont,
                            forGlyphRange glyphRange: NSRange) {
        guard let storage = textStorage else {
            super.setGlyphs(glyphs, properties: props, characterIndexes: charIndexes,
                            font: aFont, forGlyphRange: glyphRange)
            return
        }
        var edited = Array(UnsafeBufferPointer(start: props, count: glyphRange.length))
        var changed = false
        for i in 0..<glyphRange.length {
            let ci = charIndexes[i]
            guard ci < storage.length else { continue }
            if storage.attribute(.notyHidden, at: ci, effectiveRange: nil) != nil {
                edited[i] = .null
                changed = true
            }
        }
        guard changed else {
            super.setGlyphs(glyphs, properties: props, characterIndexes: charIndexes,
                            font: aFont, forGlyphRange: glyphRange)
            return
        }
        edited.withUnsafeBufferPointer { buf in
            super.setGlyphs(glyphs, properties: buf.baseAddress!, characterIndexes: charIndexes,
                            font: aFont, forGlyphRange: glyphRange)
        }
    }
}
