import AppKit
import Carbon
import CoreGraphics
import Foundation
import UniformTypeIdentifiers

private let appVersion = "0.2.4"
private let defaultBadgeSize: CGFloat = 28
private let badgeOuterPadding: CGFloat = 5
private let badgeAspectRatio: CGFloat = 1.42
private let idleDimDelay: TimeInterval = 1.0
private let activeBadgeOpacity: CGFloat = 0.96
private let idleBadgeOpacity: CGFloat = 0.42

private enum SettingKey {
    static let keepVisible = "keepVisible"
    static let preferCaret = "preferCaret"
    static let badgeSize = "badgeSize"
    static let koreanLabel = "koreanLabel"
    static let englishLabel = "englishLabel"
    static let customImagePath = "customImagePath"
    static let anchor = "anchor"
    static let offsetX = "offsetX"
    static let offsetY = "offsetY"
    static let koreanBackgroundColor = "koreanBackgroundColor"
    static let koreanTextColor = "koreanTextColor"
    static let englishBackgroundColor = "englishBackgroundColor"
    static let englishTextColor = "englishTextColor"
}

private let defaultKoreanBackground = "#EEF3FF"
private let defaultKoreanText = "#053FD1"
private let defaultEnglishBackground = "#EEEEEE"
private let defaultEnglishText = "#2E2E2E"

private enum BadgeAnchor: String, CaseIterable {
    case bottomRight
    case topRight
    case bottomLeft
    case topLeft
    case centered

    var title: String {
        switch self {
        case .bottomRight: return "Bottom Right"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .topLeft: return "Top Left"
        case .centered: return "Centered"
        }
    }
}

private extension NSColor {
    convenience init?(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let intValue = Int(value, radix: 16) else {
            return nil
        }
        self.init(
            calibratedRed: CGFloat((intValue >> 16) & 0xFF) / 255.0,
            green: CGFloat((intValue >> 8) & 0xFF) / 255.0,
            blue: CGFloat(intValue & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    var hexString: String {
        guard let color = usingColorSpace(.sRGB) else {
            return "#000000"
        }
        return String(
            format: "#%02X%02X%02X",
            Int(round(color.redComponent * 255)),
            Int(round(color.greenComponent * 255)),
            Int(round(color.blueComponent * 255))
        )
    }
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
    var koreanBackgroundColor = NSColor(hex: defaultKoreanBackground)! {
        didSet { needsDisplay = true }
    }
    var koreanTextColor = NSColor(hex: defaultKoreanText)! {
        didSet { needsDisplay = true }
    }
    var englishBackgroundColor = NSColor(hex: defaultEnglishBackground)! {
        didSet { needsDisplay = true }
    }
    var englishTextColor = NSColor(hex: defaultEnglishText)! {
        didSet { needsDisplay = true }
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

        guard let context = NSGraphicsContext.current else {
            return
        }
        context.imageInterpolation = .high
        context.shouldAntialias = true

        let background = isKoreanInput ? koreanBackgroundColor : englishBackgroundColor
        let textColor = isKoreanInput ? koreanTextColor : englishTextColor

        let height = min(badgeSize, bounds.height - badgeOuterPadding * 2)
        let width = min(height * badgeAspectRatio, bounds.width - badgeOuterPadding * 2)
        let rawRect = NSRect(
            x: (bounds.width - width) / 2,
            y: (bounds.height - height) / 2,
            width: width,
            height: height
        ).insetBy(dx: 1.0, dy: 1.0)
        let rect = pixelAligned(rawRect)
        let radius = rect.height / 2
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

            let highlight = NSBezierPath(
                roundedRect: pixelAligned(rect.insetBy(dx: 1.0, dy: 1.0)),
                xRadius: max(4, radius - 1),
                yRadius: max(4, radius - 1)
            )
            NSColor(calibratedWhite: 1.0, alpha: 0.58).setStroke()
            highlight.lineWidth = 1
            highlight.stroke()
        }

        NSColor(calibratedWhite: 0.0, alpha: 0.10).setStroke()
        path.lineWidth = 0.6
        path.stroke()

        let fontSize = max(11, min(20, badgeSize * 0.49))
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: textColor
        ]
        let size = label.size(withAttributes: attrs)
        let origin = pixelAligned(NSPoint(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2
        ))
        label.draw(at: origin, withAttributes: attrs)
    }

    private func pixelAligned(_ rect: NSRect) -> NSRect {
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        return NSRect(
            x: (rect.origin.x * scale).rounded() / scale,
            y: (rect.origin.y * scale).rounded() / scale,
            width: (rect.size.width * scale).rounded() / scale,
            height: (rect.size.height * scale).rounded() / scale
        )
    }

    private func pixelAligned(_ point: NSPoint) -> NSPoint {
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        return NSPoint(
            x: (point.x * scale).rounded() / scale,
            y: (point.y * scale).rounded() / scale
        )
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
        let width = max(14, min(72, size))
        let windowWidth = width * badgeAspectRatio + badgeOuterPadding * 2
        let windowHeight = width + badgeOuterPadding * 2
        badgeView.badgeSize = width
        badgeView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        setContentSize(NSSize(width: windowWidth, height: windowHeight))
    }
}

private final class SettingsWindowController: NSWindowController {
    private unowned let appDelegate: AppDelegate
    private let keepVisibleButton = NSButton(checkboxWithTitle: "Keep badge visible", target: nil, action: nil)
    private let preferCaretButton = NSButton(checkboxWithTitle: "Prefer text cursor position", target: nil, action: nil)
    private let sizeSlider = NSSlider(value: Double(defaultBadgeSize), minValue: 14, maxValue: 72, target: nil, action: nil)
    private let sizeValueLabel = NSTextField(labelWithString: "\(Int(defaultBadgeSize)) px")
    private let koreanLabelField = NSTextField(string: "한")
    private let englishLabelField = NSTextField(string: "A")
    private let imagePathLabel = NSTextField(labelWithString: "No custom image selected")
    private let anchorPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let offsetXField = NSTextField(string: "18")
    private let offsetYField = NSTextField(string: "-32")
    private let koreanBackgroundWell = NSColorWell(frame: .zero)
    private let koreanTextWell = NSColorWell(frame: .zero)
    private let englishBackgroundWell = NSColorWell(frame: .zero)
    private let englishTextWell = NSColorWell(frame: .zero)

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
        anchorPopup.selectItem(withTitle: appDelegate.anchor.title)
        offsetXField.stringValue = "\(Int(appDelegate.offsetX))"
        offsetYField.stringValue = "\(Int(appDelegate.offsetY))"
        koreanBackgroundWell.color = appDelegate.koreanBackgroundColor
        koreanTextWell.color = appDelegate.koreanTextColor
        englishBackgroundWell.color = appDelegate.englishBackgroundColor
        englishTextWell.color = appDelegate.englishTextColor
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

