import AppKit
import Carbon
import CoreGraphics
import Foundation
import UniformTypeIdentifiers

private let appVersion = "0.2.0"
private let defaultBadgeSize: CGFloat = 34
private let badgeOuterPadding: CGFloat = 6

private enum SettingKey {
    static let keepVisible = "keepVisible"
    static let preferCaret = "preferCaret"
    static let badgeSize = "badgeSize"
    static let koreanLabel = "koreanLabel"
    static let englishLabel = "englishLabel"
    static let customImagePath = "customImagePath"
}

private final class BadgeView: NSView {
    var label: String = "A" {
        didSet {
            needsDisplay = true
        }
    }
    var badgeImage: NSImage? {
        didSet {
            needsDisplay = true
        }
    }
    var badgeSize: CGFloat = defaultBadgeSize {
        didSet {
            needsDisplay = true
        }
    }
    var isKoreanInput = false {
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

        let background = isKoreanInput
            ? NSColor(calibratedRed: 0.06, green: 0.38, blue: 0.96, alpha: 0.92)
            : NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 0.88)

        let side = min(badgeSize, bounds.width - badgeOuterPadding * 2, bounds.height - badgeOuterPadding * 2)
        let rect = NSRect(
            x: (bounds.width - side) / 2,
            y: (bounds.height - side) / 2,
            width: side,
            height: side
        ).insetBy(dx: 1.5, dy: 1.5)
        let radius = max(6, min(14, badgeSize * 0.2))
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        if let image = badgeImage {
            NSGraphicsContext.saveGraphicsState()
            path.addClip()
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            NSColor(calibratedWhite: 0.0, alpha: 0.34).setFill()
            path.fill()
        } else {
            background.setFill()
            path.fill()
        }

        NSColor(calibratedWhite: 1.0, alpha: 0.26).setStroke()
        path.lineWidth = 1
        path.stroke()

        let fontSize = max(11, min(28, badgeSize * 0.47))
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let size = label.size(withAttributes: attrs)
        let origin = NSPoint(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2 - 0.5
        )
        label.draw(at: origin, withAttributes: attrs)
    }
}

private final class BadgeWindow: NSPanel {
    let badgeView = BadgeView(
        frame: NSRect(
            x: 0,
            y: 0,
            width: defaultBadgeSize + badgeOuterPadding * 2,
            height: defaultBadgeSize + badgeOuterPadding * 2
        )
    )

    init() {
        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: defaultBadgeSize + badgeOuterPadding * 2,
                height: defaultBadgeSize + badgeOuterPadding * 2
            ),
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

    func applyBadgeSize(_ size: CGFloat) {
        let width = max(22, min(96, size))
        let windowSide = width + badgeOuterPadding * 2
        badgeView.badgeSize = width
        badgeView.frame = NSRect(x: 0, y: 0, width: windowSide, height: windowSide)
        setContentSize(NSSize(width: windowSide, height: windowSide))
    }
}

