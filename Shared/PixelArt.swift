import AppKit

/// 문자 그리드 → NSImage 픽셀 아트 렌더러. 메뉴바 아이콘(높이 18pt) 전용.
enum PixelArt {
    static let defaultPalette: [Character: NSColor] = [
        "#": .labelColor,           // 외곽선/본체 (다크·라이트 자동)
        "o": .secondaryLabelColor,  // 그림자
        ".": .clear,
        " ": .clear,
        "r": NSColor(red: 0.90, green: 0.30, blue: 0.30, alpha: 1),
        "g": NSColor(red: 0.35, green: 0.70, blue: 0.40, alpha: 1),
        "b": NSColor(red: 0.30, green: 0.55, blue: 0.90, alpha: 1),
        "y": NSColor(red: 0.95, green: 0.78, blue: 0.25, alpha: 1),
        "w": NSColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1),
        "k": NSColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1),
        "n": NSColor(red: 0.62, green: 0.45, blue: 0.30, alpha: 1), // 갈색
        "p": NSColor(red: 0.95, green: 0.60, blue: 0.70, alpha: 1), // 분홍
        "c": NSColor(red: 0.55, green: 0.85, blue: 0.95, alpha: 1), // 하늘
        "d": NSColor(red: 0.30, green: 0.30, blue: 0.55, alpha: 1), // 어두운 남색
    ]

    /// rows: 같은 너비의 문자열 배열. 세로 18px에 맞춰 스케일.
    static func render(_ rows: [String], palette: [Character: NSColor] = defaultPalette, height: CGFloat = 18, template: Bool = false) -> NSImage {
        let h = rows.count
        let w = rows.map { $0.count }.max() ?? 1
        let px = height / CGFloat(h)
        let size = NSSize(width: CGFloat(w) * px, height: height)
        let img = NSImage(size: size)
        img.lockFocus()
        for (y, row) in rows.enumerated() {
            for (x, ch) in row.enumerated() {
                guard let c = palette[ch], c != .clear else { continue }
                c.setFill()
                let rect = NSRect(x: CGFloat(x) * px, y: CGFloat(h - 1 - y) * px, width: px, height: px)
                rect.fill()
            }
        }
        img.unlockFocus()
        img.isTemplate = template
        return img
    }

    /// 여러 스프라이트를 가로로 이어 붙임 (간격 px).
    static func hstack(_ images: [NSImage], gap: CGFloat = 2) -> NSImage {
        let h = images.map { $0.size.height }.max() ?? 18
        let w = images.reduce(0) { $0 + $1.size.width } + gap * CGFloat(max(0, images.count - 1))
        let img = NSImage(size: NSSize(width: w, height: h))
        img.lockFocus()
        var x: CGFloat = 0
        for i in images {
            i.draw(at: NSPoint(x: x, y: (h - i.size.height) / 2), from: .zero, operation: .sourceOver, fraction: 1)
            x += i.size.width + gap
        }
        img.unlockFocus()
        return img
    }

    /// 텍스트를 메뉴바 높이의 작은 이미지로.
    static func text(_ s: String, size: CGFloat = 11) -> NSImage {
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: .medium), .foregroundColor: NSColor.labelColor]
        let str = NSAttributedString(string: s, attributes: attrs)
        let sz = str.size()
        let img = NSImage(size: NSSize(width: ceil(sz.width), height: 18))
        img.lockFocus()
        str.draw(at: NSPoint(x: 0, y: (18 - sz.height) / 2))
        img.unlockFocus()
        return img
    }
}
