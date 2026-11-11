import AppKit
import Carbon
import SwiftUI

@main
struct InterpasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("interpaste", systemImage: "doc.on.clipboard") {
            Text("⌥V で形式を選んで貼り付け")
            Divider()
            Button("終了") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let paster = Paster()
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)

        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(optionKey)) { [paster] in
            paster.showMenu()
        }
    }
}
