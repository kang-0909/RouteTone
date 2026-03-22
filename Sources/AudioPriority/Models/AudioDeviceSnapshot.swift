import Foundation

struct AudioDeviceSnapshot: Identifiable, Hashable {
    let audioObjectID: UInt32
    let uid: String
    let name: String
    let manufacturer: String?
    let transportType: TransportType
    let supportsInput: Bool
    let supportsOutput: Bool
    let isAlive: Bool
    let isDefaultInput: Bool
    let isDefaultOutput: Bool
    let isDefaultSystemOutput: Bool

    var id: String { uid }

    func supports(_ direction: AudioDirection) -> Bool {
        switch direction {
        case .input:
            return supportsInput
        case .output:
            return supportsOutput
        }
    }
}

struct KnownDeviceRecord: Codable, Hashable, Identifiable {
    let uid: String
    var name: String
    var manufacturer: String?
    var transportType: TransportType
    var supportsInput: Bool
    var supportsOutput: Bool
    var lastSeenAt: Date

    var id: String { uid }
}

struct PriorityEntry: Codable, Hashable, Identifiable {
    var deviceUID: String
    var isEnabled: Bool = true

    var id: String { deviceUID }
}

struct RankedDevice: Identifiable, Hashable {
    let direction: AudioDirection
    let rank: Int
    let record: KnownDeviceRecord
    let isEnabled: Bool
    let isAvailable: Bool
    let isCurrentDefault: Bool

    var id: String { record.uid }
}
