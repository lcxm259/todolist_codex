import AppKit

@main
enum NotchNotesApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        delegate.start()
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = NoteStore()
    private var panelController: PanelController?
    private var statusItem: NSStatusItem?
    private var didStart = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        start()
    }

    func start() {
        guard !didStart else { return }
        didStart = true
        let panelController = PanelController(store: store)
        self.panelController = panelController
        configureStatusItem()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.showPanel()
        }
    }

    private func showPanel(anchor button: NSStatusBarButton? = nil) {
        panelController?.show(anchor: screenFrame(for: button))
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "todo list")
                ?? NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "todo list") {
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageLeading
            }
            button.title = "todo"
            button.toolTip = "todo list"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            _ = button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = statusItem
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            showPanel(anchor: sender)
            return
        }

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showStatusMenu()
        } else {
            showPanel(anchor: sender)
        }
    }

    private func screenFrame(for button: NSStatusBarButton?) -> CGRect? {
        guard
            let button,
            let window = button.window
        else { return nil }

        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }

    private func showStatusMenu() {
        guard let statusItem else { return }
        let menu = NSMenu()
        let quitItem = NSMenuItem(
            title: "退出 todo list",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
