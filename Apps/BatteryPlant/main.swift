import AppKit
import IOKit.ps

/// 배터리 식물: 잔량이 식물 상태로. 충전 중이면 자라고, 20% 아래면 시듦.
final class App: NSObject, NSApplicationDelegate {
    let bar = StatusBarController()

    // 단계 0(시듦)~4(만개), 10x10
    let stages: [[String]] = [
        ["..........", "..........", "..........", "..........", "....n.....", "...n......", "....n.....", "..nnnnnn..", "..nnnnnn..", "...nnnn..."],
        ["..........", "..........", "..........", "..........", "....gg....", "....g.....", "....g.....", "..nnnnnn..", "..nnnnnn..", "...nnnn..."],
        ["..........", "..........", "..........", "...gg.....", "..gggg.gg.", "....g.gg..", "....gg....", "..nnnnnn..", "..nnnnnn..", "...nnnn..."],
        ["..........", "....gg....", "..gggggg..", ".gg.gg.gg.", "....gggg..", "..gggg....", "....gg....", "..nnnnnn..", "..nnnnnn..", "...nnnn..."],
        ["...pp.pp..", "..pyppyp..", "..gggggg..", ".gg.gg.gg.", "....gggg..", "..gggg....", "....gg....", "..nnnnnn..", "..nnnnnn..", "...nnnn..."],
    ]

    struct Battery { var pct: Int; var charging: Bool; var present: Bool }

    func read() -> Battery {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return Battery(pct: 100, charging: true, present: false)
        }
        for ps in list {
            guard let d = IOPSGetPowerSourceDescription(blob, ps)?.takeUnretainedValue() as? [String: Any] else { continue }
            let cur = d[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = d[kIOPSMaxCapacityKey] as? Int ?? 100
            let charging = (d[kIOPSIsChargingKey] as? Bool ?? false) || (d[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue)
            return Battery(pct: max > 0 ? cur * 100 / max : 0, charging: charging, present: true)
        }
        return Battery(pct: 100, charging: true, present: false)
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        bar.frameProvider = { [weak self] t in self?.frame(t) ?? NSImage() }
        bar.menuBuilder = { [weak self] in self?.menu() ?? NSMenu() }
        bar.setInterval(1.0)
    }

    func stage(for b: Battery) -> Int {
        if !b.present { return 4 }
        switch b.pct { case ..<20: return 0; case ..<40: return 1; case ..<60: return 2; case ..<85: return 3; default: return 4 }
    }

    func frame(_ t: Int) -> NSImage {
        let b = read()
        var s = stage(for: b)
        // 충전 중이면 2초마다 한 단계 위로 살짝 자라는 연출
        if b.charging && b.present && s < 4 && t % 4 < 2 { s += 1 }
        var rows = stages[s]
        if b.charging && b.present { rows[0] = "y" + String(rows[0].dropFirst()) } // 번개 점
        return PixelArt.render(rows)
    }

    func menu() -> NSMenu {
        let b = read()
        let m = NSMenu()
        m.add(b.present ? "배터리 \(b.pct)% \(b.charging ? "(충전 중)" : "")" : "배터리 없음 (데스크톱)")
        m.add(["시들었어요… 충전해 주세요", "목이 말라요", "그럭저럭", "잘 자라고 있어요", "만개!"][stage(for: b)])
        m.addQuit()
        return m
    }
}
runMenuBarApp(App())
