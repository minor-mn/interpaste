import AppKit
import UniformTypeIdentifiers

// 一般クリップボードの全アイテム・全形式を表示する。
// 使い方: pbdump [--full]
//   --full  テキストは全文、バイナリは全バイトを表示(既定は先頭のみ)

let full = CommandLine.arguments.contains("--full")
let textPreviewLimit = 2000
let hexPreviewLimit = 256

let pb = NSPasteboard.general
print("changeCount: \(pb.changeCount)")

guard let items = pb.pasteboardItems, !items.isEmpty else {
    print("(クリップボードは空です)")
    exit(0)
}

print("items: \(items.count)")

for (i, item) in items.enumerated() {
    print("\n==================== item[\(i)] ====================")
    for type in item.types {
        let uti = UTType(type.rawValue)
        let desc = uti?.localizedDescription ?? "-"
        print("\n--- \(type.rawValue)  (\(desc))")

        guard let data = item.data(forType: type) else {
            print("    (データ取得不可)")
            continue
        }
        print("    \(data.count) bytes")

        if let text = decodeText(data, type: type, uti: uti) {
            let shown = full ? text : String(text.prefix(textPreviewLimit))
            print(indent(shown))
            if !full && text.count > textPreviewLimit {
                print("    … (残り \(text.count - textPreviewLimit) 文字, --full で全表示)")
            }
        } else {
            let bytes = full ? data : data.prefix(hexPreviewLimit)
            print(hexDump(bytes))
            if !full && data.count > hexPreviewLimit {
                print("    … (残り \(data.count - hexPreviewLimit) bytes, --full で全表示)")
            }
        }
    }
}

// テキストとして読める形式ならデコードする
func decodeText(_ data: Data, type: NSPasteboard.PasteboardType, uti: UTType?) -> String? {
    let isText = uti.map { $0.conforms(to: .text) || $0.conforms(to: .propertyList) || $0.conforms(to: .url) } ?? false
    if isText {
        if type.rawValue.contains("utf16"), let s = String(data: data, encoding: .utf16LittleEndian) { return s }
        if let s = String(data: data, encoding: .utf8), !s.contains("\u{0}") { return s }
        if let s = String(data: data, encoding: .utf16) { return s }
    }
    // バイナリplist は XML に変換して表示
    if data.starts(with: Array("bplist".utf8)),
       let obj = try? PropertyListSerialization.propertyList(from: data, format: nil),
       let xml = try? PropertyListSerialization.data(fromPropertyList: obj, format: .xml, options: 0) {
        return "(binary plist → XML)\n" + (String(data: xml, encoding: .utf8) ?? "")
    }
    // 未知の形式でも UTF-8 として妥当(NUL なし)ならテキストとして表示
    if let s = String(data: data, encoding: .utf8), !s.contains("\u{0}") { return s }
    return nil
}

func indent(_ s: String) -> String {
    s.split(separator: "\n", omittingEmptySubsequences: false)
        .map { "    " + $0 }
        .joined(separator: "\n")
}

func hexDump(_ data: Data) -> String {
    var lines: [String] = []
    let bytes = [UInt8](data)
    for offset in stride(from: 0, to: bytes.count, by: 16) {
        let chunk = bytes[offset..<min(offset + 16, bytes.count)]
        let hex = chunk.map { String(format: "%02x", $0) }.joined(separator: " ")
        let ascii = chunk.map { (0x20...0x7e).contains($0) ? String(UnicodeScalar($0)) : "." }.joined()
        lines.append(String(format: "    %08x  ", offset) + hex.padding(toLength: 48, withPad: " ", startingAt: 0) + " " + ascii)
    }
    return lines.joined(separator: "\n")
}
