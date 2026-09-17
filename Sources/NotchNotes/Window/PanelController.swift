import AppKit
import SwiftUI

enum PanelAppearance {
    static let cornerRadius: CGFloat = 18
}

enum PanelGeometry {
    static func frame(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        safeTop: CGFloat,
        hasNotch: Bool,
        size: CGSize
    ) -> CGRect {
        let x = screenFrame.midX - (size.width / 2)
        let top = hasNotch
            ? screenFrame.maxY - max(safeTop, 28) - 8
            : visibleFrame.maxY - 8
        return CGRect(x: x, y: top - size.height, width: size.width, height: size.height)
    }
}

private final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class PanelController {
    private let panel: NotchPanel
    private let size = CGSize(width: 420, height: 560)

    init(store: NoteStore) {
        panel = NotchPanel(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        let hostingController = NSHostingController(
            rootView: NotchNotesView(store: store) { [weak panel] in
                panel?.orderOut(nil)
            }
        )
        panel.contentViewController = hostingController

        let hostingView = hostingController.view
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = PanelAppearance.cornerRadius
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
    }

    var isVisible: Bool { panel.isVisible }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show(anchor: CGRect? = nil) {
        positionPanel(anchor: anchor)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak panel] in
            panel?.orderOut(nil)
            panel?.alphaValue = 1
        })
    }

    private func positionPanel(anchor: CGRect?) {
        let screen: NSScreen?
        if let anchor {
            let anchorPoint = CGPoint(x: anchor.midX, y: anchor.midY)
            screen = NSScreen.screens.first { $0.frame.contains(anchorPoint) } ?? NSScreen.main
        } else {
            let mouseLocation = NSEvent.mouseLocation
            screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        }
        guard let screen else { return }
        let hasNotch = screen.safeAreaInsets.top > 0
            && screen.auxiliaryTopLeftArea != nil
            && screen.auxiliaryTopRightArea != nil
        let frame = PanelGeometry.frame(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            safeTop: screen.safeAreaInsets.top,
            hasNotch: hasNotch,
            size: size
        )
        panel.setFrame(frame, display: true)
    }
}
