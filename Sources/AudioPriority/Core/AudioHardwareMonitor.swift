import CoreAudio
import Foundation

final class AudioHardwareMonitor {
    enum ChangeKind {
        case deviceList
        case defaultDevice
    }

    private let queue = DispatchQueue(label: "RouteTone.AudioHardwareMonitor")
    private var hasStarted = false

    func start(onChange: @escaping (ChangeKind) -> Void) {
        guard !hasStarted else { return }
        hasStarted = true

        let selectors: [(AudioObjectPropertySelector, ChangeKind)] = [
            (kAudioHardwarePropertyDevices, .deviceList),
            (kAudioHardwarePropertyDefaultInputDevice, .defaultDevice),
            (kAudioHardwarePropertyDefaultOutputDevice, .defaultDevice),
            (kAudioHardwarePropertyDefaultSystemOutputDevice, .defaultDevice)
        ]

        for (selector, kind) in selectors {
            var address = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectAddPropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                queue
            ) { _, _ in
                onChange(kind)
            }
        }
    }
}
