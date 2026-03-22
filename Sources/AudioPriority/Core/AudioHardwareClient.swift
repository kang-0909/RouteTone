import AudioToolbox
import CoreAudio
import Foundation

enum AudioHardwareError: LocalizedError {
    case propertyUnavailable(String)
    case coreAudio(OSStatus, String)
    case missingDevice(String)
    case verificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .propertyUnavailable(let message):
            return message
        case .coreAudio(let status, let context):
            return "\(context) failed with OSStatus \(status)."
        case .missingDevice(let uid):
            return "Could not find audio device with UID \(uid)."
        case .verificationFailed(let message):
            return message
        }
    }
}

enum AudioHardwareClient {
    private static let systemObjectID = AudioObjectID(kAudioObjectSystemObject)

    static func captureSnapshot() throws -> [AudioDeviceSnapshot] {
        let defaultInput = try defaultDeviceID(forSelector: kAudioHardwarePropertyDefaultInputDevice)
        let defaultOutput = try defaultDeviceID(forSelector: kAudioHardwarePropertyDefaultOutputDevice)
        let defaultSystemOutput = try defaultDeviceID(forSelector: kAudioHardwarePropertyDefaultSystemOutputDevice)

        return try allDeviceIDs().compactMap { deviceID in
            try makeSnapshot(
                for: deviceID,
                defaultInput: defaultInput,
                defaultOutput: defaultOutput,
                defaultSystemOutput: defaultSystemOutput
            )
        }
        .sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    static func defaultInputUID() throws -> String? {
        try uid(for: defaultDeviceID(forSelector: kAudioHardwarePropertyDefaultInputDevice))
    }

    static func defaultOutputUID() throws -> String? {
        try uid(for: defaultDeviceID(forSelector: kAudioHardwarePropertyDefaultOutputDevice))
    }

    static func defaultSystemOutputUID() throws -> String? {
        try uid(for: defaultDeviceID(forSelector: kAudioHardwarePropertyDefaultSystemOutputDevice))
    }

    static func setDefaultDevice(uid: String, direction: AudioDirection) throws {
        let deviceID = try deviceID(forUID: uid)

        switch direction {
        case .input:
            try setSystemProperty(
                selector: kAudioHardwarePropertyDefaultInputDevice,
                deviceID: deviceID,
                context: "Setting default input device"
            )
        case .output:
            try setSystemProperty(
                selector: kAudioHardwarePropertyDefaultOutputDevice,
                deviceID: deviceID,
                context: "Setting default output device"
            )
            try setSystemProperty(
                selector: kAudioHardwarePropertyDefaultSystemOutputDevice,
                deviceID: deviceID,
                context: "Setting default system output device"
            )
        }
    }

    private static func setSystemProperty(selector: AudioObjectPropertySelector, deviceID: AudioObjectID, context: String) throws {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var mutableDeviceID = deviceID
        let size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectSetPropertyData(systemObjectID, &address, 0, nil, size, &mutableDeviceID)
        guard status == noErr else {
            throw AudioHardwareError.coreAudio(status, context)
        }
    }

    private static func makeSnapshot(
        for deviceID: AudioObjectID,
        defaultInput: AudioObjectID,
        defaultOutput: AudioObjectID,
        defaultSystemOutput: AudioObjectID
    ) throws -> AudioDeviceSnapshot? {
        guard let uid = try uid(for: deviceID), !uid.isEmpty else {
            return nil
        }

        let name = try stringProperty(
            objectID: deviceID,
            selector: kAudioObjectPropertyName,
            fallback: "Unknown Device"
        ) ?? "Unknown Device"
        let manufacturer = try? stringProperty(
            objectID: deviceID,
            selector: kAudioObjectPropertyManufacturer,
            fallback: nil
        )
        let transport = TransportType(coreAudioValue: try numericProperty(
            objectID: deviceID,
            selector: kAudioDevicePropertyTransportType
        ))
        let isAlive = try boolProperty(
            objectID: deviceID,
            selector: kAudioDevicePropertyDeviceIsAlive,
            fallback: true
        )
        let supportsInput = try hasChannels(deviceID: deviceID, scope: kAudioObjectPropertyScopeInput)
        let supportsOutput = try hasChannels(deviceID: deviceID, scope: kAudioObjectPropertyScopeOutput)

        return AudioDeviceSnapshot(
            audioObjectID: deviceID,
            uid: uid,
            name: name,
            manufacturer: manufacturer,
            transportType: transport,
            supportsInput: supportsInput,
            supportsOutput: supportsOutput,
            isAlive: isAlive,
            isDefaultInput: deviceID == defaultInput,
            isDefaultOutput: deviceID == defaultOutput,
            isDefaultSystemOutput: deviceID == defaultSystemOutput
        )
    }

    private static func allDeviceIDs() throws -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(systemObjectID, &address, 0, nil, &dataSize)
        guard status == noErr else {
            throw AudioHardwareError.coreAudio(status, "Reading audio device list size")
        }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = Array(repeating: AudioObjectID(), count: count)
        status = AudioObjectGetPropertyData(systemObjectID, &address, 0, nil, &dataSize, &deviceIDs)
        guard status == noErr else {
            throw AudioHardwareError.coreAudio(status, "Reading audio device list")
        }
        return deviceIDs
    }

    private static func defaultDeviceID(forSelector selector: AudioObjectPropertySelector) throws -> AudioObjectID {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioObjectID()
        var dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(systemObjectID, &address, 0, nil, &dataSize, &deviceID)
        guard status == noErr else {
            throw AudioHardwareError.coreAudio(status, "Reading default audio device")
        }
        return deviceID
    }

    private static func deviceID(forUID targetUID: String) throws -> AudioObjectID {
        for deviceID in try allDeviceIDs() {
            if try uid(for: deviceID) == targetUID {
                return deviceID
            }
        }
        throw AudioHardwareError.missingDevice(targetUID)
    }

    private static func uid(for deviceID: AudioObjectID) throws -> String? {
        try stringProperty(
            objectID: deviceID,
            selector: kAudioDevicePropertyDeviceUID,
            fallback: nil
        )
    }

    private static func stringProperty(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        fallback: String?
    ) throws -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        let status = withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, pointer)
        }
        if status == noErr {
            let stringValue = (value as String?) ?? ""
            return stringValue.isEmpty ? fallback : stringValue
        }
        if let fallback {
            return fallback
        }
        throw AudioHardwareError.propertyUnavailable("Audio string property \(selector) is unavailable.")
    }

    private static func numericProperty(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) throws -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value)
        guard status == noErr else {
            throw AudioHardwareError.coreAudio(status, "Reading numeric audio property")
        }
        return value
    }

    private static func boolProperty(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        fallback: Bool
    ) throws -> Bool {
        do {
            return try numericProperty(objectID: objectID, selector: selector) != 0
        } catch {
            return fallback
        }
    }

    private static func hasChannels(deviceID: AudioObjectID, scope: AudioObjectPropertyScope) throws -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        guard sizeStatus == noErr else {
            return false
        }

        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(dataSize),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { rawPointer.deallocate() }

        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, rawPointer)
        guard status == noErr else {
            throw AudioHardwareError.coreAudio(status, "Reading audio channel layout")
        }

        let bufferList = rawPointer.assumingMemoryBound(to: AudioBufferList.self)
        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        let channelCount = buffers.reduce(0) { partialResult, buffer in
            partialResult + Int(buffer.mNumberChannels)
        }
        return channelCount > 0
    }
}