        let koreanTitle = NSTextField(labelWithString: "Korean")
        koreanTitle.frame = NSRect(x: 26, y: 202, width: 64, height: 22)
        view.addSubview(koreanTitle)
        koreanLabelField.frame = NSRect(x: 92, y: 198, width: 48, height: 28)
        koreanLabelField.target = self
        koreanLabelField.action = #selector(labelChanged)
        view.addSubview(koreanLabelField)

        koreanBackgroundWell.frame = NSRect(x: 150, y: 198, width: 42, height: 28)
        koreanBackgroundWell.target = self
        koreanBackgroundWell.action = #selector(colorChanged)
        view.addSubview(koreanBackgroundWell)

        koreanTextWell.frame = NSRect(x: 202, y: 198, width: 42, height: 28)
        koreanTextWell.target = self
        koreanTextWell.action = #selector(colorChanged)
        view.addSubview(koreanTextWell)

        let englishTitle = NSTextField(labelWithString: "English")
        englishTitle.frame = NSRect(x: 270, y: 202, width: 64, height: 22)
        view.addSubview(englishTitle)
        englishLabelField.frame = NSRect(x: 336, y: 198, width: 48, height: 28)
        englishLabelField.target = self
        englishLabelField.action = #selector(labelChanged)
        view.addSubview(englishLabelField)

        englishBackgroundWell.frame = NSRect(x: 394, y: 198, width: 42, height: 28)
        englishBackgroundWell.target = self
        englishBackgroundWell.action = #selector(colorChanged)
        view.addSubview(englishBackgroundWell)

        englishTextWell.frame = NSRect(x: 446, y: 198, width: 42, height: 28)
        englishTextWell.target = self
        englishTextWell.action = #selector(colorChanged)
        view.addSubview(englishTextWell)

