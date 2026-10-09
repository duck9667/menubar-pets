import AppKit

/// 공유 펫: 둘이 같은 캐릭터를 키운다. 서버 대신 공유 폴더(iCloud Drive 등)의 pet.json을 양쪽이 감시.
struct Pet: Codable {
    var name = "토리"
    var hunger = 50      // 0(배부름)~100(배고픔)
    var mood = 50        // 0(우울)~100(신남)
    var updated = Date()
    var lastBy = ""
    var log: [String] = []
}

final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()
    let d = UserDefaults.standard
    var pet = Pet()
    var source: DispatchSourceFileSystemObject?
    var fd: Int32 = -1
    var me: String { d.string(forKey: "me") ?? NSFullUserName() }
    var file: URL? { get { d.string(forKey: "file").map { URL(fileURLWithPath: $0) } } set { d.set(newValue?.path, forKey: "file") } }
    var reactUntil: Date?; var reactKind = ""

    // 햄스터 (12x10)
    let idle: [[String]] = [
        [".y......y...", "yyy....yyy..", "yyyyyyyyyy..", "y#yyyyyy#y..", "yyyyppyyyy..", ".yyyyyyyyy..", ".yyyyyyyyyyy", "..yyyyyyyy..", "..yy....yy..", "............"],
        [".y......y...", "yyy....yyy..", "yyyyyyyyyy..", "y#yyyyyy#y..", "yyyyppyyyy..", ".yyyyyyyyy..", ".yyyyyyyyyy.", "..yyyyyyyy..", "...yy..yy...", "............"],
    ]
    let sad: [String] = ["............", ".y......y...", "yyy....yyy..", "yyyyyyyyyy..", "yoyyyyyyoy..", "yyyyppyyyy..", ".yyyyyyyyy..", "..yyyyyyyy..", "..yy....yy..", "............"]

    func applicationDidFinishLaunching(_ n: Notification) {
        bar.frameProvider = { [weak self] t in self?.frame(t) ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.setInterval(0.7)
        if file == nil {
            // 기본: iCloud Drive 안 MenubarPet 폴더
            let base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/MenubarPet")
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            file = base.appendingPathComponent("pet.json")
        }
        load(); watch()
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.decay() }
    }

    func load() {
        guard let f = file, let data = try? Data(contentsOf: f), let p = try? JSONDecoder().decode(Pet.self, from: data) else { save(); return }
        if p.updated > pet.updated || pet.log.isEmpty { pet = p }
    }
    func save() {
        guard let f = file else { return }
        pet.updated = Date(); pet.lastBy = me
        if let data = try? JSONEncoder().encode(pet) { try? data.write(to: f, options: .atomic) }
    }
    func watch() {
        source?.cancel(); if fd >= 0 { close(fd) }
        guard let f = file else { return }
        if !FileManager.default.fileExists(atPath: f.path) { save() }
        fd = open(f.path, O_EVTONLY); guard fd >= 0 else { return }
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .rename, .delete], queue: .main)
        source?.setEventHandler { [weak self] in
            let old = self?.pet.lastBy
            self?.load()
            if let s = self, s.pet.lastBy != s.me, s.pet.lastBy != old { s.react("heart") }
            if self?.source?.data.contains(.rename) == true || self?.source?.data.contains(.delete) == true { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self?.watch() } }
        }
        source?.resume()
    }

    func decay() {
        // 1시간에 배고픔 +10, 기분 -5 (updated 기준으로 양쪽이 같은 값 계산)
        let h = Date().timeIntervalSince(pet.updated) / 3600
        if h >= 1 { pet.hunger = min(100, pet.hunger + Int(h * 10)); pet.mood = max(0, pet.mood - Int(h * 5)); save() }
    }

    func act(_ what: String) {
        load()
        switch what {
        case "feed": pet.hunger = max(0, pet.hunger - 30); pet.log.append("\(me)가 먹이를 줬어요")
        case "play": pet.mood = min(100, pet.mood + 25); pet.log.append("\(me)가 놀아줬어요")
        default: break
        }
        pet.log = Array(pet.log.suffix(10)); save(); react(what)
    }
    func react(_ k: String) { reactKind = k; reactUntil = Date().addingTimeInterval(2) }

    func frame(_ t: Int) -> NSImage {
        if let r = reactUntil, Date() < r {
            var rows = idle[t % 2]
            let mark: Character = reactKind == "heart" ? "p" : (reactKind == "feed" ? "r" : "b")
            rows[0] = String(rows[0].prefix(10)) + String(mark) + String(mark)
            return PixelArt.render(rows)
        }
        if pet.hunger > 70 || pet.mood < 30 { return PixelArt.render(sad) }
        return PixelArt.render(idle[t % 2])
    }

    func menu() -> NSMenu {
        let m = NSMenu()
        m.add("\(pet.name) · 배고픔 \(pet.hunger) · 기분 \(pet.mood)")
        m.add("먹이 주기", key: "f") { [weak self] in self?.act("feed") }
        m.add("놀아주기", key: "p") { [weak self] in self?.act("play") }
        m.addItem(.separator())
        for l in pet.log.suffix(5).reversed() { m.add(l) }
        m.addItem(.separator())
        m.add("내 이름: \(me)") { [weak self] in if let s = promptText("내 이름", "상대에게 보일 이름", default: self?.me ?? "") { self?.d.set(s, forKey: "me") } }
        m.add("펫 이름 바꾸기…") { [weak self] in if let s = promptText("펫 이름", "", default: self?.pet.name ?? "") { self?.pet.name = s; self?.save() } }
        m.add("공유 파일: \(file?.path ?? "")") { [weak self] in
            let p = NSOpenPanel(); p.canChooseDirectories = true; p.canChooseFiles = false; p.message = "둘이 함께 쓰는 폴더(iCloud 공유 폴더 등)"
            NSApp.activate(ignoringOtherApps: true)
            if p.runModal() == .OK, let u = p.url { self?.file = u.appendingPathComponent("pet.json"); self?.load(); self?.watch() }
        }
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
