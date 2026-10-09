import AppKit

/// 가족 메뉴바: 사진 폴더에서 하루 한 장씩 동그란 아이콘으로, 기념일 D-day 표시.
final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()
    let d = UserDefaults.standard
    var folder: URL? { get { (d.string(forKey: "folder")).map { URL(fileURLWithPath: $0) } } set { d.set(newValue?.path, forKey: "folder") } }
    /// "이름|MM-DD" 형식
    var events: [String] { get { d.stringArray(forKey: "events") ?? [] } set { d.set(newValue, forKey: "events") } }
    var photos: [URL] = []

    let placeholder: [String] = ["...pppp.....", "..pppppp....", "..p#pp#p....", "..pppppp....", "...pppp.....", ".ppppppppp..", "ppppppppppp.", "ppppppppppp.", ".pp.....pp..", "............"]

    func applicationDidFinishLaunching(_ n: Notification) {
        loadPhotos()
        bar.frameProvider = { [weak self] _ in self?.frame() ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.setInterval(600)
    }

    func loadPhotos() {
        guard let f = folder, let items = try? FileManager.default.contentsOfDirectory(at: f, includingPropertiesForKeys: nil) else { photos = []; return }
        photos = items.filter { ["jpg", "jpeg", "png", "heic"].contains($0.pathExtension.lowercased()) }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// 날짜 기준으로 사진 1장 고정 선택
    var todayPhoto: NSImage? {
        guard !photos.isEmpty else { return nil }
        let day = Int(Date().timeIntervalSince1970 / 86400)
        return NSImage(contentsOf: photos[day % photos.count])
    }

    func circle(_ src: NSImage, size: CGFloat = 18) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size)).addClip()
        let s = src.size; let scale = max(size / s.width, size / s.height)
        let w = s.width * scale, h = s.height * scale
        src.draw(in: NSRect(x: (size - w) / 2, y: (size - h) / 2, width: w, height: h), from: .zero, operation: .sourceOver, fraction: 1)
        img.unlockFocus()
        return img
    }

    func nearest() -> (String, Int)? {
        let cal = Calendar.current; let today = cal.startOfDay(for: Date())
        var best: (String, Int)?
        for e in events {
            let p = e.split(separator: "|"); guard p.count == 2 else { continue }
            let md = p[1].split(separator: "-").compactMap { Int($0) }; guard md.count == 2 else { continue }
            var c = cal.dateComponents([.year], from: today); c.month = md[0]; c.day = md[1]
            guard var date = cal.date(from: c) else { continue }
            if date < today { c.year! += 1; date = cal.date(from: c)! }
            let days = cal.dateComponents([.day], from: today, to: date).day ?? 0
            if best == nil || days < best!.1 { best = (String(p[0]), days) }
        }
        return best
    }

    func frame() -> NSImage {
        let icon = todayPhoto.map { circle($0) } ?? PixelArt.render(placeholder)
        if let (name, days) = nearest(), days <= 30 {
            return PixelArt.hstack([icon, PixelArt.text(days == 0 ? "\(name) D-DAY" : "\(name) D-\(days)")], gap: 4)
        }
        return icon
    }

    func pickFolder() {
        let p = NSOpenPanel(); p.canChooseDirectories = true; p.canChooseFiles = false
        NSApp.activate(ignoringOtherApps: true)
        if p.runModal() == .OK, let u = p.url { folder = u; loadPhotos(); bar.refresh() }
    }

    func menu() -> NSMenu {
        let m = NSMenu()
        m.add("사진 \(photos.count)장 · \(folder?.lastPathComponent ?? "폴더 미설정")")
        m.add("사진 폴더 고르기…") { [weak self] in self?.pickFolder() }
        m.addItem(.separator())
        for e in events { let p = e.split(separator: "|"); m.add("\(p[0])  \(p.count > 1 ? p[1] : "")") }
        m.add("기념일 추가…") { [weak self] in
            if let s = promptText("기념일 추가", "이름|MM-DD (예: 요요 생일|03-14)"), s.contains("|") { self?.events.append(s); self?.bar.refresh() }
        }
        if !events.isEmpty { m.add("기념일 전체 삭제") { [weak self] in self?.events = []; self?.bar.refresh() } }
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
