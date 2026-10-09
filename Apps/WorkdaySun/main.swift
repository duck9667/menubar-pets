import AppKit

/// 퇴근 카운트다운 해: 출근부터 퇴근까지 해가 떠서 진다. 야근이면 달이 뜬다.
final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()
    let d = UserDefaults.standard
    var startMin: Int { get { d.object(forKey: "start") as? Int ?? 9 * 60 } set { d.set(newValue, forKey: "start") } }
    var endMin: Int { get { d.object(forKey: "end") as? Int ?? 18 * 60 } set { d.set(newValue, forKey: "end") } }

    func applicationDidFinishLaunching(_ n: Notification) {
        bar.frameProvider = { [weak self] t in self?.frame(t) ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.setInterval(30)
    }

    var nowMin: Int { let c = Calendar.current.dateComponents([.hour, .minute], from: Date()); return c.hour! * 60 + c.minute! }

    func frame(_ t: Int) -> NSImage {
        let now = nowMin
        var g = Array(repeating: Array(repeating: Character("."), count: 16), count: 10)
        // 지평선
        for x in 0..<16 { g[8][x] = "#" }
        let label: String
        if now < startMin {
            // 출근 전: 지평선 아래 해
            for x in 6...9 { g[9][x] = "y" }
            let r = startMin - now; label = String(format: "-%d:%02d", r / 60, r % 60)
        } else if now <= endMin {
            // 근무 중: 반원 궤적
            let p = Double(now - startMin) / Double(max(1, endMin - startMin))
            let x = Int(1 + p * 13); let y = Int(7 - sin(p * .pi) * 6)
            for (dx, dy) in [(0,0),(1,0),(0,1),(1,1)] { if y + dy < 8 { g[y + dy][min(15, x + dx)] = "y" } }
            let r = endMin - now; label = String(format: "%d:%02d", r / 60, r % 60)
        } else {
            // 야근: 달 + 별
            for (x, y) in [(10,1),(11,1),(12,1),(9,2),(10,2),(9,3),(10,3),(10,4),(11,4),(12,4)] { g[y][x] = "w" }
            for (x, y) in [(2,2),(4,5),(6,1)] { g[y][x] = "w" }
            let r = now - endMin; label = String(format: "+%d:%02d", r / 60, r % 60)
        }
        return PixelArt.hstack([PixelArt.render(g.map { String($0) }), PixelArt.text(label)], gap: 3)
    }

    func ask(_ title: String, cur: Int) -> Int? {
        guard let s = promptText(title, "HH:MM 형식", default: String(format: "%02d:%02d", cur / 60, cur % 60)) else { return nil }
        let p = s.split(separator: ":").compactMap { Int($0) }
        return p.count == 2 ? p[0] * 60 + p[1] : nil
    }

    func menu() -> NSMenu {
        let m = NSMenu()
        let f = { (v: Int) in String(format: "%02d:%02d", v / 60, v % 60) }
        m.add("근무 \(f(startMin)) ~ \(f(endMin))")
        m.add("출근 시각…") { [weak self] in if let s = self, let v = s.ask("출근 시각", cur: s.startMin) { s.startMin = v; s.bar.refresh() } }
        m.add("퇴근 시각…") { [weak self] in if let s = self, let v = s.ask("퇴근 시각", cur: s.endMin) { s.endMin = v; s.bar.refresh() } }
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
