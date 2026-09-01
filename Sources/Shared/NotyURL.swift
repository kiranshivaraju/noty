import Foundation

/// Parsing for the noty:// scheme, kept apart from the UI that acts on it so the
/// routing can be tested without a running app. The Mac reads the same scheme
/// through AppDelegate; the iPhone's Control Center button fires noty://new.
enum NotyURL {
    enum Route: Equatable {
        case newNote(text: String)
        case allNotes
        case settings
        case unknown
    }

    static func route(_ url: URL) -> Route {
        guard url.scheme == "noty" else { return .unknown }
        switch url.host {
        case "new", "capture":
            let text = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "text" }?.value ?? ""
            return .newNote(text: text)
        case "all":
            return .allNotes
        case "settings":
            return .settings
        default:
            return .unknown
        }
    }
}
