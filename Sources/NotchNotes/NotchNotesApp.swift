import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = NoteStore()
    private var panelController: PanelController?
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let panelController = PanelController(store: store)
        self.panelController = panelController
        hotKey = GlobalHotKey { [weak panelController] in
            panelController?.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            panelController.show()
        }
    }

    func showPanel() { panelController?.show() }
    func hidePanel() { panelController?.hide() }
    func togglePanel() { panelController?.toggle() }
}

@main
struct NotchNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("todo list", systemImage: "checklist") {
            Button("打开 todo list") { appDelegate.showPanel() }
                .keyboardShortcut("n", modifiers: [.command])
            Button("显示/隐藏面板") { appDelegate.togglePanel() }
            Divider()
            Text("全局快捷键：⇧⌘空格")
            Divider()
            Button("退出 todo list") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: [.command])
        }
        .menuBarExtraStyle(.menu)

        Settings {
            Text("todo list 在菜单栏中运行。")
                .padding()
        }
    }
}
