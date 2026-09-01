import AppIntents
import SwiftUI
import WidgetKit

// The iPhone's answer to the Mac's edge deck. iOS never lets an app draw over
// another app, so a deck that lives on the screen edge is not possible here —
// but Control Center is reachable from inside any app with one swipe, which is
// the property that made the deck worth having.
//
// The button only opens a URL, so this extension shares no data with the app and
// therefore needs no App Group — which is what keeps it working on free
// provisioning. The app does the writing when it comes up.

@main
struct NotyControlBundle: WidgetBundle {
    var body: some Widget {
        NewNoteControl()
    }
}

struct NewNoteControl: ControlWidget {
    static let kind = "com.kiranshivaraju.noty.control.newnote"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenURLIntent(URL(string: "noty://new")!)) {
                Label("New Note", systemImage: "square.and.pencil")
            }
        }
        .displayName("New Note")
        .description("Open a new Noty note, ready to type.")
    }
}