        let colorHelp = NSTextField(labelWithString: "Order: label, background, text")
        colorHelp.textColor = .secondaryLabelColor
        colorHelp.font = NSFont.systemFont(ofSize: 11)
        colorHelp.frame = NSRect(x: 26, y: 176, width: 280, height: 18)
        view.addSubview(colorHelp)

        let anchorTitle = NSTextField(labelWithString: "Cursor position")
        anchorTitle.frame = NSRect(x: 26, y: 142, width: 120, height: 22)
        view.addSubview(anchorTitle)

        anchorPopup.addItems(withTitles: BadgeAnchor.allCases.map(\.title))
        anchorPopup.frame = NSRect(x: 146, y: 138, width: 150, height: 28)
        anchorPopup.target = self
        anchorPopup.action = #selector(positionChanged)
        view.addSubview(anchorPopup)

        let offsetTitle = NSTextField(labelWithString: "Offset X/Y")
        offsetTitle.frame = NSRect(x: 316, y: 142, width: 78, height: 22)
        view.addSubview(offsetTitle)

        offsetXField.frame = NSRect(x: 394, y: 138, width: 42, height: 26)
        offsetXField.target = self
        offsetXField.action = #selector(positionChanged)
        view.addSubview(offsetXField)

        offsetYField.frame = NSRect(x: 442, y: 138, width: 42, height: 26)
        offsetYField.target = self
        offsetYField.action = #selector(positionChanged)
        view.addSubview(offsetYField)

