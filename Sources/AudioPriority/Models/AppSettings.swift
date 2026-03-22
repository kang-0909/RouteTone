import Foundation

struct AppSettings: Codable {
    var autoSwitchInput: Bool = true
    var autoSwitchOutput: Bool = true
    var launchAtLogin: Bool = false
    var showMenuBarIcon: Bool = true
    var useLiquidGlass: Bool = true
    var inputPriority: [PriorityEntry] = []
    var outputPriority: [PriorityEntry] = []
    var knownDevices: [KnownDeviceRecord] = []
}
