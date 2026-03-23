import Foundation

struct AppSettings: Codable {
    var hasCompletedInitialSetup: Bool = false
    var autoSwitchInput: Bool = true
    var autoSwitchOutput: Bool = true
    var launchAtLogin: Bool = true
    var showMenuBarIcon: Bool = true
    var useLiquidGlass: Bool = true
    var inputPriority: [PriorityEntry] = []
    var outputPriority: [PriorityEntry] = []
    var removedInputUIDs: [String] = []
    var removedOutputUIDs: [String] = []
    var knownDevices: [KnownDeviceRecord] = []
}