        let chooseButton = NSButton(title: "Choose Image...", target: self, action: #selector(chooseImage))
        chooseButton.frame = NSRect(x: 26, y: 90, width: 140, height: 32)
        view.addSubview(chooseButton)

        let clearButton = NSButton(title: "Clear Image", target: self, action: #selector(clearImage))
        clearButton.frame = NSRect(x: 178, y: 90, width: 110, height: 32)
        view.addSubview(clearButton)

        imagePathLabel.frame = NSRect(x: 26, y: 60, width: 455, height: 22)
        imagePathLabel.lineBreakMode = .byTruncatingMiddle
        view.addSubview(imagePathLabel)

        view.addSubview(helpText(
            "Cursor position sets where the badge sits around the cursor. X/Y offsets fine-tune the distance. The selected image is used as the badge background.",
            x: 26,
            y: 12,
            width: 440,
            height: 40
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
            - Cursor Position and Offset X/Y: place the badge around the cursor.
            - Korean/English Label and colors: custom text, background, and text colors.
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

    @objc private func colorChanged() {
        appDelegate.setColors(
            koreanBackground: koreanBackgroundWell.color,
            koreanText: koreanTextWell.color,
            englishBackground: englishBackgroundWell.color,
            englishText: englishTextWell.color
        )
    }

    @objc private func positionChanged() {
        let selectedTitle = anchorPopup.selectedItem?.title ?? BadgeAnchor.bottomRight.title
        let anchor = BadgeAnchor.allCases.first(where: { $0.title == selectedTitle }) ?? .bottomRight
        appDelegate.setPosition(
            anchor: anchor,
            offsetX: CGFloat(offsetXField.doubleValue),
            offsetY: CGFloat(offsetYField.doubleValue)
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
    private var mouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var hideAt = Date.distantFuture
    fileprivate var keepVisible = true
    fileprivate var preferCaret = true
    fileprivate var badgeSize: CGFloat = defaultBadgeSize
    fileprivate var koreanLabel = "한"
    fileprivate var englishLabel = "A"
    fileprivate var customImagePath = ""
    fileprivate var anchor: BadgeAnchor = .bottomRight
    fileprivate var offsetX: CGFloat = 18
    fileprivate var offsetY: CGFloat = -32
    fileprivate var koreanBackgroundColor = NSColor(hex: defaultKoreanBackground)!
    fileprivate var koreanTextColor = NSColor(hex: defaultKoreanText)!
    fileprivate var englishBackgroundColor = NSColor(hex: defaultEnglishBackground)!
    fileprivate var englishTextColor = NSColor(hex: defaultEnglishText)!
    private var lastLabel = ""
    private var lastInputSourceID = ""
    private var lastInputCheck = Date.distantPast
    private var cachedLabel = "A"
    private var cachedIsKorean = false
    private var cachedSourceID = ""
    private var lastCaretPoint: CGPoint?
    private var lastMouseActivity = Date()
    private var isDimmed = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        loadOptions()
        buildMenu()
        applyAppearanceOptions()
        observeInputSourceChanges()
        askForAccessibilityIfNeeded()

        installMouseMonitors()

        timer = Timer.scheduledTimer(
            timeInterval: 0.04,
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
            SettingKey.customImagePath: "",
            SettingKey.anchor: BadgeAnchor.bottomRight.rawValue,
            SettingKey.offsetX: 18.0,
            SettingKey.offsetY: -32.0,
            SettingKey.koreanBackgroundColor: defaultKoreanBackground,
            SettingKey.koreanTextColor: defaultKoreanText,
            SettingKey.englishBackgroundColor: defaultEnglishBackground,
            SettingKey.englishTextColor: defaultEnglishText
        ])
        keepVisible = UserDefaults.standard.bool(forKey: SettingKey.keepVisible)
        preferCaret = UserDefaults.standard.bool(forKey: SettingKey.preferCaret)
        badgeSize = CGFloat(UserDefaults.standard.double(forKey: SettingKey.badgeSize))
        if badgeSize < 24 || badgeSize > 72 {
            badgeSize = defaultBadgeSize
            UserDefaults.standard.set(Double(badgeSize), forKey: SettingKey.badgeSize)
        }
        koreanLabel = UserDefaults.standard.string(forKey: SettingKey.koreanLabel) ?? "한"
        englishLabel = UserDefaults.standard.string(forKey: SettingKey.englishLabel) ?? "A"
        customImagePath = UserDefaults.standard.string(forKey: SettingKey.customImagePath) ?? ""
        let anchorRawValue = UserDefaults.standard.string(forKey: SettingKey.anchor) ?? BadgeAnchor.bottomRight.rawValue
        anchor = BadgeAnchor(rawValue: anchorRawValue) ?? .bottomRight
        offsetX = CGFloat(UserDefaults.standard.double(forKey: SettingKey.offsetX))
        offsetY = CGFloat(UserDefaults.standard.double(forKey: SettingKey.offsetY))
        koreanBackgroundColor = colorSetting(SettingKey.koreanBackgroundColor, fallback: defaultKoreanBackground)
        koreanTextColor = colorSetting(SettingKey.koreanTextColor, fallback: defaultKoreanText)
        englishBackgroundColor = colorSetting(SettingKey.englishBackgroundColor, fallback: defaultEnglishBackground)
        englishTextColor = colorSetting(SettingKey.englishTextColor, fallback: defaultEnglishText)
    }

    private func saveOptions() {
        UserDefaults.standard.set(keepVisible, forKey: SettingKey.keepVisible)
        UserDefaults.standard.set(preferCaret, forKey: SettingKey.preferCaret)
        UserDefaults.standard.set(Double(badgeSize), forKey: SettingKey.badgeSize)
        UserDefaults.standard.set(koreanLabel, forKey: SettingKey.koreanLabel)
        UserDefaults.standard.set(englishLabel, forKey: SettingKey.englishLabel)
        UserDefaults.standard.set(customImagePath, forKey: SettingKey.customImagePath)
        UserDefaults.standard.set(anchor.rawValue, forKey: SettingKey.anchor)
        UserDefaults.standard.set(Double(offsetX), forKey: SettingKey.offsetX)
        UserDefaults.standard.set(Double(offsetY), forKey: SettingKey.offsetY)
        UserDefaults.standard.set(koreanBackgroundColor.hexString, forKey: SettingKey.koreanBackgroundColor)
        UserDefaults.standard.set(koreanTextColor.hexString, forKey: SettingKey.koreanTextColor)
        UserDefaults.standard.set(englishBackgroundColor.hexString, forKey: SettingKey.englishBackgroundColor)
        UserDefaults.standard.set(englishTextColor.hexString, forKey: SettingKey.englishTextColor)
    }

    private func applyAppearanceOptions() {
        window.applyBadgeSize(badgeSize)
        window.badgeView.koreanBackgroundColor = koreanBackgroundColor
        window.badgeView.koreanTextColor = koreanTextColor
        window.badgeView.englishBackgroundColor = englishBackgroundColor
        window.badgeView.englishTextColor = englishTextColor
        if !customImagePath.isEmpty, let image = NSImage(contentsOfFile: customImagePath) {
            window.badgeView.badgeImage = image
        } else {
            window.badgeView.badgeImage = nil
        }
        window.badgeView.needsDisplay = true
    }

    private func colorSetting(_ key: String, fallback: String) -> NSColor {
        let hex = UserDefaults.standard.string(forKey: key) ?? fallback
        return NSColor(hex: hex) ?? NSColor(hex: fallback)!
    }

    private func observeInputSourceChanges() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }

    private func installMouseMonitors() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.fastMouseUpdate()
            }
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.fastMouseUpdate()
            return event
        }
    }

