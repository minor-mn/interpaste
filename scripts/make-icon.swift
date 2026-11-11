// アプリのアイコン(1024×1024 の PNG)を描く。使い方: swift scripts/make-icon.swift <出力先.png>
// クリップボードの上に、貼り付ける形式を選ぶメニューが割り込んで開いている絵。
import AppKit

let size = 1024.0
let output = CommandLine.arguments[1]

func color(_ hex: Int, _ alpha: Double = 1) -> CGColor {
  CGColor(
    srgbRed: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255,
    alpha: alpha)
}

func rounded(_ rect: CGRect, _ radius: Double) -> CGPath {
  CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
  data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: space,
  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// macOS のアイコンの形(角の丸い四角。周りに余白を空ける)。
let plate = CGRect(x: 100, y: 100, width: 824, height: 824)
let platePath = rounded(plate, 185)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.45))
ctx.addPath(platePath)
ctx.setFillColor(color(0x1B1F3B))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(platePath)
ctx.clip()
let bg = CGGradient(colorsSpace: space, colors: [color(0x3B2B8F), color(0x0E6E7A)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: plate.minX, y: plate.maxY), end: CGPoint(x: plate.maxX, y: plate.minY), options: [])

// クリップボードの板。
let board = CGRect(x: 230, y: 190, width: 440, height: 600)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 24, color: color(0x000000, 0.35))
ctx.addPath(rounded(board, 48))
ctx.setFillColor(color(0xC98A4B))
ctx.fillPath()
ctx.restoreGState()

// 板に挟んだ紙。
let paper = board.insetBy(dx: 34, dy: 34).offsetBy(dx: 0, dy: -10)
ctx.addPath(rounded(paper, 20))
ctx.setFillColor(color(0xF7F4EC))
ctx.fillPath()

// 紙の上の文字の行。
ctx.setFillColor(color(0xB9B4A8))
for (i, w) in [300.0, 250, 320, 200, 280].enumerated() {
  ctx.addPath(rounded(CGRect(x: paper.minX + 40, y: paper.maxY - 130 - Double(i) * 70, width: w, height: 26), 13))
  ctx.fillPath()
}

// クリップ。
let clip = CGRect(x: board.midX - 95, y: board.maxY - 50, width: 190, height: 90)
ctx.addPath(rounded(clip, 26))
ctx.setFillColor(color(0x8E949E))
ctx.fillPath()
ctx.addPath(rounded(clip.insetBy(dx: 60, dy: 30).offsetBy(dx: 0, dy: 12), 12))
ctx.setFillColor(color(0x1B1F3B, 0.6))
ctx.fillPath()

// 割り込んで開いたメニュー。
let menu = CGRect(x: 470, y: 250, width: 380, height: 330)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 36, color: color(0x000000, 0.55))
ctx.addPath(rounded(menu, 40))
ctx.setFillColor(color(0x23252B))
ctx.fillPath()
ctx.restoreGState()
ctx.addPath(rounded(menu, 40))
ctx.setStrokeColor(color(0xFFFFFF, 0.12))
ctx.setLineWidth(4)
ctx.strokePath()

// メニューの3行(真ん中を選択中)。
let rowH = 78.0
for i in 0..<3 {
  let y = menu.maxY - 40 - rowH * Double(i + 1) - 10 * Double(i)
  let row = CGRect(x: menu.minX + 22, y: y, width: menu.width - 44, height: rowH)
  if i == 1 {
    ctx.addPath(rounded(row, 20))
    ctx.setFillColor(color(0x2F7CF6))
    ctx.fillPath()
  }
  ctx.addPath(rounded(CGRect(x: row.minX + 28, y: row.midY - 13, width: [190.0, 230, 150][i], height: 26), 13))
  ctx.setFillColor(i == 1 ? color(0xFFFFFF) : color(0xD8DBE2, 0.85))
  ctx.fillPath()
}
ctx.restoreGState()

let image = ctx.makeImage()!
let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: output))
