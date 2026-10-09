import AppKit

/// 자세 알림 거북이: 일정 시간마다 거북이가 목을 빼고 쳐다본다. 클릭하면 "허리 폈어요".
final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()
    let d = UserDefaults.standard
    var interval: Int { get { max(5, d.integer(forKey: "interval") == 0 ? 45 : d.integer(forKey: "interval")) } set { d.set(newValue, forKey: "interval") } }
    var lastStretch = Date()
    var logKey: String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return "stretch-" + f.string(from: Date()) }
    var count: Int { get { d.integer(forKey: logKey) } set { d.set(newValue, forKey: logKey) } }

    let hidden: [String] = ["............", "............", "............", "....gggggg..", "...gggggggg.", "..gg.gg.gg.g", "..gggggggggg", "...gggggggg.", "....gg..gg..", "............"]
    let peek: [[String]] = [
        ["g#g.........", "ggg.........", ".g..........", ".g..gggggg..", ".g.gggggggg.", ".ggg.gg.gg.g", "..gggggggggg", "...gggggggg.", "....gg..gg..", "............"],
        ["............", "g#g.........", "ggg.........", ".g..gggggg..", ".g.gggggggg.", ".ggg.gg.gg.g", "..gggggggggg", "...gggggggg.", "....gg..gg..", "............"],
    ]

    func applicationDidFinishLaunching(_ n: Notification) {
        bar.frameProvider = { [weak self] t in self?.frame(t) ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.onClick = { [weak self] in self?.stretched() }
        bar.setInterval(0.6)
    }

    var due: Bool { Date().timeIntervalSince(lastStretch) >= Double(interval) * 60 }

    func frame(_ t: Int) -> NSImage {
        if due { return PixelArt.render(peek[t % 2]) }
        let remain = Int(Double(interval) * 60 - Date().timeIntervalSince(lastStretch)) / 60
        return PixelArt.hstack([PixelArt.render(hidden), PixelArt.text("\(remain)")], gap: 3)
    }

    func stretched() {
        if due { count += 1 }
        lastStretch = Date()
    }

    func menu() -> NSMenu {
        let m = NSMenu()
        m.add(due ? "🐢 허리 펴고 어깨 돌릴 시간!" : "다음 알림까지 \(Int(Double(interval) * 60 - Date().timeIntervalSince(lastStretch)) / 60)분")
        m.add("허리 폈어요 (왼쪽 클릭과 동일)", key: "s") { [weak self] in self?.stretched() }
        m.add("오늘 스트레칭 \(count)회")
        m.addItem(.separator())
        for v in [25, 45, 60, 90] {
            let it = m.add("\(v)분마다") { [weak self] in self?.interval = v }
            it.state = v == interval ? .on : .off
        }
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
