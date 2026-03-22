import Foundation
import CoreAudio

enum TransportType: String, Codable, Hashable {
    case builtIn
    case bluetooth
    case bluetoothLE
    case usb
    case hdmi
    case displayPort
    case airPlay
    case aggregate
    case virtual
    case pci
    case unknown

    init(coreAudioValue: UInt32) {
        switch coreAudioValue {
        case kAudioDeviceTransportTypeBuiltIn:
            self = .builtIn
        case kAudioDeviceTransportTypeBluetooth:
            self = .bluetooth
        case kAudioDeviceTransportTypeBluetoothLE:
            self = .bluetoothLE
        case kAudioDeviceTransportTypeUSB:
            self = .usb
        case kAudioDeviceTransportTypeHDMI:
            self = .hdmi
        case kAudioDeviceTransportTypeDisplayPort:
            self = .displayPort
        case kAudioDeviceTransportTypeAirPlay:
            self = .airPlay
        case kAudioDeviceTransportTypeAggregate:
            self = .aggregate
        case kAudioDeviceTransportTypeVirtual:
            self = .virtual
        case kAudioDeviceTransportTypePCI:
            self = .pci
        default:
            self = .unknown
        }
    }

    var label: String {
        switch self {
        case .builtIn:
            return "Built-in"
        case .bluetooth:
            return "Bluetooth"
        case .bluetoothLE:
            return "Bluetooth LE"
        case .usb:
            return "USB"
        case .hdmi:
            return "HDMI"
        case .displayPort:
            return "DisplayPort"
        case .airPlay:
            return "AirPlay"
        case .aggregate:
            return "Aggregate"
        case .virtual:
            return "Virtual"
        case .pci:
            return "PCI"
        case .unknown:
            return "Unknown"
        }
    }
}
