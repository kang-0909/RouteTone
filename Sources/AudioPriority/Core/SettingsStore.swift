import Foundation
import SwiftUI

@MainActor
final class SettingsStore {
    private let fileURL: URL
    private(set) var settings: AppSettings

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("RouteTone", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("settings.json")
        settings = (try? Self.loadSettings(from: fileURL)) ?? AppSettings()
    }

    func updateAutoSwitch(_ enabled: Bool, for direction: AudioDirection) {
        switch direction {
        case .input:
            settings.autoSwitchInput = enabled
        case .output:
            settings.autoSwitchOutput = enabled
        }
        save()
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        settings.launchAtLogin = enabled
        save()
    }

    func updateMenuBarIconVisibility(_ isVisible: Bool) {
        settings.showMenuBarIcon = isVisible
        save()
    }

    func updateLiquidGlassEnabled(_ isEnabled: Bool) {
        settings.useLiquidGlass = isEnabled
        save()
    }

    func mergeDiscoveredDevices(_ devices: [AudioDeviceSnapshot]) {
        let shouldBootstrapInputPriority = settings.inputPriority.isEmpty
        let shouldBootstrapOutputPriority = settings.outputPriority.isEmpty
        var knownByUID = Dictionary(uniqueKeysWithValues: settings.knownDevices.map { ($0.uid, $0) })

        for device in devices {
            let updatedRecord = KnownDeviceRecord(
                uid: device.uid,
                name: device.name,
                manufacturer: device.manufacturer,
                transportType: device.transportType,
                supportsInput: device.supportsInput,
                supportsOutput: device.supportsOutput,
                lastSeenAt: .now
            )
            knownByUID[device.uid] = updatedRecord

            if device.supportsInput && !settings.inputPriority.contains(where: { $0.deviceUID == device.uid }) {
                settings.inputPriority.append(PriorityEntry(deviceUID: device.uid))
            }
            if device.supportsOutput && !settings.outputPriority.contains(where: { $0.deviceUID == device.uid }) {
                settings.outputPriority.append(PriorityEntry(deviceUID: device.uid))
            }
        }

        settings.knownDevices = Array(knownByUID.values).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        if shouldBootstrapInputPriority {
            settings.inputPriority = bootstrappedPriority(
                for: .input,
                availableDevices: devices
            )
        }

        if shouldBootstrapOutputPriority {
            settings.outputPriority = bootstrappedPriority(
                for: .output,
                availableDevices: devices
            )
        }

        save()
    }

    func orderedDevices(
        for direction: AudioDirection,
        availableDevices: [AudioDeviceSnapshot]
    ) -> [RankedDevice] {
        let availableByUID = Dictionary(uniqueKeysWithValues: availableDevices.map { ($0.uid, $0) })
        let priority = priorityEntries(for: direction)

        return priority.enumerated().compactMap { index, entry in
            guard let record = knownRecord(for: entry.deviceUID) else {
                return nil
            }

            let available = availableByUID[entry.deviceUID]
            let isCurrentDefault: Bool
            switch direction {
            case .input:
                isCurrentDefault = available?.isDefaultInput == true
            case .output:
                isCurrentDefault = available?.isDefaultOutput == true
            }

            return RankedDevice(
                direction: direction,
                rank: index + 1,
                record: record,
                isEnabled: entry.isEnabled,
                isAvailable: available != nil,
                isCurrentDefault: isCurrentDefault
            )
        }
    }

    func bestAvailableUID(
        for direction: AudioDirection,
        availableDevices: [AudioDeviceSnapshot]
    ) -> String? {
        let availableByUID = Dictionary(uniqueKeysWithValues: availableDevices.map { ($0.uid, $0) })
        for entry in priorityEntries(for: direction) where entry.isEnabled {
            if availableByUID[entry.deviceUID] != nil {
                return entry.deviceUID
            }
        }
        return nil
    }

    func move(_ uid: String, direction: AudioDirection, delta: Int) {
        var entries = priorityEntries(for: direction)
        guard let currentIndex = entries.firstIndex(where: { $0.deviceUID == uid }) else { return }
        let newIndex = min(max(currentIndex + delta, 0), entries.count - 1)
        guard currentIndex != newIndex else { return }

        let entry = entries.remove(at: currentIndex)
        entries.insert(entry, at: newIndex)
        setPriorityEntries(entries, for: direction)
        save()
    }

    func move(fromOffsets: IndexSet, toOffset: Int, direction: AudioDirection) {
        var entries = priorityEntries(for: direction)
        entries.move(fromOffsets: fromOffsets, toOffset: toOffset)
        setPriorityEntries(entries, for: direction)
        save()
    }

    func move(_ uid: String, to destinationIndex: Int, direction: AudioDirection) {
        var entries = priorityEntries(for: direction)
        guard let currentIndex = entries.firstIndex(where: { $0.deviceUID == uid }) else { return }

        let entry = entries.remove(at: currentIndex)
        let clampedIndex = min(max(destinationIndex, 0), entries.count)
        entries.insert(entry, at: clampedIndex)
        setPriorityEntries(entries, for: direction)
        save()
    }

