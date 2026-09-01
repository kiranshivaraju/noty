import Foundation
import UIKit

// Proves EditorStyleEngine produces the same attributes under UIKit that it does
// under AppKit. The engine is driven through a mock NotyStyleTarget rather than a
// live UITextView so the binary runs headless under `simctl spawn` — the app
// itself covers the UITextView conformance.

fileprivate final class MockTarget: NotyStyleTarget {
    var notyTypingAttributes: [NSAttributedString.Key: Any] = [:]
    let storage = NSTextStorage()
    var notyTextStorage: NSTextStorage? { storage }
    var notyLayoutManager: NSLayoutManager? { nil }

    init(_ source: String) {
        storage.setAttributedString(NSAttributedString(string: source))
    }
}

@main
struct IOSEngineSmokeTest {
    static var failures: [String] = []

    static func check(_ condition: Bool, _ label: String) {
        if !condition { failures.append(label) }
    }

    fileprivate static func styled(_ source: String, revealing: NSRange? = nil) -> MockTarget {
        let target = MockTarget(source)
        let full = NSRange(location: 0, length: (source as NSString).length)
        EditorStyleEngine.apply(
            to: target,
            ranges: [full],
            revealing: revealing,
            ink: .black,
            size: 14,
            markdownEnabled: true,
            bodyFont: { UIFont.systemFont(ofSize: $0) },
            isCompletedTask: { Tasks.marker(of: $0) == Tasks.done })
        return target
    }

    static func main() {
        // 1. Bold markdown resolves to a bold font on iOS.
        let bold = styled("**loud** quiet")
        let boldFont = bold.storage.attribute(.font, at: 2, effectiveRange: nil) as? UIFont
        let plainFont = bold.storage.attribute(.font, at: 10, effectiveRange: nil) as? UIFont
        check(boldFont?.fontDescriptor.symbolicTraits.contains(.traitBold) == true,
              "**bold** should render with a bold font")
        check(plainFont?.fontDescriptor.symbolicTraits.contains(.traitBold) == false,
              "text outside the markers should stay regular")

        // 2. Markers are marked hidden when the caret is not on that line.
        let hidden = bold.storage.attribute(NSAttributedString.Key.notyHidden,
                                            at: 0, effectiveRange: nil) as? Bool
        check(hidden == true, "** markers should be flagged hidden off the active line")

        // 3. Revealing the line un-hides its markers.
        let revealed = styled("**loud** quiet", revealing: NSRange(location: 0, length: 14))
        let stillHidden = revealed.storage.attribute(NSAttributedString.Key.notyHidden,
                                                     at: 0, effectiveRange: nil) as? Bool
        check(stillHidden != true, "markers on the caret's line should be revealed")

        // 4. A completed task is struck through.
        let task = styled("\(Tasks.donePrefix)shipped")
        let strike = task.storage.attribute(.strikethroughStyle, at: 3, effectiveRange: nil)
        check(strike != nil, "a ☑ task line should be struck through")

        // 5. An open task is not.
        let open = styled("\(Tasks.openPrefix)todo")
        let noStrike = open.storage.attribute(.strikethroughStyle, at: 3, effectiveRange: nil)
        check(noStrike == nil, "an ☐ task line should not be struck through")

        // 6. Ink reaches the text as a UIColor.
        let colour = task.storage.attribute(.foregroundColor, at: 3, effectiveRange: nil)
        check(colour is UIColor, "ink should be applied as a UIColor")

        // 7. Crypto round-trips under the iOS SDK.
        let secret = "sealed on iOS ☑"
        check(Crypto.open(Crypto.seal(secret)) == secret, "AES-GCM should round-trip")

        if failures.isEmpty {
            print("IOSEngineSmokeTest: all checks passed")
        } else {
            for f in failures { print("FAIL: \(f)") }
            exit(1)
        }
    }
}
