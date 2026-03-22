import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let model: AudioPriorityModel
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []

    init(model: AudioPriorityModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        configurePopover()
        bindModel()
        updateButtonImage()
    }

    func removeFromStatusBar() {
        closePopover()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 304, height: 340)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(model: model, dismissAction: { [weak self] in
                self?.closePopover()
            })
        )
    }

    private func bindModel() {
        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateButtonImage()
            }
            .store(in: &cancellables)
    }

    private func updateButtonImage() {
        guard let button = statusItem.button else { return }
        let image = makeStatusImage(for: model.menuBarIconState)
        image?.isTemplate = true
        button.image = image
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
            return
        }

        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        configurePopoverWindow()
    }

    func closePopover() {
        popover.performClose(nil)
    }

    func popoverWillShow(_ notification: Notification) {
        configurePopoverWindow()
    }

    private func configurePopoverWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let window = self.popover.contentViewController?.view.window else { return }

            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovable = false
            window.acceptsMouseMovedEvents = true
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
        }
    }

    private func makeStatusImage(for state: AudioPriorityModel.MenuBarIconState) -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.black.setFill()
        drawStatusGlyph(in: CGRect(origin: .zero, size: size), state: state)

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func drawStatusGlyph(in rect: CGRect, state: AudioPriorityModel.MenuBarIconState) {
        let trackWidth: CGFloat = 1.7
        let trackHeight: CGFloat = 11.6
        let knobVerticalOffset: CGFloat = 0.9
        let centers: [CGFloat] = [4.3, 9.0, 13.7]
        let knobPositions: [CGFloat] = [7.0 + knobVerticalOffset, 5.2 + knobVerticalOffset, 9.0 + knobVerticalOffset]

        for index in 0..<3 {
            let trackRect = CGRect(
                x: rect.minX + centers[index] - trackWidth / 2,
                y: rect.midY - trackHeight / 2,
                width: trackWidth,
                height: trackHeight
            )
            let path = NSBezierPath(roundedRect: trackRect, xRadius: trackWidth / 2, yRadius: trackWidth / 2)
            path.fill()

            let knobRect = CGRect(
                x: rect.minX + centers[index] - 2.25,
                y: rect.minY + knobPositions[index] - 2.25,
                width: 4.5,
                height: 4.5
            )
            let knob = NSBezierPath(ovalIn: knobRect)
            knob.fill()
        }

        switch state {
        case .normal:
            break
        case .inactive:
            let slash = NSBezierPath()
            slash.move(to: CGPoint(x: rect.minX + 2.3, y: rect.maxY - 2.3))
            slash.line(to: CGPoint(x: rect.maxX - 2.3, y: rect.minY + 2.3))
            slash.lineWidth = 1.9
            slash.lineCapStyle = .round
            slash.stroke()
        case .error:
            let mark = NSBezierPath(roundedRect: CGRect(x: rect.maxX - 3.8, y: rect.midY - 0.8, width: 1.7, height: 4.8), xRadius: 0.85, yRadius: 0.85)
            mark.fill()
            let dot = NSBezierPath(ovalIn: CGRect(x: rect.maxX - 3.85, y: rect.midY - 3.65, width: 1.8, height: 1.8))
            dot.fill()
        }
    }
}
