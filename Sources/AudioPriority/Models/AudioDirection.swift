import Foundation

enum AudioDirection: String, Codable, CaseIterable, Hashable {
    case input
    case output

    var title: String {
        switch self {
        case .input:
            return "Input"
        case .output:
            return "Output"
        }
    }

    var systemImageName: String {
        switch self {
        case .input:
            return "mic.fill"
        case .output:
            return "speaker.wave.2.fill"
        }
    }
}
