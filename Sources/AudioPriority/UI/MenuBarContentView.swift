import AppKit
import SwiftUI

private enum PanelTypography {
    static let header = Font.system(size: 16, weight: .semibold)
    static let section = Font.system(size: 12, weight: .semibold)
    static let body = Font.system(size: 12, weight: .semibold)
    static let caption = Font.system(size: 11)
}

@MainActor
struct MenuBarContentView: View {
    @ObservedObject var model: AudioPriorityModel
    let dismissAction: (() -> Void)?

    init(model: AudioPriorityModel, dismissAction: (() -> Void)? = nil) {
        self.model = model
        self.dismissAction = dismissAction
    }

    var body: some View {
        panelContent(useLiquidGlass: false)
            .padding(16)
            .frame(width: 304)
            .background(MenuPanelWindowConfigurator(clearBackground: true))
            .modifier(MenuPanelBackgroundModifier(useLiquidGlass: false))
    }

    @ViewBuilder
    private func panelContent(useLiquidGlass: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                StatusCard(
                    title: "Output",
                    systemImage: "speaker.wave.2.fill",
                    primaryText: model.currentOutput?.name ?? "No output device",
                    secondaryText: model.currentOutput?.transportType.label ?? "Waiting for device",
                    useLiquidGlass: useLiquidGlass
                )

                StatusCard(
                    title: "Input",
                    systemImage: "mic.fill",
                    primaryText: model.currentInput?.name ?? "No input device",
                    secondaryText: model.currentInput?.transportType.label ?? "Waiting for device",
                    useLiquidGlass: useLiquidGlass
                )
            }

            VStack(spacing: 8) {
                CompactToggleRow(
                    title: "Auto-switch Input",
                    isOn: Binding(
                        get: { model.autoSwitchInputEnabled },
                        set: { model.setAutoSwitch($0, for: .input) }
                    )
                )

                CompactToggleRow(
                    title: "Auto-switch Output",
                    isOn: Binding(
                        get: { model.autoSwitchOutputEnabled },
                        set: { model.setAutoSwitch($0, for: .output) }
                    )
                )
            }

            if let error = model.lastError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Divider()

            Text("Top Priority")
                .font(PanelTypography.section)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                CompactPriorityLine(direction: .output, items: model.rankedDevices(for: .output))
                CompactPriorityLine(direction: .input, items: model.rankedDevices(for: .input))
            }

            HStack(spacing: 8) {
                PanelActionButton(
                    title: "App Settings",
                    prominent: true,
                    useLiquidGlass: useLiquidGlass,
                    width: 98
                ) {
                    dismissPanel {
                        model.showSettingsWindow()
                    }
                }

                PanelActionButton(
                    title: "System Settings",
                    prominent: false,
                    useLiquidGlass: useLiquidGlass,
                    width: 98
                ) {
                    dismissPanel {
                        model.openSoundSettings()
                    }
                }
                
                PanelActionButton(
                    title: "Quit",
                    prominent: false,
                    useLiquidGlass: useLiquidGlass,
                    width: 60
                ) {
                    NSApp.terminate(nil)
                }
            }
            .padding(.top, 6)
        }
    }

    private func dismissPanel(action: @escaping @MainActor () -> Void) {
        dismissAction?()
        if dismissAction == nil {
            let panelWindow = NSApp.keyWindow
            panelWindow?.close()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            Task { @MainActor in
                action()
            }
        }
    }
}

private struct PanelActionButton: View {
    let title: String
    let prominent: Bool
    let useLiquidGlass: Bool
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Group {
            if prominent {
                Button(title, action: action)
                    .buttonStyle(.borderedProminent)
            } else {
                Button(title, action: action)
                    .buttonStyle(.bordered)
            }
        }
        .controlSize(.small)
        .font(PanelTypography.body)
        .frame(width: width)
    }
}

private struct StatusCard: View {
    let title: String
    let systemImage: String
    let primaryText: String
    let secondaryText: String
    let useLiquidGlass: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, height: 14, alignment: .center)
                Text(title)
                    .font(PanelTypography.section)
                    .foregroundStyle(.secondary)
            }

            Text(primaryText)
                .font(PanelTypography.body)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(secondaryText)
                .font(PanelTypography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .modifier(PanelCardBackgroundModifier(useLiquidGlass: useLiquidGlass))
    }
}

private struct PanelBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let alpha: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        view.alphaValue = alpha
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.alphaValue = alpha
    }
}

private struct MenuPanelWindowConfigurator: NSViewRepresentable {
    let clearBackground: Bool

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.isOpaque = !clearBackground
            window.backgroundColor = clearBackground ? .clear : .windowBackgroundColor
            window.hasShadow = true
        }
    }
}

private struct MenuPanelBackgroundModifier: ViewModifier {
    let useLiquidGlass: Bool

    func body(content: Content) -> some View {
        if useLiquidGlass {
            content.background(Color.clear)
        } else {
            content.background {
                ZStack {
                    PanelBackground(
                        material: .popover,
                        alpha: 0.9
                    )
                    Color.white.opacity(0.11)
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.11),
                            Color.white.opacity(0.05),
                            Color.blue.opacity(0.022)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
    }
}

private struct PanelCardBackgroundModifier: ViewModifier {
    let useLiquidGlass: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.17))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.11), lineWidth: 0.8)
            )
    }
}

private struct CompactToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(PanelTypography.body)
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .frame(width: 38, alignment: .trailing)
        }
    }
}

private struct CompactPriorityLine: View {
    let direction: AudioDirection
    let items: [RankedDevice]

    var body: some View {
        let preview = items.prefix(3).map(\.record.name).joined(separator: "  ·  ")

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: direction.systemImageName)
                .foregroundStyle(.secondary)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 16, height: 16, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(direction.title)
                    .font(PanelTypography.section)
                Text(preview.isEmpty ? "No devices yet" : preview)
                    .font(PanelTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}
