import AppKit

/// 메뉴바 아이템 + 프레임 타이머 + 메뉴를 한 번에 묶는 공용 컨트롤러.
final class StatusBarController {
    let item: NSStatusItem
    private var timer: Timer?
    private var tick = 0
    var frameProvider: ((Int) -> NSImage)?
    var menuBuilder: (() -> NSMenu)?
    var onClick: (() -> Void)?

    init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.imagePosition = .imageOnly
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    /// interval 초마다 프레임 갱신. 0 이하이면 정지.
    func setInterval(_ interval: TimeInterval) {
        timer?.invalidate()
        timer = nil
        guard interval > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in self?.step() }
        RunLoop.main.add(timer!, forMode: .common)
        refresh()
    }

    func step() {
        tick += 1
        refresh()
    }

    func refresh() {
        guard let f = frameProvider else { return }
        item.button?.image = f(tick)
    }

    @objc private func clicked() {
        let ev = NSApp.currentEvent
        if ev?.type == .rightMouseUp || onClick == nil {
            showMenu()
        } else {
            onClick?()
            refresh()
        }
    }

    func showMenu() {
        guard let m = menuBuilder?() else { return }
        item.menu = m
        item.button?.performClick(nil)
        item.menu = nil
    }
}

extension NSMenu {
    @discardableResult
    func add(_ title: String, key: String = "", action: (() -> Void)? = nil) -> NSMenuItem {
        let it = BlockMenuItem(title: title, key: key, block: action)
        addItem(it)
        return it
    }
    func addQuit() {
        addItem(.separator())
        add("종료", key: "q") { NSApp.terminate(nil) }
    }
}

final class BlockMenuItem: NSMenuItem {
    private let block: (() -> Void)?
    init(title: String, key: String, block: (() -> Void)?) {
        self.block = block
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
        isEnabled = block != nil
    }
    required init(coder: NSCoder) { fatalError() }
    @objc private func fire() { block?() }
}

/// 간단한 입력 다이얼로그.
func promptText(_ title: String, _ message: String, default def: String = "") -> String? {
    let a = NSAlert()
    a.messageText = title
    a.informativeText = message
    a.addButton(withTitle: "확인")
    a.addButton(withTitle: "취소")
    let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
    tf.stringValue = def
    a.accessoryView = tf
    NSApp.activate(ignoringOtherApps: true)
    return a.runModal() == .alertFirstButtonReturn ? tf.stringValue : nil
}

/// 모든 앱 공용 진입점: Dock 아이콘 없이 메뉴바에만 상주.
private var retainedDelegate: NSApplicationDelegate?
func runMenuBarApp(_ delegate: NSApplicationDelegate) {
    retainedDelegate = delegate
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    app.delegate = delegate
    app.run()
}
