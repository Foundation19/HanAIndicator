import AppKit
import Carbon
import CoreGraphics
import Foundation

private final class BadgeView: NSView {
    var label: String = "A" {
        didSet {
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let isKorean = label == "한"
        let background = isKorean
            ? NSColor(calibratedRed: 0.06, green: 0.38, blue: 0.96, alpha: 0.92)
            : NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 0.88)

        let rect = bounds.insetBy(dx: 1.0, dy: 1.0)
        let path = NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7)
        background.setFill()
        path.fill()

        NSColor(calibratedWhite: 1.0, alpha: 0.26).setStroke()
        path.lineWidth = 1
        path.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: label == "한" ? 16 : 17, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let size = label.size(withAttributes: attrs)
        let origin = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2 - 0.5
        )
        label.draw(at: origin, withAttributes: attrs)
    }
}

private final class BadgeWindow: NSPanel {
    let badgeView = BadgeView(frame: NSRect(x: 0, y: 0, width: 34, height: 28))

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 34, height: 28),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        contentView = badgeView
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        ignoresMouseEvents = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        orderOut(nil)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let window = BadgeWindow()
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var hideAt = Date.distantFuture
    private var keepVisible = true
    private var preferCaret = true
    private var lastLabel = ""
    private var lastInputSourceID = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        buildMenu()
        observeInputSourceChanges()
        askForAccessibilityIfNeeded()

        timer = Timer.scheduledTimer(
            timeInterval: 0.12,
            target: self,
            selector: #selector(tick),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func buildMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "한A"

        let menu = NSMenu()
        let visibleItem = NSMenuItem(
            title: "Keep Badge Visible",
            action: #selector(toggleKeepVisible(_:)),
            keyEquivalent: ""
        )
        visibleItem.state = keepVisible ? .on : .off
        menu.addItem(visibleItem)

        let caretItem = NSMenuItem(
            title: "Prefer Text Cursor Position",
            action: #selector(togglePreferCaret(_:)),
            keyEquivalent: ""
        )
        caretItem.state = preferCaret ? .on : .off
        menu.addItem(caretItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Open Accessibility Settings",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Quit HanAIndicator",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        item.menu = menu
        statusItem = item
    }

    private func observeInputSourceChanges() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }

    private func askForAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @objc private func tick() {
        let current = currentInputLabel()
        if current.label != lastLabel {
            lastLabel = current.label
            hideAt = Date().addingTimeInterval(1.8)
        }
        if current.sourceID != lastInputSourceID {
            lastInputSourceID = current.sourceID
            hideAt = Date().addingTimeInterval(1.8)
        }

        window.badgeView.label = current.label

        guard keepVisible || Date() < hideAt else {
            window.orderOut(nil)
            return
        }

        let point = preferCaret ? caretPoint() ?? mousePoint() : mousePoint()
        moveBadge(near: point)
        if !window.isVisible {
            window.orderFrontRegardless()
        }
    }

    @objc private func inputSourceChanged() {
        hideAt = Date().addingTimeInterval(2.0)
        tick()
    }

    @objc private func toggleKeepVisible(_ sender: NSMenuItem) {
        keepVisible.toggle()
        sender.state = keepVisible ? .on : .off
        if keepVisible {
            window.orderFrontRegardless()
        }
    }

    @objc private func togglePreferCaret(_ sender: NSMenuItem) {
        preferCaret.toggle()
        sender.state = preferCaret ? .on : .off
    }

    @objc private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func currentInputLabel() -> (label: String, sourceID: String) {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return ("?", "")
        }

        let id = tisString(source, kTISPropertyInputSourceID) ?? ""
        let name = tisString(source, kTISPropertyLocalizedName) ?? ""
        let mode = tisString(source, kTISPropertyInputModeID) ?? ""
        let combined = "\(id) \(name) \(mode)".lowercased()

        if combined.contains("korean")
            || combined.contains("hangul")
            || combined.contains("2-set")
            || combined.contains("2set")
            || combined.contains("gureum")
            || combined.contains("han")
        {
            return ("한", id)
        }

        if combined.contains("abc")
            || combined.contains("roman")
            || combined.contains("us")
            || combined.contains("com.apple.keylayout")
        {
            return ("A", id)
        }

        if let first = name.trimmingCharacters(in: .whitespacesAndNewlines).first {
            return (String(first).uppercased(), id)
        }
        return ("A", id)
    }

    private func tisString(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(source, key) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    private func mousePoint() -> CGPoint {
        let location = NSEvent.mouseLocation
        return CGPoint(x: location.x + 18, y: location.y - 32)
    }

    private func caretPoint() -> CGPoint? {
        guard AXIsProcessTrusted() else {
            return nil
        }

        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        ) == .success else {
            return nil
        }

        let focusedElement = focusedValue as! AXUIElement
        guard isTextLike(focusedElement) else {
            return nil
        }

        if let rect = selectedTextRect(focusedElement) {
            return CGPoint(x: rect.maxX + 8, y: rect.minY - 2)
        }

        if let rect = elementRect(focusedElement) {
            return CGPoint(x: rect.minX + 8, y: rect.maxY - 34)
        }

        return nil
    }

    private func isTextLike(_ element: AXUIElement) -> Bool {
        let role = axString(element, kAXRoleAttribute) ?? ""
        let subrole = axString(element, kAXSubroleAttribute) ?? ""
        if role.contains("Text") || role.contains("ComboBox") || role.contains("SearchField") {
            return true
        }
        if subrole.contains("Text") || subrole.contains("SearchField") {
            return true
        }

        var editableValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            "AXEditable" as CFString,
            &editableValue
        ) == .success,
           let editable = editableValue as? Bool {
            return editable
        }
        return false
    }

    private func axString(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private func selectedTextRect(_ element: AXUIElement) -> CGRect? {
        var rangeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rangeValue
        ) == .success,
              rangeValue != nil else {
            return nil
        }
        let axRange = rangeValue as! AXValue

        var range = CFRange()
        guard AXValueGetValue(axRange, .cfRange, &range) else {
            return nil
        }

        var parameter: CFTypeRef?
        let result = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            axRange,
            &parameter
        )
        guard result == .success, parameter != nil else {
            return nil
        }
        let axRect = parameter as! AXValue

        var rect = CGRect.zero
        guard AXValueGetValue(axRect, .cgRect, &rect), !rect.isNull, !rect.isEmpty else {
            return nil
        }

        if range.length == 0, rect.width > 18 {
            rect.size.width = 1
        }
        return rect
    }

    private func elementRect(_ element: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        ) == .success,
              AXUIElementCopyAttributeValue(
                element,
                kAXSizeAttribute as CFString,
                &sizeValue
              ) == .success,
              positionValue != nil,
              sizeValue != nil else {
            return nil
        }

        let axPosition = positionValue as! AXValue
        let axSize = sizeValue as! AXValue
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(axPosition, .cgPoint, &position),
              AXValueGetValue(axSize, .cgSize, &size) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    private func moveBadge(near point: CGPoint) {
        let screenFrame = NSScreen.screens.first(where: { $0.frame.contains(point) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let size = window.frame.size
        var origin = CGPoint(x: point.x, y: point.y)
        origin.x = max(screenFrame.minX + 6, min(origin.x, screenFrame.maxX - size.width - 6))
        origin.y = max(screenFrame.minY + 6, min(origin.y, screenFrame.maxY - size.height - 6))
        window.setFrameOrigin(origin)
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
