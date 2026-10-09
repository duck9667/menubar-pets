import AppKit

/// 물 마시기 어항: 클릭 = 물 한 잔. 2시간 안 마시면 물고기가 흐려진다.
final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()
    let d = UserDefaults.standard
    var last: Date? { get { d.object(forKey: "last") as? Date } set { d.set(newValue, forKey: "last") } }
    var cupsKey: String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return "cups-" + f.string(from: Date()) }
    var cups: Int { get { d.integer(forKey: cupsKey) } set { d.set(newValue, forKey: cupsKey) } }
    var splashUntil: Date?

    func applicationDidFinishLaunching(_ n: Notification) {
        bar.frameProvider = { [weak self] t in self?.frame(t) ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.onClick = { [weak self] in self?.drink() }
        bar.setInterval(0.4)
    }

    func drink() {
        last = Date(); cups += 1
        splashUntil = Date().addingTimeInterval(1.5)
    }

    var hoursSince: Double { last.map { Date().timeIntervalSince($0) / 3600 } ?? 99 }

    func frame(_ t: Int) -> NSImage {
        let h = hoursSince
        // 물 색: 신선할수록 파랑, 오래되면 회색
        let water: Character = h < 1 ? "b" : (h < 2 ? "c" : "o")
        let fish: Character = h < 2 ? "y" : "o"
        var g = Array(repeating: Array(repeating: water, count: 14), count: 10)
        // 물결 윗줄
        for x in 0..<14 { g[0][x] = ((x + t) % 3 == 0) ? water : "." }
        // 물고기(좌우 왕복)
        func put(_ x: Int, _ y: Int, _ c: Character) { if x >= 0 && x < 14 && y >= 0 && y < 10 { g[y][x] = c } }
        let span = 14 - 7
        let p = t % (span * 2); let fx = p < span ? p : span * 2 - p
        let right = p < span
        let body: [(Int, Int)] = [(1,4),(2,3),(3,3),(4,3),(2,4),(3,4),(4,4),(5,4),(2,5),(3,5),(4,5)]
        for (x, y) in body { put(right ? fx + x : fx + 6 - x, y, fish) }
        for y in 3...5 { put(right ? fx : fx + 6, y, fish) } // 꼬리
        put(right ? fx + 4 : fx + 2, 4, "k") // 눈
        // 거품
        if let s = splashUntil, Date() < s { for i in 0..<4 { put(i * 3 + 1, (t + i * 2) % 4 + 1, "w") } }
        // 바닥 자갈
        for x in stride(from: 1, to: 13, by: 2) { g[9][x] = "n" }
        let rows = g.map { String($0) }
        return PixelArt.hstack([PixelArt.render(rows), PixelArt.text("\(cups)")], gap: 3)
    }

    func menu() -> NSMenu {
        let m = NSMenu()
        let lastStr = last == nil ? "기록 없음" : "\(Int(hoursSince * 60))분 전"
        m.add("오늘 \(cups)잔 · 마지막 \(lastStr)")
        m.add("물 한 잔 마셨어요 (왼쪽 클릭과 동일)", key: "d") { [weak self] in self?.drink() }
        m.add("오늘 기록 초기화") { [weak self] in self?.cups = 0 }
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