private final class SettingsWindowController: NSWindowController {
    private unowned let appDelegate: AppDelegate
    private let keepVisibleButton = NSButton(checkboxWithTitle: "Keep badge visible", target: nil, action: nil)
    private let preferCaretButton = NSButton(checkboxWithTitle: "Prefer text cursor position", target: nil, action: nil)
    private let sizeSlider = NSSlider(value: Double(defaultBadgeSize), minValue: 22, maxValue: 96, target: nil, action: nil)
    private let sizeValueLabel = NSTextField(labelWithString: "\(Int(defaultBadgeSize)) px")
    private let koreanLabelField = NSTextField(string: "한")
    private let englishLabelField = NSTextField(string: "A")
    private let imagePathLabel = NSTextField(labelWithString: "No custom image selected")

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 430),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "HanAIndicator Settings"
        window.center()
        super.init(window: window)
        buildContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh() {
        keepVisibleButton.state = appDelegate.keepVisible ? .on : .off
        preferCaretButton.state = appDelegate.preferCaret ? .on : .off
        sizeSlider.doubleValue = Double(appDelegate.badgeSize)
        sizeValueLabel.stringValue = "\(Int(appDelegate.badgeSize)) px"
        koreanLabelField.stringValue = appDelegate.koreanLabel
        englishLabelField.stringValue = appDelegate.englishLabel
        imagePathLabel.stringValue = appDelegate.customImagePath.isEmpty
            ? "No custom image selected"
            : appDelegate.customImagePath
    }

    private func buildContent() {
        let tabView = NSTabView(frame: NSRect(x: 18, y: 18, width: 524, height: 394))
        tabView.tabViewType = .topTabsBezelBorder
        tabView.addTabViewItem(tab(title: "General", view: generalView()))
        tabView.addTabViewItem(tab(title: "Indicator", view: indicatorView()))
        tabView.addTabViewItem(tab(title: "Advanced", view: advancedView()))
        tabView.addTabViewItem(tab(title: "About", view: aboutView()))
        window?.contentView = tabView
        refresh()
    }

    private func tab(title: String, view: NSView) -> NSTabViewItem {
        let item = NSTabViewItem(identifier: title)
        item.label = title
        item.view = view
        return item
    }

    private func generalView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 510, height: 340))
        addHeader("Options", to: view, y: 292)

        keepVisibleButton.frame = NSRect(x: 26, y: 244, width: 220, height: 24)
        keepVisibleButton.target = self
        keepVisibleButton.action = #selector(toggleKeepVisible)
        view.addSubview(keepVisibleButton)

        view.addSubview(helpText(
            "Keeps the 한/A badge on screen while you type. Turn this off if you only want a short confirmation after switching input sources.",
            x: 48,
            y: 202,
            width: 420
        ))

        preferCaretButton.frame = NSRect(x: 26, y: 158, width: 260, height: 24)
        preferCaretButton.target = self
        preferCaretButton.action = #selector(togglePreferCaret)
        view.addSubview(preferCaretButton)

        view.addSubview(helpText(
            "Uses macOS Accessibility to place the badge near the blinking text cursor. If an app does not expose that position, the badge falls back to the mouse pointer.",
            x: 48,
            y: 106,
            width: 420
        ))

        let accessButton = NSButton(title: "Open Accessibility Settings", target: self, action: #selector(openAccessibilitySettings))
        accessButton.frame = NSRect(x: 26, y: 54, width: 210, height: 32)
        view.addSubview(accessButton)

        return view
    }

    private func indicatorView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 510, height: 340))
        addHeader("Badge Appearance", to: view, y: 292)

        let sizeTitle = NSTextField(labelWithString: "Icon size")
        sizeTitle.frame = NSRect(x: 26, y: 244, width: 120, height: 22)
        view.addSubview(sizeTitle)

        sizeSlider.frame = NSRect(x: 112, y: 238, width: 250, height: 30)
        sizeSlider.target = self
        sizeSlider.action = #selector(sizeChanged)
        view.addSubview(sizeSlider)

        sizeValueLabel.frame = NSRect(x: 374, y: 244, width: 70, height: 22)
        view.addSubview(sizeValueLabel)

        let koreanTitle = NSTextField(labelWithString: "Korean label")
        koreanTitle.frame = NSRect(x: 26, y: 196, width: 100, height: 22)
        view.addSubview(koreanTitle)
        koreanLabelField.frame = NSRect(x: 136, y: 192, width: 60, height: 28)
        koreanLabelField.target = self
        koreanLabelField.action = #selector(labelChanged)
        view.addSubview(koreanLabelField)

        let englishTitle = NSTextField(labelWithString: "English label")
        englishTitle.frame = NSRect(x: 230, y: 196, width: 100, height: 22)
        view.addSubview(englishTitle)
        englishLabelField.frame = NSRect(x: 340, y: 192, width: 60, height: 28)
        englishLabelField.target = self
        englishLabelField.action = #selector(labelChanged)
        view.addSubview(englishLabelField)

        let chooseButton = NSButton(title: "Choose Image...", target: self, action: #selector(chooseImage))
        chooseButton.frame = NSRect(x: 26, y: 136, width: 140, height: 32)
        view.addSubview(chooseButton)

        let clearButton = NSButton(title: "Clear Image", target: self, action: #selector(clearImage))
        clearButton.frame = NSRect(x: 178, y: 136, width: 110, height: 32)
        view.addSubview(clearButton)

        imagePathLabel.frame = NSRect(x: 26, y: 100, width: 455, height: 22)
        imagePathLabel.lineBreakMode = .byTruncatingMiddle
        view.addSubview(imagePathLabel)

        view.addSubview(helpText(
            "The selected image is used as the badge background. The current 한/A label remains on top so the language is still readable.",
            x: 26,
            y: 50,
            width: 440
        ))

        return view
    }

    private func advancedView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 510, height: 340))
        addHeader("Advanced", to: view, y: 292)
        view.addSubview(helpText(
            "HanAIndicator checks the active macOS input source every 0.12 seconds and also listens for input-source change notifications. It does not read the text you type.",
            x: 26,
            y: 226,
            width: 440
        ))

        let resetButton = NSButton(title: "Reset Options", target: self, action: #selector(resetOptions))
        resetButton.frame = NSRect(x: 26, y: 172, width: 130, height: 32)
        view.addSubview(resetButton)

        let buildButton = NSButton(title: "Open Project Folder", target: self, action: #selector(openProjectFolder))
        buildButton.frame = NSRect(x: 170, y: 172, width: 160, height: 32)
        view.addSubview(buildButton)

        return view
    }

    private func aboutView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 510, height: 340))
        addHeader("HanAIndicator \(appVersion)", to: view, y: 292)

        view.addSubview(helpText(
            """
            Purpose: show Korean input as 한 and English input as A near the cursor.

            Current options:
            - Keep Badge Visible: persistent Keyla-style badge.
            - Prefer Text Cursor Position: attach to the text caret when possible.
            - Icon Size: changes the floating badge size.
            - Korean/English Label: custom text for each input source.
            - Choose Image: replace the badge background image.
            """,
            x: 26,
            y: 124,
            width: 440,
            height: 150
        ))

        return view
    }

    private func addHeader(_ text: String, to view: NSView, y: CGFloat) {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        label.frame = NSRect(x: 26, y: y, width: 420, height: 26)
        view.addSubview(label)
    }

    private func helpText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat = 46) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.textColor = .secondaryLabelColor
        field.frame = NSRect(x: x, y: y, width: width, height: height)
        return field
    }

    @objc private func toggleKeepVisible() {
        appDelegate.setKeepVisible(keepVisibleButton.state == .on)
    }

    @objc private func togglePreferCaret() {
        appDelegate.setPreferCaret(preferCaretButton.state == .on)
    }

    @objc private func sizeChanged() {
        let value = CGFloat(sizeSlider.doubleValue.rounded())
        sizeValueLabel.stringValue = "\(Int(value)) px"
        appDelegate.setBadgeSize(value)
    }

    @objc private func labelChanged() {
        appDelegate.setLabels(
            korean: koreanLabelField.stringValue.isEmpty ? "한" : koreanLabelField.stringValue,
            english: englishLabelField.stringValue.isEmpty ? "A" : englishLabelField.stringValue
        )
    }

    @objc private func chooseImage() {
        let panel = NSOpenPanel()
        panel.title = "Choose Badge Background Image"
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff, .bmp, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            appDelegate.setCustomImagePath(url.path)
            imagePathLabel.stringValue = url.path
        }
    }

    @objc private func clearImage() {
        appDelegate.setCustomImagePath("")
        imagePathLabel.stringValue = "No custom image selected"
    }

    @objc private func resetOptions() {
        appDelegate.resetOptions()
        refresh()
    }

    @objc private func openAccessibilitySettings() {
        appDelegate.openAccessibilitySettings()
    }

    @objc private func openProjectFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Users/macpro/HanAIndicator"))
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let window = BadgeWindow()
    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private var timer: Timer?
    private var hideAt = Date.distantFuture
    fileprivate var keepVisible = true
    fileprivate var preferCaret = true
    fileprivate var badgeSize: CGFloat = defaultBadgeSize
    fileprivate var koreanLabel = "한"
    fileprivate var englishLabel = "A"
    fileprivate var customImagePath = ""
    private var lastLabel = ""
    private var lastInputSourceID = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        loadOptions()
        buildMenu()
        applyAppearanceOptions()
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
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "Version \(appVersion)",
            action: nil,
            keyEquivalent: ""
        ))
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

    private func loadOptions() {
        UserDefaults.standard.register(defaults: [
            SettingKey.keepVisible: true,
            SettingKey.preferCaret: true,
            SettingKey.badgeSize: Double(defaultBadgeSize),
            SettingKey.koreanLabel: "한",
            SettingKey.englishLabel: "A",
            SettingKey.customImagePath: ""
        ])
        keepVisible = UserDefaults.standard.bool(forKey: SettingKey.keepVisible)
        preferCaret = UserDefaults.standard.bool(forKey: SettingKey.preferCaret)
        badgeSize = CGFloat(UserDefaults.standard.double(forKey: SettingKey.badgeSize))
        koreanLabel = UserDefaults.standard.string(forKey: SettingKey.koreanLabel) ?? "한"
        englishLabel = UserDefaults.standard.string(forKey: SettingKey.englishLabel) ?? "A"
        customImagePath = UserDefaults.standard.string(forKey: SettingKey.customImagePath) ?? ""
    }

    private func saveOptions() {
        UserDefaults.standard.set(keepVisible, forKey: SettingKey.keepVisible)
        UserDefaults.standard.set(preferCaret, forKey: SettingKey.preferCaret)
        UserDefaults.standard.set(Double(badgeSize), forKey: SettingKey.badgeSize)
        UserDefaults.standard.set(koreanLabel, forKey: SettingKey.koreanLabel)
        UserDefaults.standard.set(englishLabel, forKey: SettingKey.englishLabel)
        UserDefaults.standard.set(customImagePath, forKey: SettingKey.customImagePath)
    }

    private func applyAppearanceOptions() {
        window.applyBadgeSize(badgeSize)
        if !customImagePath.isEmpty, let image = NSImage(contentsOfFile: customImagePath) {
            window.badgeView.badgeImage = image
        } else {
            window.badgeView.badgeImage = nil
        }
        window.badgeView.needsDisplay = true
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
        window.badgeView.isKoreanInput = current.isKorean

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

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(appDelegate: self)
        }
        settingsWindowController?.refresh()
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    fileprivate func setKeepVisible(_ value: Bool) {
        keepVisible = value
        saveOptions()
        if keepVisible {
            window.orderFrontRegardless()
        }
    }

    fileprivate func setPreferCaret(_ value: Bool) {
        preferCaret = value
        saveOptions()
    }

    fileprivate func setBadgeSize(_ value: CGFloat) {
        badgeSize = max(22, min(96, value))
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func setLabels(korean: String, english: String) {
        koreanLabel = String(korean.prefix(3))
        englishLabel = String(english.prefix(3))
        saveOptions()
        window.badgeView.needsDisplay = true
    }

    fileprivate func setCustomImagePath(_ path: String) {
        customImagePath = path
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func resetOptions() {
        keepVisible = true
        preferCaret = true
        badgeSize = defaultBadgeSize
        koreanLabel = "한"
        englishLabel = "A"
        customImagePath = ""
        saveOptions()
        applyAppearanceOptions()
    }

    @objc fileprivate func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func currentInputLabel() -> (label: String, sourceID: String, isKorean: Bool) {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return ("?", "", false)
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
            return (koreanLabel, id, true)
        }

        if combined.contains("abc")
            || combined.contains("roman")
            || combined.contains("us")
            || combined.contains("com.apple.keylayout")
        {
            return (englishLabel, id, false)
        }

        if let first = name.trimmingCharacters(in: .whitespacesAndNewlines).first {
            return (String(first).uppercased(), id, false)
        }
        return (englishLabel, id, false)
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
