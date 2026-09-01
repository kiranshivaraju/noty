import Foundation
import SwiftUI
import AppKit

// Typography lives Mac-side for now: face selection reads Settings, and tab
// metrics scale off DeckGeom — both deck concepts with no iOS meaning yet.
// The iOS app will bring its own equivalent.

// MARK: - Type

/// One entry per face offered for note bodies.
struct NoteFace {
    let name: String          // shown in the menu
    let body: String          // PostScript name, "" for the system font
    let tab: String           // heavier cut used on the tab labels
    let bump: CGFloat         // size nudge so faces look the same size as each other
}

enum Ink {
    /// Faces that suit a note. Filtered to what is actually installed, so the
    /// menu never offers something that would silently fall back.
    static let allFaces: [NoteFace] = [
        NoteFace(name: "System",       body: "",                     tab: "",                     bump: 0),
        NoteFace(name: "Noteworthy",   body: "Noteworthy-Light",     tab: "Noteworthy-Bold",      bump: 1.5),
        NoteFace(name: "Bradley Hand", body: "BradleyHandITCTT-Bold", tab: "BradleyHandITCTT-Bold", bump: 1.5),
        NoteFace(name: "Marker Felt",  body: "MarkerFelt-Thin",      tab: "MarkerFelt-Wide",      bump: 1),
        NoteFace(name: "Chalkboard",   body: "ChalkboardSE-Light",   tab: "ChalkboardSE-Bold",    bump: 0),
        NoteFace(name: "Avenir Next",  body: "AvenirNext-Regular",   tab: "AvenirNext-DemiBold",  bump: 0),
        NoteFace(name: "New York",     body: "NewYork-Regular",      tab: "NewYork-Semibold",     bump: 0),
        NoteFace(name: "Georgia",      body: "Georgia",              tab: "Georgia-Bold",         bump: 0),
        NoteFace(name: "Menlo",        body: "Menlo-Regular",        tab: "Menlo-Bold",           bump: -1),
    ]

    /// Installed faces do not change while the app runs, and this is asked for on
    /// every text render — resolving it each time cost nine font lookups a call.
    static let faces: [NoteFace] =
        allFaces.filter { $0.body.isEmpty || PlatformFont(name: $0.body, size: 12) != nil }

    private static var faceCache: (name: String, face: NoteFace)?

    static var face: NoteFace {
        let want = Settings.noteFontName
        if let cached = faceCache, cached.name == want { return cached.face }
        let resolved = faces.first { $0.body == want } ?? faces[0]
        faceCache = (want, resolved)
        return resolved
    }

    /// The hand (or face) note bodies are set in.
    static func body(_ size: CGFloat) -> PlatformFont {
        let f = face
        guard !f.body.isEmpty, let font = PlatformFont(name: f.body, size: size + f.bump) else {
            return .systemFont(ofSize: size)
        }
        return font
    }

    // Tab labels use the same face a shade bolder, so they hold up turned on
    // their side at this size.
    /// Labels scale with the deck, so a bigger tab carries a bigger title rather
    /// than more empty paper. Layout measures the strip with this very font, so
    /// the two cannot drift apart.
    static var tabSize: CGFloat { 9.5 * DeckGeom.scale }
    static var tabTracking: CGFloat { 0.1 * DeckGeom.scale }

    /// For measuring — layout sizes each tab's strip to the longest label.
    static var tabNSFont: PlatformFont {
        let f = face
        guard !f.tab.isEmpty, let font = PlatformFont(name: f.tab, size: tabSize + f.bump) else {
            return .systemFont(ofSize: tabSize - 0.5, weight: .semibold)
        }
        return font
    }

    /// The body face as a SwiftUI font. Falls back to the system font by name,
    /// which `Font.custom` cannot express for the system face.
    static func bodyFont(_ size: CGFloat) -> Font {
        let f = face
        guard !f.body.isEmpty, PlatformFont(name: f.body, size: size) != nil else {
            return .system(size: size)
        }
        return .custom(f.body, size: size + f.bump)
    }

    static var tabFont: Font {
        let f = face
        guard !f.tab.isEmpty, PlatformFont(name: f.tab, size: tabSize) != nil else {
            return .system(size: tabSize - 0.5, weight: .semibold)
        }
        return .custom(f.tab, size: tabSize + f.bump)
    }
}

