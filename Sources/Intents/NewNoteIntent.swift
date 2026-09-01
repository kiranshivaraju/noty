import AppIntents
import Foundation

// Compiled into BOTH the app and the control extension — the system requires
// that shared membership to launch the app from a control.
//
// The obvious approach, ControlWidgetButton(action: OpenURLIntent(noty://new)),
// does not work: OpenURLIntent refuses custom URL schemes from a Control Widget
// and accepts only Universal Links, which would mean owning a domain and serving
// an apple-app-site-association file for an app that deliberately talks to no
// server. So the intent opens the app itself and leaves a note behind for it.
//
// perform() runs in the *app's* process because openAppWhenRun is true, so the
// flag it sets is the app's own UserDefaults — no App Group needed, which is
// what keeps this working under free provisioning.

extension Notification.Name {
    static let notyNewNoteRequested = Notification.Name("notyNewNoteRequested")
}

enum CaptureRequest {
    static let key = "notyPendingNewNote"

    static func raise() {
        UserDefaults.standard.set(true, forKey: key)
        NotificationCenter.default.post(name: .notyNewNoteRequested, object: nil)
    }

    /// Reads and clears in one step, so a pending capture is only ever honoured
    /// once however many times the app is asked.
    static func take() -> Bool {
        guard UserDefaults.standard.bool(forKey: key) else { return false }
        UserDefaults.standard.removeObject(forKey: key)
        return true
    }
}

struct NewNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "New Note"
    static let description = IntentDescription("Open a new Noty note, ready to type.")

    /// Brings the app forward. Without this the control fires into nothing.
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        CaptureRequest.raise()
        return .result()
    }
}
