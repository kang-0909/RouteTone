import AppKit
import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject var model: AudioPriorityModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                behaviorSection
                prioritiesSection
            }
            .padding(20)
        }
        .frame(minWidth: 600, idealWidth: 620, minHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RouteTone")
                .font(.system(size: 18, weight: .semibold))
            Text("Automatically keep macOS on the highest-priority available input and output device.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Behavior")

            VStack(spacing: 0) {
                PreferenceRow(
                    title: "Auto-switch input",
                    subtitle: "Always route to the highest-priority available microphone.",
                    isOn: Binding(
                        get: { model.autoSwitchInputEnabled },
                        set: { model.setAutoSwitch($0, for: .input) }
                    )
                )

                Divider()
                    .padding(.leading, 14)

                PreferenceRow(
                    title: "Auto-switch output",
                    subtitle: "Keep playback and system output aligned to the best available speaker.",
                    isOn: Binding(
                        get: { model.autoSwitchOutputEnabled },
                        set: { model.setAutoSwitch($0, for: .output) }
                    )
                )

                Divider()
                    .padding(.leading, 14)

                PreferenceRow(
                    title: "Launch at login",
                    subtitle: "Unsigned local builds work best after moving the app into /Applications.",
                    isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )

                Divider()
                    .padding(.leading, 14)

                PreferenceRow(
                    title: "Show menu bar icon",
                    subtitle: "Turning this off applies on the next launch. Reopening RouteTone will open Settings directly.",
                    isOn: Binding(
                        get: { model.menuBarIconVisible },
                        set: { model.setMenuBarIconVisible($0) }
                    )
                )

            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.045))
            )
        }
    }

    private var prioritiesSection: some View {
        VStack(spacing: 14) {
            DirectionPriorityCard(direction: .output, items: model.rankedDevices(for: .output), model: model)
            DirectionPriorityCard(direction: .input, items: model.rankedDevices(for: .input), model: model)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

private struct PreferenceRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 16)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .frame(width: 38, alignment: .trailing)
                .padding(.top, 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

@MainActor
private struct DirectionPriorityCard: View {
    let direction: AudioDirection
    let items: [RankedDevice]
    @ObservedObject var model: AudioPriorityModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: direction.systemImageName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .center)
                Text(direction.title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(direction == .output ? "Open Output Settings" : "Open Input Settings") {
                    model.openSoundSettings(for: direction)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text(direction == .input
                 ? "The highest enabled and available microphone wins."
                 : "The highest enabled and available speaker wins. System output follows too.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            if items.isEmpty {
                Text("No \(direction.title.lowercased()) devices discovered yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                PriorityDeviceList(direction: direction, items: items, model: model)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }
}

@MainActor
private struct PriorityDeviceList: View {
    let direction: AudioDirection
    let items: [RankedDevice]
    @ObservedObject var model: AudioPriorityModel

    var body: some View {
        PriorityTableView(direction: direction, items: items, model: model)
        .frame(height: max(CGFloat(items.count) * 64, 76))
    }
}

@MainActor
private struct PriorityTableView: NSViewRepresentable {
    let direction: AudioDirection
    let items: [RankedDevice]
    let model: AudioPriorityModel

    func makeCoordinator() -> Coordinator {
        Coordinator(direction: direction, items: items, model: model)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let tableView = context.coordinator.tableView
        scrollView.documentView = tableView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.direction = direction
        context.coordinator.items = items
        context.coordinator.model = model
        context.coordinator.reloadDataPreservingDragState()
    }

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var direction: AudioDirection
        var items: [RankedDevice]
        var model: AudioPriorityModel
        let tableView: NSTableView

        private let columnIdentifier = NSUserInterfaceItemIdentifier("PriorityColumn")
        private let rowIdentifier = NSUserInterfaceItemIdentifier("PriorityRow")
        private let pasteboardType = NSPasteboard.PasteboardType("io.github.kang0909.RouteTone.priority-row")

        init(direction: AudioDirection, items: [RankedDevice], model: AudioPriorityModel) {
            self.direction = direction
            self.items = items
            self.model = model

            let tableView = NSTableView()
            let column = NSTableColumn(identifier: columnIdentifier)
            column.resizingMask = .autoresizingMask
            tableView.addTableColumn(column)
            tableView.headerView = nil
            tableView.rowHeight = 56
            tableView.intercellSpacing = NSSize(width: 0, height: 8)
            tableView.backgroundColor = .clear
            tableView.selectionHighlightStyle = .none
            tableView.focusRingType = .none
            tableView.allowsColumnReordering = false
            tableView.allowsColumnResizing = false
            tableView.allowsColumnSelection = false
            tableView.allowsTypeSelect = false
            tableView.usesAutomaticRowHeights = false
            tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
            tableView.style = .fullWidth
            tableView.registerForDraggedTypes([pasteboardType])
            tableView.setDraggingSourceOperationMask(.move, forLocal: true)
            tableView.frame = NSRect(x: 0, y: 0, width: 560, height: 200)

            self.tableView = tableView
            super.init()

            tableView.delegate = self
            tableView.dataSource = self
            tableView.draggingDestinationFeedbackStyle = .gap
        }

        func reloadDataPreservingDragState() {
            tableView.reloadData()
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            items.count
        }

        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            56
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let item = items[row]
            let view = (tableView.makeView(withIdentifier: rowIdentifier, owner: self) as? HostingTableCellView) ?? {
                let cell = HostingTableCellView(frame: .zero)
                cell.identifier = rowIdentifier
                return cell
            }()
            view.apply(rootView: AnyView(RankedDeviceRow(item: item, model: model)))
            return view
        }

        func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
            let item = NSPasteboardItem()
            item.setString(items[row].id, forType: pasteboardType)
            return item
        }

        func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
            tableView.setDropRow(row, dropOperation: .above)
            return .move
        }

        func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
            guard let draggedUID = info.draggingPasteboard.string(forType: pasteboardType) else { return false }
            guard let sourceIndex = items.firstIndex(where: { $0.id == draggedUID }) else { return false }

            let destinationIndex = row > sourceIndex ? row - 1 : row
            guard destinationIndex != sourceIndex else { return false }

            model.moveDevice(uid: draggedUID, to: destinationIndex, direction: direction)
            return true
        }
    }
}