    func move(_ uid: String, before targetUID: String, direction: AudioDirection) {
        guard uid != targetUID else { return }

        var entries = priorityEntries(for: direction)
        guard let currentIndex = entries.firstIndex(where: { $0.deviceUID == uid }) else { return }
        guard let targetIndex = entries.firstIndex(where: { $0.deviceUID == targetUID }) else { return }

        let entry = entries.remove(at: currentIndex)
        let adjustedTargetIndex = currentIndex < targetIndex ? targetIndex - 1 : targetIndex
        entries.insert(entry, at: adjustedTargetIndex)
        setPriorityEntries(entries, for: direction)
        save()
    }

    func move(_ uid: String, after targetUID: String, direction: AudioDirection) {
        guard uid != targetUID else { return }

        var entries = priorityEntries(for: direction)
        guard let currentIndex = entries.firstIndex(where: { $0.deviceUID == uid }) else { return }
        guard let targetIndex = entries.firstIndex(where: { $0.deviceUID == targetUID }) else { return }

        let entry = entries.remove(at: currentIndex)
        let adjustedTargetIndex = currentIndex < targetIndex ? targetIndex : targetIndex + 1
        let insertionIndex = min(adjustedTargetIndex, entries.count)
        entries.insert(entry, at: insertionIndex)
        setPriorityEntries(entries, for: direction)
        save()
    }

    func prioritize(_ uid: String, direction: AudioDirection) {
        var entries = priorityEntries(for: direction)
        guard let currentIndex = entries.firstIndex(where: { $0.deviceUID == uid }) else { return }
        let entry = entries.remove(at: currentIndex)
        entries.insert(entry, at: 0)
        setPriorityEntries(entries, for: direction)
        save()
    }

    func setEnabled(_ enabled: Bool, uid: String, direction: AudioDirection) {
        var entries = priorityEntries(for: direction)
        guard let index = entries.firstIndex(where: { $0.deviceUID == uid }) else { return }
        entries[index].isEnabled = enabled
        setPriorityEntries(entries, for: direction)
        save()
    }

    func isAutoSwitchEnabled(for direction: AudioDirection) -> Bool {
        switch direction {
        case .input:
            return settings.autoSwitchInput
        case .output:
            return settings.autoSwitchOutput
        }
    }

    private func priorityEntries(for direction: AudioDirection) -> [PriorityEntry] {
        switch direction {
        case .input:
            return settings.inputPriority
        case .output:
            return settings.outputPriority
        }
    }

    private func setPriorityEntries(_ entries: [PriorityEntry], for direction: AudioDirection) {
        switch direction {
        case .input:
            settings.inputPriority = entries
        case .output:
            settings.outputPriority = entries
        }
    }

    private func knownRecord(for uid: String) -> KnownDeviceRecord? {
        settings.knownDevices.first(where: { $0.uid == uid })
    }

    private func bootstrappedPriority(
        for direction: AudioDirection,
        availableDevices: [AudioDeviceSnapshot]
    ) -> [PriorityEntry] {
        availableDevices
            .filter { $0.supports(direction) }
            .sorted { lhs, rhs in
                let lhsScore = priorityScore(for: lhs, direction: direction)
                let rhsScore = priorityScore(for: rhs, direction: direction)
                if lhsScore != rhsScore {
                    return lhsScore < rhsScore
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .map { PriorityEntry(deviceUID: $0.uid) }
    }

    private func priorityScore(for device: AudioDeviceSnapshot, direction: AudioDirection) -> Int {
        let normalizedName = device.name.lowercased()

        switch direction {
        case .input:
            if device.transportType == .builtIn || normalizedName.contains("macbook") || normalizedName.contains("built-in") || normalizedName.contains("internal") {
                return 0
            }
            if device.transportType == .usb || normalizedName.contains("microphone") || normalizedName.contains("mic") {
                return 1
            }
            if device.transportType == .bluetooth || normalizedName.contains("airpods") || normalizedName.contains("headset") || normalizedName.contains("buds") {
                return 3
            }
            return 2

        case .output:
            if device.transportType == .bluetooth || normalizedName.contains("airpods") || normalizedName.contains("headphone") || normalizedName.contains("headset") || normalizedName.contains("buds") || normalizedName.contains("bose") || normalizedName.contains("beats") || normalizedName.contains("sony") {
                return 0
            }
            if device.transportType == .builtIn || normalizedName.contains("speaker") || normalizedName.contains("macbook") {
                return 1
            }
            if device.transportType == .hdmi || device.transportType == .displayPort {
                return 3
            }
            return 2
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder.pretty.encode(settings)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("RouteTone failed to save settings: %@", error.localizedDescription)
        }
    }

    private static func loadSettings(from url: URL) throws -> AppSettings {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AppSettings.self, from: data)
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    convenience init(iso8601: Bool = true) {
        self.init()
        if iso8601 {
            dateDecodingStrategy = .iso8601
        }
    }
}
