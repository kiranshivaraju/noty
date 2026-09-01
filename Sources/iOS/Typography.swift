import SwiftUI
import UIKit

// The iOS counterpart of Sources/Mac/Typography.swift. Face selection is
// deliberately thin here: there is no deck, so none of the tab metrics that tie
// the Mac version to DeckGeom have any meaning yet.

enum NotyType {
    /// Faces that ship on iOS and read well as handwriting on paper.
    static let faceNames = [
        "",                       // system
        "BradleyHandITCTT-Bold",
        "MarkerFelt-Thin",
        "ChalkboardSE-Light",
        "AvenirNext-Regular",
        "Georgia",
        "Menlo-Regular",
    ]

    static var selected: String {
        get { UserDefaults.standard.string(forKey: "noteFontName") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "noteFontName") }
    }

    static func body(_ size: CGFloat) -> UIFont {
        let name = selected
        guard !name.isEmpty, let font = UIFont(name: name, size: size) else {
            return .systemFont(ofSize: size)
        }
        return font
    }

    static func bodyFont(_ size: CGFloat) -> Font {
        let name = selected
        guard !name.isEmpty, UIFont(name: name, size: size) != nil else {
            return .system(size: size)
        }
        return .custom(name, size: size)
    }
}
