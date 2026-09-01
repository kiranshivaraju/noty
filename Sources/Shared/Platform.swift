// Platform.swift — the one file that knows which OS it is on.
//
// Everything else in Sources/Shared is written against these aliases, so the
// store, the note model and the Markdown styling engine compile unchanged for
// both macOS and iOS. On macOS every alias resolves to the AppKit type it
// replaced, so the Mac app's behaviour is identical to before this file existed.

import Foundation

#if canImport(AppKit)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#endif

// MARK: - Bold conversion

extension PlatformFont {
    /// A bold cut of `base`, falling back to a semibold system font when the
    /// family has no bold face.
    static func noty_bolder(than base: PlatformFont, size: CGFloat) -> PlatformFont {
        #if canImport(AppKit)
        // Kept on NSFontManager rather than font descriptors so the Mac app
        // picks exactly the same faces it always has.
        let bold = NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
        return bold != base ? bold : NSFont.systemFont(ofSize: size, weight: .semibold)
        #else
        if let descriptor = base.fontDescriptor.withSymbolicTraits(.traitBold) {
            return UIFont(descriptor: descriptor, size: base.pointSize)
        }
        return UIFont.systemFont(ofSize: size, weight: .semibold)
        #endif
    }
}

// MARK: - Style target

/// The slice of a text view the styling engine actually touches. NSTextView and
/// UITextView both satisfy it, which is what keeps EditorStyleEngine free of
/// any view class.
protocol NotyStyleTarget: AnyObject {
    var notyTypingAttributes: [NSAttributedString.Key: Any] { get set }
    var notyTextStorage: NSTextStorage? { get }
    var notyLayoutManager: NSLayoutManager? { get }
}

#if canImport(AppKit)
extension NSTextView: NotyStyleTarget {
    var notyTypingAttributes: [NSAttributedString.Key: Any] {
        get { typingAttributes }
        set { typingAttributes = newValue }
    }
    var notyTextStorage: NSTextStorage? { textStorage }
    var notyLayoutManager: NSLayoutManager? { layoutManager }
}
#elseif canImport(UIKit)
extension UITextView: NotyStyleTarget {
    var notyTypingAttributes: [NSAttributedString.Key: Any] {
        get { typingAttributes }
        set { typingAttributes = newValue }
    }
    var notyTextStorage: NSTextStorage? { textStorage }
    var notyLayoutManager: NSLayoutManager? { layoutManager }
}
#endif
