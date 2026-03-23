import AppKit
import Foundation
import SwiftUI

@MainActor
final class AudioPriorityModel: ObservableObject {
    enum MenuBarIconState {
        case normal
        case inactive
        case error
    }

    @Published private(set) var devices: [AudioDeviceSnapshot] = []
    @Published private(set) var lastError: String?
    @Published private(set) var statusMessage = "Starting up..."
    @Published private(set) var lastUpdatedAt: Date?

    private let settingsStore = SettingsStore()
    private let hardwareMonitor = AudioHardwareMonitor()
    private var refreshTask: Task<Void, Never>?

    init() {
        ApplicationDelegate.sharedModel = self
        let appliedInitialDefaults = settingsStore.applyInitialDefaultsIfNeeded()
        if settingsStore.settings.useLiquidGlass {
            settingsStore.updateLiquidGlassEnabled(false)
        }
        if appliedInitialDefaults && settingsStore.settings.launchAtLogin {
            do {
                try LaunchAtLoginManager.setEnabled(true)
            } catch {
                lastError = error.localizedDescription
            }
        }

        hardwareMonitor.start { [weak self] in
            Task { @MainActor in
                self?.scheduleRefresh(reason: "hardware change")
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleRefresh(reason: "wake")
            }
        }

        scheduleRefresh(reason: "launch", delayMilliseconds: 0)

        if !menuBarIconVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                self?.showSettingsWindow()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                self?.showSettingsWindow()
            }
        }
    }

    var currentInput: AudioDeviceSnapshot? {
        devices.first(where: \.isDefaultInput)
    }

    var currentOutput: AudioDeviceSnapshot? {
        devices.first(where: \.isDefaultOutput)
    }

    var currentSystemOutput: AudioDeviceSnapshot? {
        devices.first(where: \.isDefaultSystemOutput)
    }

    var autoSwitchInputEnabled: Bool {
        settingsStore.isAutoSwitchEnabled(for: .input)
    }

    var autoSwitchOutputEnabled: Bool {
        settingsStore.isAutoSwitchEnabled(for: .output)
    }

    var launchAtLoginEnabled: Bool {
        settingsStore.settings.launchAtLogin
    }

    var menuBarIconVisible: Bool {
        settingsStore.settings.showMenuBarIcon
    }

    var supportsLiquidGlass: Bool {
        return false
    }

    var liquidGlassEnabled: Bool {
        false
    }

    var statusSymbolName: String {
        if lastError != nil {
            return "exclamationmark.triangle.fill"
        }
        if devices.isEmpty {
            return "speaker.slash.fill"
        }
        return "speaker.wave.2.fill"
    }

    var menuBarIconState: MenuBarIconState {
        if lastError != nil {
            return .error
        }
        if devices.isEmpty {
            return .inactive
        }
        return .normal
    }

    func rankedDevices(for direction: AudioDirection) -> [RankedDevice] {
        settingsStore.orderedDevices(for: direction, availableDevices: devices)
    }

    func setAutoSwitch(_ enabled: Bool, for direction: AudioDirection) {
        settingsStore.updateAutoSwitch(enabled, for: direction)
        statusMessage = enabled ? "\(direction.title) auto-switch enabled." : "\(direction.title) auto-switch paused."
        scheduleRefresh(reason: "auto switch toggle", delayMilliseconds: 50)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginManager.setEnabled(enabled)
            settingsStore.updateLaunchAtLogin(enabled)
            statusMessage = enabled ? "Launch at login enabled." : "Launch at login disabled."
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Launch at login could not be updated."
        }
    }

    func setMenuBarIconVisible(_ isVisible: Bool) {
        settingsStore.updateMenuBarIconVisibility(isVisible)
        statusMessage = isVisible ? "Menu bar icon shown." : "Menu bar icon will hide on next launch."
    }

    func setLiquidGlassEnabled(_ isEnabled: Bool) {
        settingsStore.updateLiquidGlassEnabled(isEnabled)
        statusMessage = isEnabled ? "Liquid Glass enabled." : "Liquid Glass disabled."
    }

    func moveDevice(uid: String, direction: AudioDirection, delta: Int) {
        settingsStore.move(uid, direction: direction, delta: delta)
        statusMessage = "\(direction.title) priority updated."
        scheduleRefresh(reason: "priority reorder", delayMilliseconds: 50)
    }

    func moveDevices(fromOffsets: IndexSet, toOffset: Int, direction: AudioDirection) {
        settingsStore.move(fromOffsets: fromOffsets, toOffset: toOffset, direction: direction)
        statusMessage = "\(direction.title) priority updated."
        scheduleRefresh(reason: "priority reorder", delayMilliseconds: 50)
    }

    func moveDevice(uid: String, to destinationIndex: Int, direction: AudioDirection) {
        settingsStore.move(uid, to: destinationIndex, direction: direction)
        statusMessage = "\(direction.title) priority updated."
        scheduleRefresh(reason: "priority reorder", delayMilliseconds: 50)
    }

    func replacePriorityOrder(with orderedUIDs: [String], direction: AudioDirection) {
        settingsStore.replacePriorityOrder(with: orderedUIDs, direction: direction)
        statusMessage = "\(direction.title) priority updated."
        scheduleRefresh(reason: "priority reorder", delayMilliseconds: 50)
    }

    func moveDevice(uid: String, before targetUID: String, direction: AudioDirection) {
        settingsStore.move(uid, before: targetUID, direction: direction)
        statusMessage = "\(direction.title) priority updated."
        scheduleRefresh(reason: "priority reorder", delayMilliseconds: 50)
    }

    func moveDevice(uid: String, after targetUID: String, direction: AudioDirection) {
        settingsStore.move(uid, after: targetUID, direction: direction)
        statusMessage = "\(direction.title) priority updated."
        scheduleRefresh(reason: "priority reorder", delayMilliseconds: 50)
    }

    func prioritize(uid: String, direction: AudioDirection) {
        settingsStore.prioritize(uid, direction: direction)
        statusMessage = "Moved device to the top of \(direction.title.lowercased()) priority."
        scheduleRefresh(reason: "priority pin", delayMilliseconds: 50)
    }

    func setDeviceEnabled(_ enabled: Bool, uid: String, direction: AudioDirection) {
        settingsStore.setEnabled(enabled, uid: uid, direction: direction)
        statusMessage = enabled ? "Device enabled for \(direction.title.lowercased())." : "Device disabled for \(direction.title.lowercased())."
        scheduleRefresh(reason: "priority enable toggle", delayMilliseconds: 50)
    }

    func removeDevice(uid: String, direction: AudioDirection) {
        settingsStore.removeDevice(uid: uid, direction: direction)
        statusMessage = "Removed device from \(direction.title.lowercased()) priority."
        scheduleRefresh(reason: "priority remove", delayMilliseconds: 50)
    }

    func openSoundSettings(for direction: AudioDirection? = nil) {
        let settingsURLString: String

        switch direction {
        case .output:
            settingsURLString = "x-apple.systempreferences:com.apple.Sound-Settings.extension?output"
        case .input:
            settingsURLString = "x-apple.systempreferences:com.apple.Sound-Settings.extension?input"
        case nil:
            settingsURLString = "x-apple.systempreferences:com.apple.Sound-Settings.extension"
        }

        if let settingsURL = URL(string: settingsURLString) {
            if NSWorkspace.shared.open(settingsURL) {
                return
            }
        }

        let fallback = URL(fileURLWithPath: "/System/Library/PreferencePanes/Sound.prefPane")
        NSWorkspace.shared.open(fallback)
    }

    func showSettingsWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            SettingsWindowController.shared.show(model: self)
        }
    }
    func scheduleRefresh(reason: String, delayMilliseconds: UInt64 = 250) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            if delayMilliseconds > 0 {
                try? await Task.sleep(nanoseconds: delayMilliseconds * 1_000_000)
            }
            await self.refreshAndReconcile(reason: reason)
        }
    }

    private func refreshAndReconcile(reason: String) async {
        do {
            let snapshots = try await Task.detached(priority: .userInitiated) {
                try AudioHardwareClient.captureSnapshot()
            }.value

            guard !Task.isCancelled else { return }

            devices = snapshots
            settingsStore.mergeDiscoveredDevices(snapshots)
            lastUpdatedAt = .now
            lastError = nil

            try await reconcile(direction: .input)
            try await reconcile(direction: .output)

            let timeText = lastUpdatedAt.map { $0.formatted(date: .omitted, time: .shortened) } ?? "just now"
            statusMessage = "Synced \(reason) at \(timeText)."
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Sync failed."
        }
    }

    private func reconcile(direction: AudioDirection) async throws {
        guard settingsStore.isAutoSwitchEnabled(for: direction) else {
            return
        }

        guard let targetUID = settingsStore.bestAvailableUID(for: direction, availableDevices: devices) else {
            return
        }

        switch direction {
        case .input:
            guard currentInput?.uid != targetUID else { return }
        case .output:
            let currentOutputUID = currentOutput?.uid
            let currentSystemUID = currentSystemOutput?.uid
            guard currentOutputUID != targetUID || currentSystemUID != targetUID else { return }
        }

        try await applyDevice(uid: targetUID, direction: direction)
    }

    private func applyDevice(uid: String, direction: AudioDirection) async throws {
        let retryDelays: [UInt64] = [0, 150, 350]
        var lastFailure: Error?

        for delay in retryDelays {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay * 1_000_000)
            }

            do {
                try await Task.detached(priority: .userInitiated) {
                    try AudioHardwareClient.setDefaultDevice(uid: uid, direction: direction)
                }.value

                try? await Task.sleep(nanoseconds: 140_000_000)

                let verified = try await Task.detached(priority: .userInitiated) { () -> Bool in
                    switch direction {
                    case .input:
                        return try AudioHardwareClient.defaultInputUID() == uid
                    case .output:
                        let outputUID = try AudioHardwareClient.defaultOutputUID()
                        let systemUID = try AudioHardwareClient.defaultSystemOutputUID()
                        return outputUID == uid && systemUID == uid
                    }
                }.value

                if verified {
                    return
                }

                lastFailure = AudioHardwareError.verificationFailed("Audio switch verification did not settle in time.")
            } catch {
                lastFailure = error
            }
        }

        throw lastFailure ?? AudioHardwareError.verificationFailed("Audio switch could not be completed.")
    }
}
