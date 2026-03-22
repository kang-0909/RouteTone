import AppKit
import Carbon
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private override init() {}

    func show(model: AudioPriorityModel) {
        promoteToForegroundApplication()
        let hostingController = NSHostingController(rootView: SettingsView(model: model))

        if let window {
            window.contentViewController = hostingController
        } else {
            let window = NSWindow(contentViewController: hostingController)
            window.title = "RouteTone Settings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 620, height: 680))
            window.minSize = NSSize(width: 560, height: 560)
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.collectionBehavior = [.moveToActiveSpace]
            window.center()
            self.window = window
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        demoteToAccessoryApplication()
        NSApp.setActivationPolicy(.accessory)
    }

    private func promoteToForegroundApplication() {
        var processSerialNumber = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&processSerialNumber, ProcessApplicationTransformState(kProcessTransformToForegroundApplication))
    }

    private func demoteToAccessoryApplication() {
        var processSerialNumber = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&processSerialNumber, ProcessApplicationTransformState(kProcessTransformToUIElementApplication))
    }
}
