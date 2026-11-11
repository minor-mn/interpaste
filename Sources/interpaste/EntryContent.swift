import AppKit
import ImageIO
import UniformTypeIdentifiers

enum EntryContent {
    private static let thumbSize = NSSize(width: 200, height: 120)

    static func label(for type: NSPasteboard.PasteboardType) -> String {
        let uti = UTType(type.rawValue)
        switch type.rawValue {
        case "public.html": return "書式あり"
        case "public.rtf": return "書式あり(RTF)"
        case "public.file-url": return "ファイル"
        case "public.url": return "URL"
        default: break
        }
        if let uti, uti.conforms(to: .plainText) { return "書式なし" }
        if let uti, uti.conforms(to: .image) {
            let ext = uti.preferredFilenameExtension
                ?? type.rawValue.split(separator: ".").last.map(String.init)
                ?? ""
            return ext.uppercased()
        }
        return type.rawValue
    }

    static func isImage(_ type: NSPasteboard.PasteboardType) -> Bool {
        UTType(type.rawValue)?.conforms(to: .image) ?? false
    }

    static func thumbnail(data: Data) -> NSImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return nil }
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(thumbSize.width, thumbSize.height) * scale,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        return NSImage(cgImage: cg, size: fit(NSSize(width: CGFloat(cg.width) / scale, height: CGFloat(cg.height) / scale), in: thumbSize))
    }

    private static func fit(_ size: NSSize, in box: NSSize) -> NSSize {
        guard size.width > 0, size.height > 0 else { return box }
        let s = min(1, box.width / size.width, box.height / size.height)
        return NSSize(width: size.width * s, height: size.height * s)
    }
}