    private func askForAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @objc private func tick() {
        refreshInputSourceIfNeeded(force: false)
        updateIdleOpacity()

        guard keepVisible || Date() < hideAt else {
            window.orderOut(nil)
            return
        }

        if preferCaret {
            moveBadge(near: caretPoint() ?? lastCaretPoint ?? mousePoint())
        } else {
            moveBadge(near: mousePoint())
        }
        if !window.isVisible {
            window.orderFrontRegardless()
        }
    }

    @objc private func inputSourceChanged() {
        hideAt = Date().addingTimeInterval(2.0)
        refreshInputSourceIfNeeded(force: true)
        tick()
    }

    private func refreshInputSourceIfNeeded(force: Bool) {
        let now = Date()
        guard force || now.timeIntervalSince(lastInputCheck) > 0.30 else {
            return
        }
        lastInputCheck = now

        let current = currentInputLabel()
        cachedLabel = current.label
        cachedIsKorean = current.isKorean
        cachedSourceID = current.sourceID

        if current.label != lastLabel {
            lastLabel = current.label
            hideAt = now.addingTimeInterval(1.8)
        }
        if current.sourceID != lastInputSourceID {
            lastInputSourceID = current.sourceID
            hideAt = now.addingTimeInterval(1.8)
        }

        window.badgeView.label = cachedLabel
        window.badgeView.isKoreanInput = cachedIsKorean
    }

    private func fastMouseUpdate() {
        markMouseActive()
        guard !preferCaret else {
            return
        }
        guard keepVisible || Date() < hideAt else {
            return
        }
        moveBadge(near: mousePoint())
        if !window.isVisible {
            window.orderFrontRegardless()
        }
    }

    private func markMouseActive() {
        lastMouseActivity = Date()
        guard isDimmed || window.alphaValue < activeBadgeOpacity else {
            return
        }
        isDimmed = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window.animator().alphaValue = activeBadgeOpacity
        }
    }

    private func updateIdleOpacity() {
        guard window.isVisible else {
            return
        }
        let shouldDim = Date().timeIntervalSince(lastMouseActivity) >= idleDimDelay
        guard shouldDim != isDimmed else {
            return
        }
        isDimmed = shouldDim
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            window.animator().alphaValue = shouldDim ? idleBadgeOpacity : activeBadgeOpacity
        }
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
        badgeSize = max(14, min(72, value))
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func setLabels(korean: String, english: String) {
        koreanLabel = String(korean.prefix(3))
        englishLabel = String(english.prefix(3))
        saveOptions()
        refreshInputSourceIfNeeded(force: true)
        window.badgeView.needsDisplay = true
    }

