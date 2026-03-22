import CoreAudio
import Foundation

final class AudioHardwareMonitor {
    private let queue = DispatchQueue(label: "RouteTone.AudioHardwareMonitor")
    private var hasStarted = false

    func start(onChange: @escaping () -> Void) {
        guard !hasStarted else { return }
        hasStarted = true

        let selectors: [AudioObjectPropertySelector] = [
            kAudioHardwarePropertyDevices,
            kAudioHardwarePropertyDefaultInputDevice,
            kAudioHardwarePropertyDefaultOutputDevice,
            kAudioHardwarePropertyDefaultSystemOutputDevice
        ]

        for selector in selectors {
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
                onChange()
            }
        }
    }
}
