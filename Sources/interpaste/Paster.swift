import AppKit
import UniformTypeIdentifiers

@MainActor
final class Paster: NSObject {
    private let pb = NSPasteboard.general
    private var chosen: NSPasteboard.PasteboardType?

    private static let sqrt = NSPasteboard.PasteboardType("interpaste.sqrt")

    func showMenu() {
        let target = NSWorkspace.shared.frontmostApplication
        let items = pb.pasteboardItems ?? []

        func listed(_ t: NSPasteboard.PasteboardType) -> Bool {
            guard t.rawValue.hasPrefix("public.") else { return false }
            return !(UTType(t.rawValue)?.conforms(to: .movie) ?? false)
        }
        var types: [NSPasteboard.PasteboardType] = []
        for item in items {
            for t in item.types where listed(t) && !types.contains(t) {
                types.append(t)
            }
        }
        if types.contains(where: EntryContent.isImage) {
            types.removeAll { !EntryContent.isImage($0) }
        }
        if types.contains(.string) {
            types.removeAll { $0 != .string && (UTType($0.rawValue)?.conforms(to: .plainText) ?? false) }
        }
        let menu = NSMenu()
        menu.autoenablesItems = false
        let sqrtItem = NSMenuItem(title: "√", action: #selector(pick(_:)), keyEquivalent: "")
        sqrtItem.target = self
        sqrtItem.representedObject = Self.sqrt.rawValue
        menu.addItem(sqrtItem)
        if !types.isEmpty { menu.addItem(.separator()) }
        for t in types {
            let mi = NSMenuItem(title: EntryContent.label(for: t), action: #selector(pick(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = t.rawValue
            if EntryContent.isImage(t), let data = items.lazy.compactMap({ $0.data(forType: t) }).first {
                mi.image = EntryContent.thumbnail(data: data)
            }
            menu.addItem(mi)
        }

        chosen = nil
        NSApp.activate(ignoringOtherApps: true)
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        if let f = screen?.visibleFrame {
            let size = menu.size
            menu.popUp(positioning: nil, at: NSPoint(x: f.midX - size.width / 2, y: f.midY + size.height / 2), in: nil)
        }

        guard let type = chosen else {
            target?.activate(options: [])
            return
        }
        if type == Self.sqrt {
            target?.activate(options: [])
            Self.waitUntilFrontmost(target, deadline: Date().addingTimeInterval(2)) {
                Self.typeText("√")
            }
            return
        }
        paste(type, into: target)
    }

    @objc private func pick(_ sender: NSMenuItem) {
        chosen = NSPasteboard.PasteboardType(sender.representedObject as! String)
    }

    private func paste(_ type: NSPasteboard.PasteboardType, into target: NSRunningApplication?) {
        let original: [[(NSPasteboard.PasteboardType, Data)]] = (pb.pasteboardItems ?? []).map { item in
            item.types.compactMap { t in item.data(forType: t).map { (t, $0) } }
        }

        let richText = UTType(type.rawValue).map { $0.conforms(to: .text) && !$0.conforms(to: .plainText) } ?? false
        func keep(_ t: NSPasteboard.PasteboardType) -> Bool {
            if t == type { return true }
            guard richText else { return false }
            return t == .string || !t.rawValue.hasPrefix("public.")
        }

        let only = original.compactMap { reps -> NSPasteboardItem? in
            guard reps.contains(where: { $0.0 == type }) else { return nil }
            let pi = NSPasteboardItem()
            for (t, d) in reps where keep(t) { pi.setData(d, forType: t) }
            return pi
        }
        pb.clearContents()
        pb.writeObjects(only)
        let written = pb.changeCount

        target?.activate(options: [])
        let pb = self.pb
        Self.waitUntilFrontmost(target, deadline: Date().addingTimeInterval(2)) {
            Self.postCommandV()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard pb.changeCount == written else { return }
                let restored = original.map { reps -> NSPasteboardItem in
                    let pi = NSPasteboardItem()
                    for (t, d) in reps { pi.setData(d, forType: t) }
                    return pi
                }
                pb.clearContents()
                pb.writeObjects(restored)
            }
        }
    }

    private static func waitUntilFrontmost(_ target: NSRunningApplication?, deadline: Date, then action: @escaping @MainActor () -> Void) {
        let front = NSWorkspace.shared.frontmostApplication
        if target == nil || front?.processIdentifier == target?.processIdentifier || Date() > deadline {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { action() }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            waitUntilFrontmost(target, deadline: deadline, then: action)
        }
    }

    private static func typeText(_ text: String) {
        let utf16 = Array(text.utf16)
        let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
        for e in [down, up] {
            e?.flags = []
            e?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        }
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private static func postCommandV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 9
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