    fileprivate func setColors(
        koreanBackground: NSColor,
        koreanText: NSColor,
        englishBackground: NSColor,
        englishText: NSColor
    ) {
        koreanBackgroundColor = koreanBackground
        koreanTextColor = koreanText
        englishBackgroundColor = englishBackground
        englishTextColor = englishText
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func setCustomImagePath(_ path: String) {
        customImagePath = path
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func setPosition(anchor: BadgeAnchor, offsetX: CGFloat, offsetY: CGFloat) {
        self.anchor = anchor
        self.offsetX = max(-200, min(200, offsetX))
        self.offsetY = max(-200, min(200, offsetY))
        saveOptions()
        if preferCaret {
            if let point = caretPoint() ?? lastCaretPoint {
                moveBadge(near: point)
            }
        } else {
            moveBadge(near: mousePoint())
        }
    }

    fileprivate func resetOptions() {
        keepVisible = true
        preferCaret = true
        badgeSize = defaultBadgeSize
        koreanLabel = "한"
        englishLabel = "A"
        customImagePath = ""
        koreanBackgroundColor = NSColor(hex: defaultKoreanBackground)!
        koreanTextColor = NSColor(hex: defaultKoreanText)!
        englishBackgroundColor = NSColor(hex: defaultEnglishBackground)!
        englishTextColor = NSColor(hex: defaultEnglishText)!
        anchor = .bottomRight
        offsetX = 18
        offsetY = -32
        saveOptions()
        applyAppearanceOptions()
    }

    @objc fileprivate func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
        }
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
        }
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
        return location
    }

    private func caretPoint() -> CGPoint? {
        guard AXIsProcessTrusted() else {
            return nil
        }

        let systemWide = AXUIElementCreateSystemWide()
        if let focusedElement = axElement(systemWide, kAXFocusedUIElementAttribute),
           let point = caretPoint(in: focusedElement) {
            lastCaretPoint = point
            return point
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
        if let point = caretPoint(in: focusedElement) {
            lastCaretPoint = point
            return point
        }

        return nil
    }

    private func caretPoint(in focusedElement: AXUIElement) -> CGPoint? {
        if let textElement = bestTextElement(from: focusedElement),
           let rect = selectedTextRect(textElement) {
            return CGPoint(x: rect.midX, y: rect.midY)
        }

        if let textElement = bestTextElement(from: focusedElement),
           let rect = elementRect(textElement) {
            return CGPoint(x: rect.minX, y: rect.maxY)
        }

        return nil
    }

    private func bestTextElement(from element: AXUIElement) -> AXUIElement? {
        if selectedTextRect(element) != nil {
            return element
        }
        if isTextLike(element) {
            return element
        }
        if let focusedChild = axElement(element, kAXFocusedUIElementAttribute),
           let match = bestTextElement(from: focusedChild) {
            return match
        }
        if let childMatch = firstTextElementInChildren(of: element, depth: 0) {
            return childMatch
        }
        if let parent = axElement(element, kAXParentAttribute) {
            if selectedTextRect(parent) != nil || isTextLike(parent) {
                return parent
            }
            return firstTextElementInChildren(of: parent, depth: 0)
        }
        return nil
    }

    private func firstTextElementInChildren(of element: AXUIElement, depth: Int) -> AXUIElement? {
        guard depth < 3 else {
            return nil
        }
        guard let children = axElements(element, kAXChildrenAttribute) else {
            return nil
        }
        for child in children {
            if selectedTextRect(child) != nil || isTextLike(child) {
                return child
            }
            if let match = firstTextElementInChildren(of: child, depth: depth + 1) {
                return match
            }
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

    private func axElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              value != nil else {
            return nil
        }
        return (value as! AXUIElement)
    }

    private func axElements(_ element: AXUIElement, _ attribute: String) -> [AXUIElement]? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let values = value as? [Any] else {
            return nil
        }
        return values.compactMap { $0 as! AXUIElement? }
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

        if let rect = boundsForRange(axRange, originalRange: range, element: element) {
            return rect
        }

        if range.length == 0 {
            if let nextRange = makeAXRange(location: range.location, length: 1),
               let rect = boundsForRange(nextRange, originalRange: CFRange(location: range.location, length: 1), element: element) {
                return CGRect(x: rect.minX, y: rect.minY, width: 1, height: rect.height)
            }
            if range.location > 0,
               let previousRange = makeAXRange(location: range.location - 1, length: 1),
               let rect = boundsForRange(previousRange, originalRange: CFRange(location: range.location - 1, length: 1), element: element) {
                return CGRect(x: rect.maxX, y: rect.minY, width: 1, height: rect.height)
            }
        }

        return nil
    }

    private func makeAXRange(location: Int, length: Int) -> AXValue? {
        var range = CFRange(location: location, length: length)
        return AXValueCreate(.cfRange, &range)
    }

    private func boundsForRange(_ axRange: AXValue, originalRange range: CFRange, element: AXUIElement) -> CGRect? {
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
        var origin: CGPoint
        switch anchor {
        case .bottomRight:
            origin = CGPoint(x: point.x + offsetX, y: point.y + offsetY - size.height)
        case .topRight:
            origin = CGPoint(x: point.x + offsetX, y: point.y + offsetY)
        case .bottomLeft:
            origin = CGPoint(x: point.x + offsetX - size.width, y: point.y + offsetY - size.height)
        case .topLeft:
            origin = CGPoint(x: point.x + offsetX - size.width, y: point.y + offsetY)
        case .centered:
            origin = CGPoint(x: point.x + offsetX - size.width / 2, y: point.y + offsetY - size.height / 2)
        }
        origin.x = max(screenFrame.minX + 6, min(origin.x, screenFrame.maxX - size.width - 6))
        origin.y = max(screenFrame.minY + 6, min(origin.y, screenFrame.maxY - size.height - 6))
        window.setFrameOrigin(origin)
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
