import SwiftUI
import UIKit

/// UITextView driven by the shared EditorStyleEngine — the same code that styles
/// the Mac editor. This is the file that proves Sources/Shared is genuinely
/// portable: the engine is handed a UITextView and never knows the difference.
struct MarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    let ink: UIColor
    let paper: UIColor
    let fontSize: CGFloat

    func makeUIView(context: Context) -> UITextView {
        // Building the TextKit 1 stack by hand is what lets HidingLayoutManager
        // in: a plain UITextView() gets TextKit 2 on iOS 16+, which has no
        // NSLayoutManager to subclass and would leave the Markdown markers
        // taking up space.
        let storage = NSTextStorage(string: text)
        let layout = HidingLayoutManager()
        let container = NSTextContainer(
            size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        storage.addLayoutManager(layout)
        layout.addTextContainer(container)

        let tv = UITextView(frame: .zero, textContainer: container)
        tv.delegate = context.coordinator
        tv.backgroundColor = paper
        tv.textColor = ink
        tv.font = NotyType.body(fontSize)
        tv.alwaysBounceVertical = true
        tv.keyboardDismissMode = .interactive
        tv.textContainerInset = UIEdgeInsets(top: 18, left: 14, bottom: 18, right: 14)
        tv.text = text
        style(tv)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // Guard the assignment: writing .text unconditionally would reset the
        // caret to the end on every SwiftUI update.
        if tv.text != text {
            let selection = tv.selectedRange
            tv.text = text
            tv.selectedRange = selection
        }
        tv.backgroundColor = paper
        style(tv)
    }

    func style(_ tv: UITextView) {
        let ns = tv.text as NSString
        let activeLine = EditorStyleEngine.lineRange(
            containing: tv.selectedRange.location, in: ns)
        EditorStyleEngine.apply(
            to: tv,
            ranges: [NSRange(location: 0, length: ns.length)],
            revealing: activeLine,
            ink: ink,
            size: fontSize,
            markdownEnabled: true,
            bodyFont: { NotyType.body($0) },
            isCompletedTask: { Tasks.marker(of: $0) == Tasks.done })
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: MarkdownTextView
        init(_ parent: MarkdownTextView) { self.parent = parent }

        func textViewDidChange(_ tv: UITextView) {
            parent.text = tv.text
            parent.style(tv)
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            // Markers are revealed on the caret's line only, so selection moves
            // have to restyle just as edits do.
            parent.style(tv)
        }
    }
}
