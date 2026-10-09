import AppKit
import UserNotifications

/// 곰 산책러: 메뉴바 곰이 걷는 속도 = 오늘 집중한 시간. 뽀모도로 끝나면 간식.
final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()
    let d = UserDefaults.standard
    var sessionEnd: Date?        // 집중 세션 종료 시각
    var sessionLen = 25          // 분
    var snackUntil: Date?        // 간식 애니메이션 종료
    var focusTodayKey: String { "focus-" + Self.dayStr() }
    var focusToday: Int { get { d.integer(forKey: focusTodayKey) } set { d.set(newValue, forKey: focusTodayKey) } }

    static func dayStr() -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }

    // 곰 걷기 4프레임 (12x10)
    let walk: [[String]] = [
        ["..nnnn......", ".nnnnnnn....", "nn#nnn#nn...", "nnnnnnnnn...", ".nnnnnnnnnnn", ".nnnnnnnnnn.", "..nnnnnnnn..", "..nn....nn..", "..nn....nn..", ".nn......nn."],
        ["..nnnn......", ".nnnnnnn....", "nn#nnn#nn...", "nnnnnnnnn...", ".nnnnnnnnnnn", ".nnnnnnnnnn.", "..nnnnnnnn..", "...nn..nn...", "...nn..nn...", "...nn..nn..."],
        ["..nnnn......", ".nnnnnnn....", "nn#nnn#nn...", "nnnnnnnnn...", ".nnnnnnnnnnn", ".nnnnnnnnnn.", "..nnnnnnnn..", "...nn..nn...", "..nn....nn..", ".nn......nn."],
        ["..nnnn......", ".nnnnnnn....", "nn#nnn#nn...", "nnnnnnnnn...", ".nnnnnnnnnnn", ".nnnnnnnnnn.", "..nnnnnnnn..", "...nn..nn...", "...nn..nn...", "....nnnn...."],
    ]
    let sleep: [String] = ["............", "............", "......zz....", "....z.......", "nnnnnnnnnn..", "nn#nnnnnnnn.", "nnnnnnnnnnnn", "nnnnnnnnnnnn", ".nnnnnnnnnn.", "..nn....nn.."]
    let snack: [[String]] = [
        ["..nnnn......", ".nnnnnnn....", "nn#nnn#nn...", "nnnnnonnn...", ".nnnnnnnnnnn", ".nnnnnnn.yy.", "..nnnnnn.yy.", "..nn....nn..", "..nn....nn..", ".nn......nn."],
        ["..nnnn......", ".nnnnnnn....", "nn#nnn#nn...", "nnnnyynnn...", ".nnnnnnnnnnn", ".nnnnnnnnnn.", "..nnnnnnnn..", "..nn....nn..", "..nn....nn..", ".nn......nn."],
    ]

    func applicationDidFinishLaunching(_ n: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        bar.frameProvider = { [weak self] t in self?.frame(t) ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.onClick = nil
        scheduleTick()
    }

    func scheduleTick() {
        // 걷는 속도: 집중 0분이면 잠, 많을수록 빠름 (최대 8프레임/초)
        if let end = sessionEnd {
            if Date() >= end { finishSession() }
            bar.setInterval(0.15)
        } else if snackUntil != nil {
            bar.setInterval(0.3)
        } else {
            let m = focusToday
            bar.setInterval(m == 0 ? 2.0 : max(0.12, 1.0 - Double(min(m, 180)) / 200.0))
        }
        bar.refresh()
    }

    func frame(_ t: Int) -> NSImage {
        if let s = snackUntil {
            if Date() > s { snackUntil = nil; scheduleTick() }
            else { return PixelArt.render(snack[t % 2]) }
        }
        if let end = sessionEnd {
            if Date() >= end { finishSession(); return PixelArt.render(snack[0]) }
            let remain = Int(end.timeIntervalSinceNow)
            let label = String(format: "%d:%02d", remain / 60, remain % 60)
            return PixelArt.hstack([PixelArt.render(walk[t % 4]), PixelArt.text(label)], gap: 4)
        }
        if focusToday == 0 { return PixelArt.render(sleep) }
        return PixelArt.render(walk[t % 4])
    }

    func startSession(_ min: Int) {
        sessionLen = min
        sessionEnd = Date().addingTimeInterval(Double(min) * 60)
        scheduleTick()
    }

    func finishSession() {
        guard sessionEnd != nil else { return }
        sessionEnd = nil
        focusToday += sessionLen
        snackUntil = Date().addingTimeInterval(6)
        let c = UNMutableNotificationContent()
        c.title = "곰이 간식을 먹어요 🍯"
        c.body = "오늘 집중 \(focusToday)분. 잠깐 쉬어요."
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
        scheduleTick()
    }

    func menu() -> NSMenu {
        let m = NSMenu()
        m.add("오늘 집중 \(focusToday)분")
        m.addItem(.separator())
        if sessionEnd != nil {
            m.add("세션 취소") { [weak self] in self?.sessionEnd = nil; self?.scheduleTick() }
        } else {
            m.add("25분 집중 시작", key: "s") { [weak self] in self?.startSession(25) }
            m.add("50분 집중 시작") { [weak self] in self?.startSession(50) }
            m.add("5분 집중 (테스트)") { [weak self] in self?.startSession(5) }
        }
        m.add("오늘 기록 초기화") { [weak self] in self?.focusToday = 0; self?.scheduleTick() }
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
