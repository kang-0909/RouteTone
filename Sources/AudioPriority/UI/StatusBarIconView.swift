import SwiftUI

struct StatusBarIconView: View {
    let state: AudioPriorityModel.MenuBarIconState

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .symbolRenderingMode(.monochrome)
            .opacity(state == .inactive ? 0.58 : 1)
        .accessibilityLabel("RouteTone")
    }

    private var symbolName: String {
        switch state {
        case .normal:
            return "speaker.wave.2.fill"
        case .inactive:
            return "speaker.slash.fill"
        case .error:
            return "speaker.badge.exclamationmark.fill"
        }
    }
}
