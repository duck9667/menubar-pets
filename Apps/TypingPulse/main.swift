import AppKit

/// 키보드 심박계: 최근 10초 타자 속도에 따라 캐릭터가 뛴다. 손목 보호 접근성 권한 필요.
final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()
    var stamps: [Date] = []
    var monitor: Any?

    // 토끼 달리기 4프레임 (12x10): 멈춤/걷기/달리기 모두 같은 프레임, 속도만 다름
    let run: [[String]] = [
        [".w..........", ".ww.........", ".www.wwww...", "..wwwwwwww..", "..w#wwwwwwww", "..wwwwwwww..", "...wwwwww...", "...ww..ww...", "..ww....ww..", "............"],
        [".w..........", ".ww.........", ".www.wwww...", "..wwwwwwww..", "..w#wwwwwwww", "..wwwwwwww..", "...wwwwww...", "....ww.ww...", "....ww..ww..", "............"],
        [".w..........", ".ww.........", ".www.wwww...", "..wwwwwwww..", "..w#wwwwwwww", "..wwwwwwww..", "...wwwwww...", "..ww....ww..", ".ww......ww.", "............"],
        [".w..........", ".ww.........", ".www.wwww...", "..wwwwwwww..", "..w#wwwwwwww", "..wwwwwwww..", "...wwwwww...", "....wwww....", "...ww..ww...", "............"],
    ]
    let idle: [String] = [".w..........", ".ww.........", ".www.wwww...", "..wwwwwwww..", "..w#wwwwwwww", "..wwwwwwww..", "...wwwwww...", "...wwwwww...", "...ww..ww...", "............"]

    func applicationDidFinishLaunching(_ n: Notification) {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.stamps.append(Date())
        }
        bar.frameProvider = { [weak self] t in self?.frame(t) ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.setInterval(0.12)
    }

    /// 최근 10초 키 입력 수를 분당 단어(5타=1단어)로 환산
    func wpm() -> Int {
        let cut = Date().addingTimeInterval(-10)
        stamps.removeAll { $0 < cut }
        return stamps.count * 6 / 5
    }

    func frame(_ t: Int) -> NSImage {
        let w = wpm()
        if w < 5 { return PixelArt.hstack([PixelArt.render(idle), PixelArt.text("\(w)")], gap: 3) }
        // 느리면 2틱마다, 빠르면 매 틱 프레임 전환
        let div = w > 60 ? 1 : (w > 30 ? 2 : 3)
        return PixelArt.hstack([PixelArt.render(run[(t / div) % 4]), PixelArt.text("\(w)")], gap: 3)
    }

    func menu() -> NSMenu {
        let m = NSMenu()
        m.add("타자 속도 \(wpm()) WPM (최근 10초)")
        if !AXIsProcessTrusted() {
            m.add("⚠️ 손쉬운 사용 권한이 필요해요 (설정 열기)") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
