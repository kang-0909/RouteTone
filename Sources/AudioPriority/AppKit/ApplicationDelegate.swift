import AppKit

@MainActor
final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    static var sharedModel: AudioPriorityModel?
    private var statusItemController: StatusItemController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        guard let model = Self.sharedModel else { return }
        guard !model.menuBarIconVisible else { return }
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard let model = Self.sharedModel else { return }
        guard !model.menuBarIconVisible else { return }
        guard NSApp.windows.allSatisfy({ !$0.isVisible }) else { return }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        scheduleSettingsWindow(for: model)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let model = Self.sharedModel else { return }
        if model.menuBarIconVisible {
            statusItemController = StatusItemController(model: model)
        }
        guard !model.menuBarIconVisible else { return }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        scheduleSettingsWindow(for: model)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard let model = Self.sharedModel, !flag else { return true }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        model.showSettingsWindow()
        return true
    }

    private func scheduleSettingsWindow(for model: AudioPriorityModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            model.showSettingsWindow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if NSApp.windows.allSatisfy({ !$0.isVisible }) {
                model.showSettingsWindow()
            }
        }
    }
}