private struct RankedDeviceRow: View {
    let item: RankedDevice
    @ObservedObject var model: AudioPriorityModel

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            DragHandle()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.record.name)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    if item.isCurrentDefault {
                        Badge(text: "Current", tint: .accentColor)
                    }
                    if !item.isAvailable {
                        Badge(text: "Offline", tint: .secondary)
                    }
                    if !item.isEnabled {
                        Badge(text: "Disabled", tint: .orange)
                    }
                }

                HStack(spacing: 6) {
                    MetadataPill(text: item.record.transportType.label)

                    if let manufacturer = item.record.manufacturer, !manufacturer.isEmpty {
                        MetadataPill(text: manufacturer)
                    }
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Button {
                    model.prioritize(uid: item.record.uid, direction: item.direction)
                } label: {
                    Image(systemName: "arrow.up.to.line.compact")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 10, height: 10)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help("Move to top")

                Toggle("", isOn: Binding(
                    get: { item.isEnabled },
                    set: { model.setDeviceEnabled($0, uid: item.record.uid, direction: item.direction) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .frame(width: 38, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

private struct DragHandle: View {
    private let columns = Array(repeating: GridItem(.fixed(3), spacing: 3), count: 2)
    @State private var isHovering = false

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<6, id: \.self) { _ in
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 3, height: 3)
            }
        }
        .frame(width: 14, height: 22)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            guard hovering != isHovering else { return }
            isHovering = hovering
            if hovering {
                NSCursor.openHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onDisappear {
            guard isHovering else { return }
            NSCursor.pop()
            isHovering = false
        }
    }
}

private final class HostingTableCellView: NSTableCellView {
    private var hostingView: NSHostingView<AnyView>?

    func apply(rootView: AnyView) {
        if let hostingView {
            hostingView.rootView = rootView
            return
        }

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.hostingView = hostingView
    }
}

private struct MetadataPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.05), in: Capsule())
    }
}

private struct Badge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.12), in: Capsule())
            .foregroundStyle(tint)
    }
}
