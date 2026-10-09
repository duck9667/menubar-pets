import AppKit

/// 날씨 창문: 메뉴바 작은 창 밖 풍경이 지금 날씨·시간대로 바뀐다. Open-Meteo(키 불필요).
final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()
    let d = UserDefaults.standard
    var code = 0          // WMO weather code
    var temp: Double = 0
    var isDay = true
    var cityName: String { d.string(forKey: "city") ?? "Seoul" }
    var lat: Double { d.object(forKey: "lat") as? Double ?? 37.5665 }
    var lon: Double { d.object(forKey: "lon") as? Double ?? 126.9780 }

    func applicationDidFinishLaunching(_ n: Notification) {
        bar.frameProvider = { [weak self] t in self?.frame(t) ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.setInterval(0.5)
        fetch()
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in self?.fetch() }
    }

    func fetch() {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code,is_day")!
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let c = j["current"] as? [String: Any] else { return }
            DispatchQueue.main.async {
                self?.code = c["weather_code"] as? Int ?? 0
                self?.temp = c["temperature_2m"] as? Double ?? 0
                self?.isDay = (c["is_day"] as? Int ?? 1) == 1
            }
        }.resume()
    }

    enum Sky { case clear, cloudy, rain, snow, storm }
    var sky: Sky {
        switch code {
        case 0, 1: return .clear
        case 2, 3, 45, 48: return .cloudy
        case 51...67, 80...82: return .rain
        case 71...77, 85, 86: return .snow
        default: return .storm
        }
    }

    /// 창틀(12x10) 안을 하늘색·구름·비·눈·해·달로 채움
    func frame(_ t: Int) -> NSImage {
        let hour = Calendar.current.component(.hour, from: Date())
        let sunset = (hour >= 17 && hour < 19) || (hour >= 5 && hour < 7)
        let bg: Character = !isDay ? "d" : (sunset ? "p" : (sky == .clear ? "c" : "o"))
        var g = Array(repeating: Array(repeating: bg, count: 12), count: 10)
        func put(_ x: Int, _ y: Int, _ c: Character) { if x >= 0 && x < 12 && y >= 0 && y < 10 { g[y][x] = c } }
        switch sky {
        case .clear:
            let c: Character = isDay ? "y" : "w"
            for (x, y) in [(8,1),(9,1),(7,2),(8,2),(9,2),(10,2),(8,3),(9,3)] { put(x, y, c) }
            if !isDay { for (x, y) in [(2,2),(4,5),(6,1)] where t % 6 != 0 { put(x, y, "w") } }
        case .cloudy, .rain, .snow, .storm:
            let sx = (t / 4) % 4
            for (x, y) in [(2,1),(3,1),(4,1),(1,2),(2,2),(3,2),(4,2),(5,2)] { put(x + sx, y, "w") }
            for (x, y) in [(7,3),(8,3),(6,4),(7,4),(8,4),(9,4)] { put(x - sx, y, "w") }
            if sky == .rain { for i in 0..<5 { put(i * 2 + 1, (t + i) % 5 + 5, "b") } }
            if sky == .snow { for i in 0..<5 { put(i * 2 + (t % 2), (t / 2 + i * 2) % 5 + 5, "w") } }
            if sky == .storm && t % 8 < 2 { for y in 3...8 { put(6 + (y % 2), y, "y") } }
        }
        // 창틀
        for x in 0..<12 { g[0][x] = "#"; g[9][x] = "#" }
        for y in 0..<10 { g[y][0] = "#"; g[y][11] = "#"; g[y][6] = (g[y][6] == bg ? "#" : g[y][6]) }
        let rows = g.map { String($0) }
        return PixelArt.hstack([PixelArt.render(rows), PixelArt.text("\(Int(temp.rounded()))°")], gap: 3)
    }

    func setCity() {
        guard let q = promptText("도시 설정", "도시 이름을 영문으로 (예: Seoul, Tokyo)", default: cityName), !q.isEmpty else { return }
        let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&count=1")!
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let r = (j["results"] as? [[String: Any]])?.first else { return }
            DispatchQueue.main.async {
                self?.d.set(r["latitude"], forKey: "lat"); self?.d.set(r["longitude"], forKey: "lon")
                self?.d.set(r["name"], forKey: "city"); self?.fetch()
            }
        }.resume()
    }

    func menu() -> NSMenu {
        let m = NSMenu()
        let names: [Sky: String] = [.clear: "맑음", .cloudy: "흐림", .rain: "비", .snow: "눈", .storm: "뇌우"]
        m.add("\(cityName) · \(names[sky]!) · \(String(format: "%.1f", temp))°C")
        m.add("도시 바꾸기…") { [weak self] in self?.setCity() }
        m.add("새로고침") { [weak self] in self?.fetch() }
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
