import AppKit
import Carbon
import CoreGraphics
import Foundation
import ImageIO
import os
import UniformTypeIdentifiers

private let log = Logger(subsystem: "com.caticator", category: "app")

private let appVersion = "0.3.1"
private let defaultBadgeSize: CGFloat = 25
private let badgeOuterPadding: CGFloat = 5
private let badgeAspectRatio: CGFloat = 1.42
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
    static let idleDimDelay = "idleDimDelay"
    static let badgeDisplayMode = "badgeDisplayMode"
    static let blackCatMode = "blackCatMode"
    static let blackCatGifPath = "blackCatGifPath"
    static let koreanImagePath = "koreanImagePath"
    static let englishImagePath = "englishImagePath"
    static let flipHorizontal = "flipHorizontal"
    static let excludedApps = "excludedApps"
}

// swiftlint:disable line_length
private let embeddedBlackCatGif = "R0lGODlhQABAAIEAAAAAAAgIBwAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQJDAAAACwAAAAAQABAAAAI/wABCBxIsKDBgwgTKlzIsKHDhxAjSpxIsaLFixgzatzIsaPHjyBDihxJsqTJkAECnFyYsqXKgilXKnQZc6BLhDVF0qRJ8ObBnCh3tuzJ02ZRkEJfEvUpcKdOoUuTQv3o9KfUpEiPwrw6lWNVnFy/bhRrMCzWsVrLmiV7kW3TtV3bpt0Kdy5Ft0bf+qy7NipQsHqHAuBr1q/ShIQTw2WouDFXxo4jM2UpuTLEypEvY24scTPnh54VWwxduCLpsBhPS02tOu7d1mdfw8brcLbriLZpU859GzJv3WDFxjY6OXDxhsOHGz+8/O9uu4Pn4lWOuHf049OtG3YeVe1x74Jnahu/zpw8d7rhZapfz769+/fw48ufT7++/fvzAwIAIfkECQwAAAAsAAAAAEAAQACCAAAABgYFFBUUKSoqRkVFNjY2WllaAAAACP8AAQgcSLCgwYMIEypcyLChw4cQI0qcSLGixYsYM2rcyLGjx48gQ4ocSbKkyZADBpxcGKClS4MtVyp0+XIgTYQxSdLcSfDmwZwjd/oUKLTn0JBCA8DkafMoyKRGk0oVyXSpVKhInTa9WvRj1Z9cu3r8ajUs2Yxno5rVijEtgLVTN4otC7emxrkFc3aty1ctUJxK3zLlW9dv4ISEEydmqbhxWAMEGDuejBcw5csEIju8TDki58kTPzv2LFrxxdJrT6PmKgDt6riqX8OmKPsqxgG1K0sskNvtw95JW9MGvlM4aayzt9olmryhbcG68T7fLNU4c7bRdSOefn258r/fwUsj9q4WLFu/ELWn1f7dYwGZ8OPLn0+/vv37+PPr38+/v/+QAQEAIfkECQwAAAAsAAAAAEAAQACDAAAABgYGERIRSEdHaGhpWlpaJSUmeXZ6Oz07IB4gAAAAAAAAAAAAAAAAAAAAAAAACP8AAQgcSLCgwYMIEypcyLChw4cQI0qcSLGixYsYM2rcyLGjx48gQ4ocSbKkyZMoDQZYydKggAEpE7JsWXBlzJozZxLUqTKAyZw8BQbd6bMk0KJEgwIlebSn0pwioR48StVmSKlOq2L1uBWn1q4amyL8upRr2alkz4YdijYtW4tgvbp9WzFuUgFzrWK0S1TozAQA8qZtq1dm0ZwGAgtezHcg48eDF0KeLJYh5cs0HWKmDHHz4wMTPQsmEFq04IsGTH+9iEC11oyuqcKOrbYu7coUb+MurZvuw967OwNvbHg48aSvkWdWjtSvbIWRHdd2vhzAgKrFsWdvLv1t8qwzBxQqKEB6O+HCzNF3P+78PHe5vi3ifa84/s37+PPr38+/v///AAYo4IAEhhQQACH5BAkMAAAALAAAAABAAEAAggAAAAcHBhMTEyYnJURERGRjZDEyMnp4eQj/AAEIHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8ePIEOKHEmypMmQAQKcXJiypcqCKREKeGnSZcyBLhHeHGkzJ86WOmmK7An0p0+BPXkmhWmT4FKUTwEQnVr0o00BB6lS/TiAQFSjWpt6/Oo0LNmMZ5GaJdoxrdS1bilezQqXrUa3de2idYk1qFqfeeuWPer3LeDAawdXDYq4MVyWjiOHhSy5MuGEljPvZKi58sPOkiOCjvx5dOOKphPLTT3ZIuutrl/rXS17tujatiHizl1692WHvmH3Di52eHHDv3NPvT2b6AGmx/9GV7j8oAGbBQrOnC79N920A2wSKYDuHXl5sOe5x+0u9Dv37u43M168sr79+/jz69/Pv7///wAGKOCACQUEACH5BAkMAAAALAAAAABAAEAAggAAAAcHBhgYFllZWWlpaiEhIIKAgH9/fQj/AAEIHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8ePIEOKHEmypMmTKCUGCIBwJcqVMFkOjNlSpkgCAwrEhEmQ5kGXI3fu7Dl0ZlGQQoES9SlQqMikNgFAnRqVo9OfVJMiPVowq9aOV2t6ZboxLNaxXDGaLXgA7dqLb5u6jTuRrlwBc3lmtCtV5tW8Y5fqVQj0L+CsgpUmPMw48MLGkKcyjEx58OPKlCFihqx5M2OVng93Dp3XImmvpk9TVav6a+rWaevCdi17duzRti2Dzq0bN++qvh0nnlubLG25ZJHzPYg3KYGBA97SPT6Zet/e062f3Yn3rIGCzXsXIYx+ezvMAosVK1dvHnjK9/Djy59Pv779+/jz69/Pv7//gAAh+QQJDAAAACwAAAAAQABAAIIAAAAHBwYRERBvcXA7PDwAAAAAAAAAAAAI/wABCBxIsKDBgwgTKlzIsKHDhxAjSpxIsaLFixgzatzIsaPHjyBDihxJsqTJkAECnGSYsqXBlAgJrBTYEubAmghtkqyJ82bLAQd1juTp0mdPmjyHEhVQkChBpyKJ6pRKtehHqE2rUkWZ9KVWqVe7Bv2KlWPZrGTPYlRrNO1RjTyZenXLlmJdAHTBwq0pdyzSnnnpohXqF2/XwG4Hq1SIuHHehY4jk4UsubJYxpYzL26oufLDzpIjgo78eXTjiqbTok799SLrqq5f610te7bE2lvt4r7Lcvfl0r5tMxQQPLdD2G3f/rX6VHjC1smZLyc8XfpY5HOt3zV+/XDO34aVNyXnzb27QeLiu1Mfv9684s2Y08+cT7++/fv48+vfz7+///8A3hcQACH5BAkMAAAALAAAAABAAEAAggAAAAYGBigpKTIzMxcXF25tb1BQTwAAAAj/AAEIHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8ePIEOKHEmypMmTKA0GWMlSZYCUCVm2LLgSJkGZOF8OlImw5sicPHfOdEkSqM6bOJEGBWmUoIECOZUO7Rj1oNGrR6kmtYoVqMeqPbuC3TjWpdiyF9FKPTsVo1oAbJtmfCswrte5W8MaHSAA6wC+Av4GFkCAwNW1WcPW3WqXLWKGPqs2npw3JuXLYiFj3kyXJufPPjWD5gxx9ObSpi9LTK36IWABhFmftSg7c9racmnjvqt7N++JvnMDD95ZNPG2D48fjqhc+EKsntG2bggdcWihleH+Vric61Ls38GHLo+e3Tvy7Ys7AyVg3Ox48tfdx7c833B5+Ilt6t/Pv7///wAGKOCABBZo4IETBQQAIfkECQwAAAAsAAAAAEAAQACBAAAABwcGEhITAAAACP8AAQgcSLCgwYMIEypcyLChw4cQI0qcSLGixYsYM2rcyLGjx48gQ4ocSbKkyZABApxcmLKlyoIpVyp0GXOgS4Q1RdKkSfDmwZwod7bsydNmUZBCXxL1KXCnTqFLk0L96PSn1KRIj8K8OpVjVZxcv24UazAs1rFay5ole5Ft07Vd26bdCncuRbdG3/qsuzYqULB6hwLga9av0oSEE8NlqLgxV8aOIzNlKbkyxMqRL2NuLHEz54eeFVsMXbgi6bAYT0tNrTru3dZnX8PG63C264i2aVPOfXuhAN6xIa82yrZ4b7Bugwf+O/g4XbuG1U42zPz5dOmCo1vV3fz69sPLwX8cr659t3ju3bPLXM++vfv38OPLn0+/vv37+OkHBAA7"
// swiftlint:enable line_length

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
        didSet { needsDisplay = true }
    }
    var koreanBadgeImage: NSImage? {
        didSet { needsDisplay = true }
    }
    var englishBadgeImage: NSImage? {
        didSet { needsDisplay = true }
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
    var flipHorizontal = false {
        didSet { needsDisplay = true }
    }
    var gifFrames: [(CGImage, TimeInterval)] = []
    var currentFrameIndex = 0
    private var gifTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current else { return }
        context.imageInterpolation = .high
        context.shouldAntialias = true

        // GIF 애니메이션 프레임 — 이미지/레이블 모두 스킵
        if !gifFrames.isEmpty {
            let cgCtx = context.cgContext
            cgCtx.saveGState()
            if flipHorizontal {
                cgCtx.translateBy(x: bounds.width, y: 0)
                cgCtx.scaleBy(x: -1, y: 1)
            }
            cgCtx.draw(gifFrames[currentFrameIndex].0, in: bounds)
            cgCtx.restoreGState()
            return
        }

        // 정적 이미지 — 언어별 이미지 우선, 레이블 스킵
        let langImage = isKoreanInput ? koreanBadgeImage : englishBadgeImage
        if let image = langImage ?? badgeImage {
            NSGraphicsContext.saveGraphicsState()
            if flipHorizontal {
                let t = NSAffineTransform()
                t.translateX(by: bounds.width, yBy: 0)
                t.scaleX(by: -1, yBy: 1)
                t.concat()
            }
            image.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            return
        }

        // 색상 배지 + 레이블
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

    func loadGIF(from url: URL) {
        log.info("loadGIF(url): \(url.lastPathComponent)")
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            log.error("loadGIF(url): CGImageSourceCreateWithURL failed — \(url.path)")
            return
        }
        loadGIF(source: src)
    }

    func loadGIF(from data: Data) {
        log.info("loadGIF(data): \(data.count) bytes")
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
            log.error("loadGIF(data): CGImageSourceCreateWithData failed")
            return
        }
        loadGIF(source: src)
    }

    private func loadGIF(source src: CGImageSource) {
        stopGIFAnimation()
        gifFrames = []
        currentFrameIndex = 0
        let count = CGImageSourceGetCount(src)
        log.info("loadGIF(source): \(count) frame(s) found")

        // 1패스: 모든 프레임 수집 + 최대 크기 파악
        var rawFrames: [(CGImage, TimeInterval)] = []
        var maxSide = 0
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(src, i, nil) else {
                log.warning("loadGIF: frame \(i) skipped")
                continue
            }
            let props = CGImageSourceCopyPropertiesAtIndex(src, i, nil) as? [CFString: Any]
            let gifProps = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gifProps?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (gifProps?[kCGImagePropertyGIFDelayTime] as? Double)
                ?? 0.1
            maxSide = max(maxSide, cgImage.width, cgImage.height)
            rawFrames.append((cgImage, max(0.02, delay)))
        }

        // 2패스: 정사각형 캔버스로 통일 + 배경 제거
        let side = max(maxSide, 1)
        for (cgImage, delay) in rawFrames {
            let normalized = normalizeFrame(cgImage, side: side)
            let processed = removeBackground(normalized) ?? normalized
            gifFrames.append((processed, delay))
        }

        log.info("loadGIF: loaded \(self.gifFrames.count) frame(s), canvas=\(side)x\(side)")
        if !gifFrames.isEmpty { scheduleNextFrame() }
        else { log.error("loadGIF: no frames loaded — nothing will display") }
    }

    // 임의 크기 프레임을 side×side 정사각형 중앙 배치로 정규화
    private func normalizeFrame(_ src: CGImage, side: Int) -> CGImage {
        guard src.width != side || src.height != side else { return src }
        guard let ctx = CGContext(
            data: nil, width: side, height: side,
            bitsPerComponent: 8, bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return src }
        let ox = (side - src.width) / 2
        let oy = (side - src.height) / 2
        ctx.draw(src, in: CGRect(x: ox, y: oy, width: src.width, height: src.height))
        return ctx.makeImage() ?? src
    }

    // 밝은 단색 배경을 투명으로 변환. 크래시 방지를 위해 경계 검사 포함.
    private func removeBackground(_ src: CGImage) -> CGImage? {
        let w = src.width, h = src.height
        guard w > 0, h > 0 else { return nil }

        // 기존 투명 픽셀이 있으면 처리 생략
        let ai = src.alphaInfo
        let hasRealAlpha = ai == .premultipliedLast || ai == .premultipliedFirst
            || ai == .last || ai == .first || ai == .alphaOnly
        if hasRealAlpha {
            guard let ctx0 = CGContext(
                data: nil, width: min(w, 4), height: min(h, 4),
                bitsPerComponent: 8, bytesPerRow: min(w, 4) * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }
            ctx0.draw(src, in: CGRect(x: 0, y: 0, width: min(w, 4), height: min(h, 4)))
            if let d = ctx0.data {
                let b = d.bindMemory(to: UInt8.self, capacity: min(w, 4) * min(h, 4) * 4)
                for i in 0..<(min(w, 4) * min(h, 4)) {
                    if b[i * 4 + 3] < 200 {
                        log.debug("removeBackground: already has transparency — skip")
                        return nil
                    }
                }
            }
        }

        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            log.error("removeBackground: CGContext creation failed (\(w)x\(h))")
            return nil
        }
        ctx.draw(src, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return nil }

        let totalPixels = w * h
        let buf = data.bindMemory(to: UInt8.self, capacity: totalPixels * 4)

        // 모서리 3곳으로 배경 밝기 판정
        let corners = [0, (w - 1), w * (h - 1)]
        let avgBg = corners.map { idx -> Int in
            Int(buf[idx * 4]) + Int(buf[idx * 4 + 1]) + Int(buf[idx * 4 + 2])
        }.reduce(0, +) / (corners.count * 3)

        guard avgBg > 180 else {
            log.debug("removeBackground: background not bright (avg=\(avgBg)) — skip")
            return nil
        }

        let threshold: UInt8 = 160
        for i in 0..<totalPixels {
            let r = buf[i * 4], g = buf[i * 4 + 1], b = buf[i * 4 + 2]
            if r > threshold && g > threshold && b > threshold {
                buf[i * 4 + 3] = 0
            }
        }
        log.debug("removeBackground: applied to \(w)x\(h)")
        return ctx.makeImage()
    }

    func stopGIFAnimation() {
        gifTimer?.invalidate()
        gifTimer = nil
    }

    private func scheduleNextFrame() {
        guard !gifFrames.isEmpty else { return }
        let delay = gifFrames[currentFrameIndex].1
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, !self.gifFrames.isEmpty else { return }
            self.currentFrameIndex = (self.currentFrameIndex + 1) % self.gifFrames.count
            self.needsDisplay = true
            self.scheduleNextFrame()
        }
        RunLoop.main.add(timer, forMode: .common)
        gifTimer = timer
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
        // Dock(~20), 메뉴바(~24) 위에 표시되려면 25+ 필요
        // statusBar(25)보다 한 단계 높은 레벨 사용
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) - 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        orderOut(nil)
    }

    func applyBadgeSize(_ size: CGFloat, imageMode: Bool = false) {
        let width = max(14, min(72, size))
        let windowWidth = imageMode ? width : width * badgeAspectRatio + badgeOuterPadding * 2
        let windowHeight = imageMode ? width : width + badgeOuterPadding * 2
        badgeView.badgeSize = width
        badgeView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        setContentSize(NSSize(width: windowWidth, height: windowHeight))
    }
}

private final class SettingsWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    private unowned let appDelegate: AppDelegate
    private let keepVisibleButton = NSButton(checkboxWithTitle: "Keep badge visible", target: nil, action: nil)
    private let preferCaretButton = NSButton(checkboxWithTitle: "Prefer text cursor position", target: nil, action: nil)
    private let axStatusLabel = NSTextField(labelWithString: "Checking...")
    private let sizeSlider = NSSlider(value: Double(defaultBadgeSize), minValue: 14, maxValue: 72, target: nil, action: nil)
    private let sizeValueLabel = NSTextField(string: "\(Int(defaultBadgeSize))")
    private let dimDelayField = NSTextField(string: "2.0")
    private let koreanLabelField = NSTextField(string: "한")
    private let englishLabelField = NSTextField(string: "A")
    private let imagePathLabel = NSTextField(labelWithString: "No custom image selected")
    private let anchorPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let offsetXField = NSTextField(string: "-4")
    private let offsetYField = NSTextField(string: "-10")
    private let koreanBackgroundWell = NSColorWell(frame: .zero)
    private let koreanTextWell = NSColorWell(frame: .zero)
    private let englishBackgroundWell = NSColorWell(frame: .zero)
    private let englishTextWell = NSColorWell(frame: .zero)
    private let labelsRadio = NSButton(radioButtonWithTitle: "Labels (Default)", target: nil, action: nil)
    private let imagesRadio = NSButton(radioButtonWithTitle: "Image per language", target: nil, action: nil)
    private var labelsSectionView: NSView?
    private var imagesSectionView: NSView?
    private let koreanImageLabel = NSTextField(labelWithString: "No image selected")
    private let englishImageLabel = NSTextField(labelWithString: "No image selected")
    private let flipHCheckbox = NSButton(checkboxWithTitle: "Flip Horizontal", target: nil, action: nil)
    private let blackCatCheckbox = NSButton(checkboxWithTitle: "BlackCat Mode  (Korean only — shows animated GIF, hides on English)", target: nil, action: nil)
    private let blackCatGifLabel = NSTextField(labelWithString: "Built-in GIF (no override)")
    private let excludedTable = NSTableView()
    // (bundleID, displayName) 순서 있는 배열 — 테이블 표시용
    private var excludedList: [(id: String, name: String)] = []

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 430),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Caticator Settings"
        window.center()
        super.init(window: window)
        buildContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh() {
        let axTrusted = AXIsProcessTrusted()
        if axTrusted {
            axStatusLabel.stringValue = "✅  Accessibility: Granted — caret tracking active"
            axStatusLabel.textColor = NSColor.systemGreen
        } else {
            axStatusLabel.stringValue = "❌  Accessibility: Not granted — badge will follow mouse only"
            axStatusLabel.textColor = NSColor.systemRed
        }
        keepVisibleButton.state = appDelegate.keepVisible ? .on : .off
        preferCaretButton.state = appDelegate.preferCaret ? .on : .off
        sizeSlider.doubleValue = Double(appDelegate.badgeSize)
        sizeValueLabel.stringValue = "\(Int(appDelegate.badgeSize))"
        dimDelayField.stringValue = String(format: "%.1f", appDelegate.idleDimDelay)
        koreanLabelField.stringValue = appDelegate.koreanLabel
        englishLabelField.stringValue = appDelegate.englishLabel
        anchorPopup.selectItem(withTitle: appDelegate.anchor.title)
        offsetXField.stringValue = "\(Int(appDelegate.offsetX))"
        offsetYField.stringValue = "\(Int(appDelegate.offsetY))"
        koreanBackgroundWell.color = appDelegate.koreanBackgroundColor
        koreanTextWell.color = appDelegate.koreanTextColor
        englishBackgroundWell.color = appDelegate.englishBackgroundColor
        englishTextWell.color = appDelegate.englishTextColor
        let mode = appDelegate.badgeDisplayMode
        labelsRadio.state = mode == "labels" ? .on : .off
        imagesRadio.state = mode == "images" ? .on : .off
        updateSectionVisibility(mode: mode)
        koreanImageLabel.stringValue = appDelegate.koreanImagePath.isEmpty ? "No image selected" : appDelegate.koreanImagePath
        englishImageLabel.stringValue = appDelegate.englishImagePath.isEmpty ? "No image selected" : appDelegate.englishImagePath
        flipHCheckbox.state = appDelegate.flipHorizontal ? .on : .off
        blackCatCheckbox.state = appDelegate.blackCatMode ? .on : .off
        blackCatGifLabel.stringValue = appDelegate.blackCatGifPath.isEmpty ? "Built-in GIF (no override)" : appDelegate.blackCatGifPath
    }

    private func updateSectionVisibility(mode: String) {
        labelsSectionView?.isHidden = mode != "labels"
        imagesSectionView?.isHidden = mode != "images"
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

        // AX 권한 상태 표시
        axStatusLabel.frame = NSRect(x: 26, y: 80, width: 460, height: 20)
        axStatusLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        view.addSubview(axStatusLabel)

        let diagButton = NSButton(title: "🔍 Diagnose Caret", target: self, action: #selector(diagnoseAX))
        diagButton.frame = NSRect(x: 26, y: 46, width: 160, height: 28)
        view.addSubview(diagButton)

        let reqButton = NSButton(title: "Request Permission", target: self, action: #selector(requestAXPermission))
        reqButton.frame = NSRect(x: 196, y: 46, width: 160, height: 28)
        view.addSubview(reqButton)

        let accessButton = NSButton(title: "Open AX Settings", target: self, action: #selector(openAccessibilitySettings))
        accessButton.frame = NSRect(x: 366, y: 46, width: 130, height: 28)
        view.addSubview(accessButton)

        return view
    }

    private func indicatorView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 510, height: 340))
        addHeader("Badge Appearance", to: view, y: 312)

        // ── Icon size ────────────────────────────────────────────
        let sizeTitle = NSTextField(labelWithString: "Icon size")
        sizeTitle.frame = NSRect(x: 26, y: 280, width: 80, height: 22)
        view.addSubview(sizeTitle)
        sizeSlider.frame = NSRect(x: 108, y: 274, width: 200, height: 30)
        sizeSlider.target = self; sizeSlider.action = #selector(sizeChanged)
        view.addSubview(sizeSlider)
        sizeValueLabel.frame = NSRect(x: 314, y: 274, width: 52, height: 28)
        sizeValueLabel.isEditable = true
        sizeValueLabel.isBordered = true
        sizeValueLabel.bezelStyle = .roundedBezel
        sizeValueLabel.target = self
        sizeValueLabel.action = #selector(sizeFieldChanged)
        view.addSubview(sizeValueLabel)
        let pxLabel = NSTextField(labelWithString: "px")
        pxLabel.frame = NSRect(x: 370, y: 280, width: 28, height: 18)
        pxLabel.textColor = .secondaryLabelColor
        view.addSubview(pxLabel)
        flipHCheckbox.frame = NSRect(x: 402, y: 278, width: 130, height: 20)
        flipHCheckbox.target = self
        flipHCheckbox.action = #selector(flipHChanged)
        view.addSubview(flipHCheckbox)

        // ── Display mode radio buttons ───────────────────────────
        labelsRadio.frame = NSRect(x: 26, y: 252, width: 160, height: 20)
        labelsRadio.target = self; labelsRadio.action = #selector(modeChanged)
        view.addSubview(labelsRadio)
        imagesRadio.frame = NSRect(x: 196, y: 252, width: 200, height: 20)
        imagesRadio.target = self; imagesRadio.action = #selector(modeChanged)
        view.addSubview(imagesRadio)

        // ── Labels section (y=158, h=88) ─────────────────────────
        let labSec = NSView(frame: NSRect(x: 0, y: 158, width: 510, height: 88))
        let korTitle = NSTextField(labelWithString: "Korean")
        korTitle.frame = NSRect(x: 26, y: 54, width: 60, height: 20)
        labSec.addSubview(korTitle)
        koreanLabelField.frame = NSRect(x: 88, y: 50, width: 48, height: 28)
        koreanLabelField.target = self; koreanLabelField.action = #selector(labelChanged)
        labSec.addSubview(koreanLabelField)
        koreanBackgroundWell.frame = NSRect(x: 142, y: 50, width: 36, height: 28)
        koreanBackgroundWell.target = self; koreanBackgroundWell.action = #selector(colorChanged)
        labSec.addSubview(koreanBackgroundWell)
        koreanTextWell.frame = NSRect(x: 182, y: 50, width: 36, height: 28)
        koreanTextWell.target = self; koreanTextWell.action = #selector(colorChanged)
        labSec.addSubview(koreanTextWell)
        let engTitle = NSTextField(labelWithString: "English")
        engTitle.frame = NSRect(x: 246, y: 54, width: 60, height: 20)
        labSec.addSubview(engTitle)
        englishLabelField.frame = NSRect(x: 308, y: 50, width: 48, height: 28)
        englishLabelField.target = self; englishLabelField.action = #selector(labelChanged)
        labSec.addSubview(englishLabelField)
        englishBackgroundWell.frame = NSRect(x: 362, y: 50, width: 36, height: 28)
        englishBackgroundWell.target = self; englishBackgroundWell.action = #selector(colorChanged)
        labSec.addSubview(englishBackgroundWell)
        englishTextWell.frame = NSRect(x: 402, y: 50, width: 36, height: 28)
        englishTextWell.target = self; englishTextWell.action = #selector(colorChanged)
        labSec.addSubview(englishTextWell)
        let colorHelp = NSTextField(labelWithString: "Order: label, background, text")
        colorHelp.textColor = .secondaryLabelColor
        colorHelp.font = NSFont.systemFont(ofSize: 11)
        colorHelp.frame = NSRect(x: 26, y: 24, width: 300, height: 18)
        labSec.addSubview(colorHelp)
        labelsSectionView = labSec
        view.addSubview(labSec)

        // ── Images section (same y=158, h=88, overlapping) ───────
        let imgSec = NSView(frame: NSRect(x: 0, y: 158, width: 510, height: 88))
        let korImgTitle = NSTextField(labelWithString: "Korean image")
        korImgTitle.frame = NSRect(x: 26, y: 64, width: 110, height: 16)
        imgSec.addSubview(korImgTitle)
        koreanImageLabel.frame = NSRect(x: 26, y: 46, width: 236, height: 15)
        koreanImageLabel.font = NSFont.systemFont(ofSize: 10)
        koreanImageLabel.textColor = .secondaryLabelColor
        koreanImageLabel.lineBreakMode = .byTruncatingMiddle
        imgSec.addSubview(koreanImageLabel)
        let chooseKorBtn = NSButton(title: "Choose...", target: self, action: #selector(chooseKoreanImage))
        chooseKorBtn.frame = NSRect(x: 268, y: 58, width: 100, height: 26)
        imgSec.addSubview(chooseKorBtn)
        let clearKorBtn = NSButton(title: "Clear", target: self, action: #selector(clearKoreanImage))
        clearKorBtn.frame = NSRect(x: 374, y: 58, width: 60, height: 26)
        imgSec.addSubview(clearKorBtn)
        let engImgTitle = NSTextField(labelWithString: "English image")
        engImgTitle.frame = NSRect(x: 26, y: 26, width: 110, height: 16)
        imgSec.addSubview(engImgTitle)
        englishImageLabel.frame = NSRect(x: 26, y: 8, width: 236, height: 15)
        englishImageLabel.font = NSFont.systemFont(ofSize: 10)
        englishImageLabel.textColor = .secondaryLabelColor
        englishImageLabel.lineBreakMode = .byTruncatingMiddle
        imgSec.addSubview(englishImageLabel)
        let chooseEngBtn = NSButton(title: "Choose...", target: self, action: #selector(chooseEnglishImage))
        chooseEngBtn.frame = NSRect(x: 268, y: 20, width: 100, height: 26)
        imgSec.addSubview(chooseEngBtn)
        let clearEngBtn = NSButton(title: "Clear", target: self, action: #selector(clearEnglishImage))
        clearEngBtn.frame = NSRect(x: 374, y: 20, width: 60, height: 26)
        imgSec.addSubview(clearEngBtn)
        imagesSectionView = imgSec
        view.addSubview(imgSec)

        // ── Cursor position ──────────────────────────────────────
        let anchorTitle = NSTextField(labelWithString: "Cursor position")
        anchorTitle.frame = NSRect(x: 26, y: 126, width: 120, height: 22)
        view.addSubview(anchorTitle)
        anchorPopup.addItems(withTitles: BadgeAnchor.allCases.map(\.title))
        anchorPopup.frame = NSRect(x: 148, y: 122, width: 150, height: 28)
        anchorPopup.target = self; anchorPopup.action = #selector(positionChanged)
        view.addSubview(anchorPopup)
        let offsetTitle = NSTextField(labelWithString: "Offset X/Y")
        offsetTitle.frame = NSRect(x: 310, y: 126, width: 78, height: 22)
        view.addSubview(offsetTitle)
        offsetXField.frame = NSRect(x: 390, y: 122, width: 42, height: 26)
        offsetXField.target = self; offsetXField.action = #selector(positionChanged)
        view.addSubview(offsetXField)
        offsetYField.frame = NSRect(x: 438, y: 122, width: 42, height: 26)
        offsetYField.target = self; offsetYField.action = #selector(positionChanged)
        view.addSubview(offsetYField)

        // ── Idle dim delay ───────────────────────────────────────
        let dimTitleLabel = NSTextField(labelWithString: "Idle dim delay")
        dimTitleLabel.frame = NSRect(x: 26, y: 96, width: 110, height: 20)
        view.addSubview(dimTitleLabel)
        dimDelayField.frame = NSRect(x: 140, y: 92, width: 60, height: 26)
        dimDelayField.isEditable = true
        dimDelayField.isBordered = true
        dimDelayField.bezelStyle = .roundedBezel
        dimDelayField.target = self
        dimDelayField.action = #selector(dimDelayChanged)
        view.addSubview(dimDelayField)
        let secLbl = NSTextField(labelWithString: "sec  (0.1 – 60)")
        secLbl.textColor = .secondaryLabelColor
        secLbl.font = NSFont.systemFont(ofSize: 11)
        secLbl.frame = NSRect(x: 206, y: 96, width: 130, height: 18)
        view.addSubview(secLbl)

        // ── BlackCat Mode ────────────────────────────────────────
        blackCatCheckbox.frame = NSRect(x: 26, y: 64, width: 470, height: 20)
        blackCatCheckbox.target = self; blackCatCheckbox.action = #selector(blackCatModeChanged)
        view.addSubview(blackCatCheckbox)
        let chooseCatBtn = NSButton(title: "Choose Cat GIF...", target: self, action: #selector(chooseBlackCatGif))
        chooseCatBtn.frame = NSRect(x: 26, y: 34, width: 150, height: 26)
        view.addSubview(chooseCatBtn)
        let clearCatBtn = NSButton(title: "Clear", target: self, action: #selector(clearBlackCatGif))
        clearCatBtn.frame = NSRect(x: 182, y: 34, width: 54, height: 26)
        view.addSubview(clearCatBtn)
        blackCatGifLabel.frame = NSRect(x: 26, y: 14, width: 420, height: 16)
        blackCatGifLabel.font = NSFont.systemFont(ofSize: 10)
        blackCatGifLabel.textColor = .secondaryLabelColor
        blackCatGifLabel.lineBreakMode = .byTruncatingMiddle
        view.addSubview(blackCatGifLabel)

        return view
    }

    private func advancedView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 510, height: 340))
        addHeader("Advanced", to: view, y: 292)

        // 제외 앱 섹션
        let excludeLabel = NSTextField(labelWithString: "Excluded Apps")
        excludeLabel.frame = NSRect(x: 26, y: 258, width: 200, height: 18)
        excludeLabel.font = NSFont.boldSystemFont(ofSize: 12)
        view.addSubview(excludeLabel)

        let excludeHint = NSTextField(labelWithString: "+ 버튼으로 앱을 추가하면 해당 앱에서는 인디케이터가 숨겨집니다.")
        excludeHint.frame = NSRect(x: 26, y: 238, width: 460, height: 16)
        excludeHint.font = NSFont.systemFont(ofSize: 11)
        excludeHint.textColor = .secondaryLabelColor
        view.addSubview(excludeHint)

        // 테이블
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        col.title = "App"
        col.width = 390
        excludedTable.addTableColumn(col)
        excludedTable.headerView = nil
        excludedTable.rowHeight = 24
        excludedTable.dataSource = self
        excludedTable.delegate = self
        excludedTable.allowsEmptySelection = true

        let scroll = NSScrollView(frame: NSRect(x: 26, y: 152, width: 440, height: 82))
        scroll.documentView = excludedTable
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        view.addSubview(scroll)

        // + / - 버튼
        let addBtn = NSButton(frame: NSRect(x: 26, y: 126, width: 28, height: 22))
        addBtn.title = "+"
        addBtn.bezelStyle = .rounded
        addBtn.target = self
        addBtn.action = #selector(addExcludedApp)
        view.addSubview(addBtn)

        let removeBtn = NSButton(frame: NSRect(x: 58, y: 126, width: 28, height: 22))
        removeBtn.title = "−"
        removeBtn.bezelStyle = .rounded
        removeBtn.target = self
        removeBtn.action = #selector(removeExcludedApp)
        view.addSubview(removeBtn)

        // 목록 초기화
        rebuildExcludedList()

        let resetButton = NSButton(title: "Reset Options", target: self, action: #selector(resetOptions))
        resetButton.frame = NSRect(x: 26, y: 84, width: 130, height: 32)
        view.addSubview(resetButton)

        let buildButton = NSButton(title: "Open Project Folder", target: self, action: #selector(openProjectFolder))
        buildButton.frame = NSRect(x: 170, y: 84, width: 160, height: 32)
        view.addSubview(buildButton)

        return view
    }

    private func aboutView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 510, height: 340))
        addHeader("Caticator \(appVersion)", to: view, y: 292)

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
        sizeValueLabel.stringValue = "\(Int(value))"
        appDelegate.setBadgeSize(value)
    }

    @objc private func sizeFieldChanged() {
        let raw = CGFloat(Double(sizeValueLabel.stringValue) ?? Double(appDelegate.badgeSize))
        let clamped = max(14, min(72, raw)).rounded()
        sizeSlider.doubleValue = Double(clamped)
        sizeValueLabel.stringValue = "\(Int(clamped))"
        appDelegate.setBadgeSize(clamped)
    }

    @objc private func dimDelayChanged() {
        let raw = Double(dimDelayField.stringValue) ?? appDelegate.idleDimDelay
        let clamped = max(0.1, min(60, raw))
        dimDelayField.stringValue = String(format: "%.1f", clamped)
        appDelegate.setIdleDimDelay(clamped)
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
    }

    @objc private func modeChanged() {
        let mode = labelsRadio.state == .on ? "labels" : "images"
        imagesRadio.state = mode == "images" ? .on : .off
        labelsRadio.state = mode == "labels" ? .on : .off
        updateSectionVisibility(mode: mode)
        appDelegate.setBadgeDisplayMode(mode)
    }

    @objc private func chooseKoreanImage() {
        let panel = NSOpenPanel()
        panel.title = "Choose Korean Badge Image"
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff, .bmp, .heic]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            appDelegate.setKoreanImagePath(url.path)
            koreanImageLabel.stringValue = url.path
        }
    }

    @objc private func clearKoreanImage() {
        appDelegate.setKoreanImagePath("")
        koreanImageLabel.stringValue = "No image selected"
    }

    @objc private func chooseEnglishImage() {
        let panel = NSOpenPanel()
        panel.title = "Choose English Badge Image"
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff, .bmp, .heic]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            appDelegate.setEnglishImagePath(url.path)
            englishImageLabel.stringValue = url.path
        }
    }

    @objc private func clearEnglishImage() {
        appDelegate.setEnglishImagePath("")
        englishImageLabel.stringValue = "No image selected"
    }

    @objc private func flipHChanged() {
        appDelegate.setFlipHorizontal(flipHCheckbox.state == .on)
    }

    @objc private func blackCatModeChanged() {
        appDelegate.setBlackCatMode(blackCatCheckbox.state == .on)
    }

    @objc private func chooseBlackCatGif() {
        let panel = NSOpenPanel()
        panel.title = "Choose BlackCat GIF"
        // UTType 필터 없이 모든 파일 표시 — 일부 GIF가 UTType 메타 없으면 필터에서 숨겨짐
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            appDelegate.setBlackCatGifPath(url.path)
            blackCatGifLabel.stringValue = url.lastPathComponent
        }
    }

    @objc private func clearBlackCatGif() {
        appDelegate.setBlackCatGifPath("")
        blackCatGifLabel.stringValue = "Built-in GIF (no override)"
    }

    @objc private func resetOptions() {
        appDelegate.resetOptions()
        refresh()
    }

    @objc private func openAccessibilitySettings() {
        appDelegate.openAccessibilitySettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.refresh() }
    }

    @objc private func requestAXPermission() {
        appDelegate.promptAccessibilityPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.refresh() }
    }

    @objc private func diagnoseAX() {
        let report = appDelegate.runAXDiagnostic()
        let alert = NSAlert()
        alert.messageText = "AX / Caret Detection Diagnostic"
        alert.informativeText = report + "\n\n━━━━━━━━━━━━\n파일 디버그 시작: Settings 닫고 텍스트 필드 클릭 후 5초 기다리면\n~/Desktop/hana_caret_debug.txt 에 결과 저장됩니다."
        alert.addButton(withTitle: "OK + 파일 디버그 시작")
        alert.addButton(withTitle: "닫기")
        alert.alertStyle = .informational
        if alert.runModal() == .alertFirstButtonReturn {
            appDelegate.startCaretDebug()
        }
        refresh()
    }

    @objc private func openProjectFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Users/macpro/Caticator"))
    }

    // MARK: - Excluded Apps

    private func rebuildExcludedList() {
        excludedList = appDelegate.excludedApps.sorted().map { bid in
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid)
            let name = url.flatMap { Bundle(url: $0)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String }
                ?? url.flatMap { Bundle(url: $0)?.object(forInfoDictionaryKey: "CFBundleName") as? String }
                ?? bid
            return (id: bid, name: name)
        }
        excludedTable.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { excludedList.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let entry = excludedList[row]
        let cell = NSTableCellView()
        cell.frame = NSRect(x: 0, y: 0, width: tableColumn?.width ?? 390, height: 24)

        let imgView = NSImageView(frame: NSRect(x: 4, y: 3, width: 18, height: 18))
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: entry.id) {
            imgView.image = NSWorkspace.shared.icon(forFile: url.path)
            imgView.image?.size = NSSize(width: 18, height: 18)
        }
        cell.addSubview(imgView)
        cell.imageView = imgView

        let label = NSTextField(labelWithString: entry.name)
        label.frame = NSRect(x: 28, y: 4, width: (tableColumn?.width ?? 390) - 32, height: 16)
        label.font = NSFont.systemFont(ofSize: 12)
        cell.addSubview(label)
        cell.textField = label

        return cell
    }

    @objc private func addExcludedApp() {
        let panel = NSOpenPanel()
        panel.title = "Choose App to Exclude"
        panel.prompt = "Exclude"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["app"]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }
            guard let bundle = Bundle(url: url),
                  let bid = bundle.bundleIdentifier else { return }
            self.appDelegate.excludedApps.insert(bid)
            self.appDelegate.saveOptionsPublic()
            self.rebuildExcludedList()
        }
    }

    @objc private func removeExcludedApp() {
        let row = excludedTable.selectedRow
        guard row >= 0, row < excludedList.count else { return }
        appDelegate.excludedApps.remove(excludedList[row].id)
        appDelegate.saveOptionsPublic()
        rebuildExcludedList()
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let window = BadgeWindow()
    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private var timer: Timer?
    private var mouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var keyMonitor: Any?
    private var hideAt = Date.distantFuture
    fileprivate var keepVisible = true
    fileprivate var preferCaret = true
    fileprivate var badgeSize: CGFloat = defaultBadgeSize
    fileprivate var koreanLabel = "한"
    fileprivate var englishLabel = "A"
    fileprivate var idleDimDelay: TimeInterval = 2.0
    fileprivate var flipHorizontal = false
    fileprivate var customImagePath = ""
    fileprivate var badgeDisplayMode = "labels"
    fileprivate var blackCatMode = false
    fileprivate var blackCatGifPath = ""
    fileprivate var koreanImagePath = ""
    fileprivate var englishImagePath = ""
    fileprivate var excludedApps: Set<String> = ["com.apple.finder"]
    fileprivate var anchor: BadgeAnchor = .bottomLeft
    fileprivate var offsetX: CGFloat = -4
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
    private var lastCaretCheck = Date.distantPast
    private var lastBadgeSource = ""
    private var caretLostSince: Date? = nil    // AX 위치 소실 시작 시각 (유예용)
    private var lastMouseActivity = Date()
    private var lastTypingActivity = Date()
    private var isDimmed = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("Caticator launched")
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
        item.button?.image = fixedMenuBarImage
        item.button?.title = ""

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "Caticator v\(appVersion)",
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
            title: "Quit Caticator",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        item.menu = menu
        statusItem = item
    }

    // GIF 첫 프레임 → 메뉴바 템플릿 아이콘 (18pt)
    // 앱 시작 시 한 번만 계산 — 이후 절대 변경 안 함
    private lazy var fixedMenuBarImage: NSImage? = {
        guard let data = Data(base64Encoded: embeddedBlackCatGif),
              let src = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
        let side = 18
        guard let ctx = CGContext(
            data: nil, width: side, height: side,
            bitsPerComponent: 8, bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let pixelData = ctx.data else { return nil }
        let buf = pixelData.bindMemory(to: UInt8.self, capacity: side * side * 4)
        for i in 0..<(side * side) {
            let r = buf[i*4], g = buf[i*4+1], b = buf[i*4+2]
            if r > 160 && g > 160 && b > 160 { buf[i*4+3] = 0 }
        }
        guard let result = ctx.makeImage() else { return nil }
        let img = NSImage(cgImage: result, size: NSSize(width: side, height: side))
        img.isTemplate = true
        return img
    }()

    private func loadOptions() {
        UserDefaults.standard.register(defaults: [
            SettingKey.keepVisible: false,
            SettingKey.preferCaret: true,
            SettingKey.badgeSize: Double(defaultBadgeSize),
            SettingKey.koreanLabel: "한",
            SettingKey.englishLabel: "A",
            SettingKey.customImagePath: "",
            SettingKey.anchor: BadgeAnchor.bottomLeft.rawValue,
            SettingKey.offsetX: -4.0,
            SettingKey.offsetY: -10.0,
            SettingKey.koreanBackgroundColor: defaultKoreanBackground,
            SettingKey.koreanTextColor: defaultKoreanText,
            SettingKey.englishBackgroundColor: defaultEnglishBackground,
            SettingKey.englishTextColor: defaultEnglishText,
            SettingKey.idleDimDelay: 2.0,
            SettingKey.flipHorizontal: false,
            SettingKey.badgeDisplayMode: "labels",
            SettingKey.blackCatMode: false,
            SettingKey.blackCatGifPath: "",
            SettingKey.koreanImagePath: "",
            SettingKey.englishImagePath: "",
            SettingKey.excludedApps: "com.apple.finder"
        ])
        keepVisible = UserDefaults.standard.bool(forKey: SettingKey.keepVisible)
        preferCaret = UserDefaults.standard.bool(forKey: SettingKey.preferCaret)
        badgeSize = CGFloat(UserDefaults.standard.double(forKey: SettingKey.badgeSize))
        if badgeSize < 14 || badgeSize > 72 {
            badgeSize = defaultBadgeSize
            UserDefaults.standard.set(Double(badgeSize), forKey: SettingKey.badgeSize)
        }
        koreanLabel = UserDefaults.standard.string(forKey: SettingKey.koreanLabel) ?? "한"
        englishLabel = UserDefaults.standard.string(forKey: SettingKey.englishLabel) ?? "A"
        customImagePath = UserDefaults.standard.string(forKey: SettingKey.customImagePath) ?? ""
        let anchorRawValue = UserDefaults.standard.string(forKey: SettingKey.anchor) ?? BadgeAnchor.bottomLeft.rawValue
        anchor = BadgeAnchor(rawValue: anchorRawValue) ?? .bottomLeft
        offsetX = CGFloat(UserDefaults.standard.double(forKey: SettingKey.offsetX))
        // 구버전 기본값(bottomRight+8) → 왼쪽 정렬 마이그레이션
        if anchor == .bottomRight && offsetX == 8 {
            anchor = .bottomLeft
            offsetX = -4
        }
        offsetY = CGFloat(UserDefaults.standard.double(forKey: SettingKey.offsetY))
        koreanBackgroundColor = colorSetting(SettingKey.koreanBackgroundColor, fallback: defaultKoreanBackground)
        koreanTextColor = colorSetting(SettingKey.koreanTextColor, fallback: defaultKoreanText)
        englishBackgroundColor = colorSetting(SettingKey.englishBackgroundColor, fallback: defaultEnglishBackground)
        englishTextColor = colorSetting(SettingKey.englishTextColor, fallback: defaultEnglishText)
        let rawDelay = UserDefaults.standard.double(forKey: SettingKey.idleDimDelay)
        idleDimDelay = rawDelay > 0 ? max(0.1, min(60, rawDelay)) : 2.0
        flipHorizontal = UserDefaults.standard.bool(forKey: SettingKey.flipHorizontal)
        badgeDisplayMode = UserDefaults.standard.string(forKey: SettingKey.badgeDisplayMode) ?? "labels"
        blackCatMode = UserDefaults.standard.bool(forKey: SettingKey.blackCatMode)
        blackCatGifPath = UserDefaults.standard.string(forKey: SettingKey.blackCatGifPath) ?? ""
        koreanImagePath = UserDefaults.standard.string(forKey: SettingKey.koreanImagePath) ?? ""
        englishImagePath = UserDefaults.standard.string(forKey: SettingKey.englishImagePath) ?? ""
        let saved = UserDefaults.standard.string(forKey: SettingKey.excludedApps) ?? "com.apple.finder"
        excludedApps = Set(saved.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    fileprivate func saveOptionsPublic() { saveOptions() }

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
        UserDefaults.standard.set(idleDimDelay, forKey: SettingKey.idleDimDelay)
        UserDefaults.standard.set(flipHorizontal, forKey: SettingKey.flipHorizontal)
        UserDefaults.standard.set(badgeDisplayMode, forKey: SettingKey.badgeDisplayMode)
        UserDefaults.standard.set(blackCatMode, forKey: SettingKey.blackCatMode)
        UserDefaults.standard.set(blackCatGifPath, forKey: SettingKey.blackCatGifPath)
        UserDefaults.standard.set(koreanImagePath, forKey: SettingKey.koreanImagePath)
        UserDefaults.standard.set(englishImagePath, forKey: SettingKey.englishImagePath)
        UserDefaults.standard.set(excludedApps.sorted().joined(separator: ", "), forKey: SettingKey.excludedApps)
    }

    private func applyAppearanceOptions() {
        window.badgeView.stopGIFAnimation()
        window.badgeView.gifFrames = []
        window.badgeView.badgeImage = nil
        window.badgeView.koreanBadgeImage = nil
        window.badgeView.englishBadgeImage = nil

        if blackCatMode {
            log.info("applyAppearanceOptions: blackCatMode, gifPath='\(self.blackCatGifPath)'")
            if !blackCatGifPath.isEmpty {
                window.badgeView.loadGIF(from: URL(fileURLWithPath: blackCatGifPath))
            }
            // 로딩 실패했거나 경로 없으면 내장 GIF 사용
            if window.badgeView.gifFrames.isEmpty {
                log.info("applyAppearanceOptions: using embedded GIF")
                if let data = Data(base64Encoded: embeddedBlackCatGif) {
                    window.badgeView.loadGIF(from: data)
                }
            }
            window.applyBadgeSize(badgeSize, imageMode: true)
        } else if badgeDisplayMode == "images" {
            if !koreanImagePath.isEmpty {
                let kPath = koreanImagePath
                if kPath.lowercased().hasSuffix(".gif") {
                    window.badgeView.loadGIF(from: URL(fileURLWithPath: kPath))
                } else {
                    window.badgeView.koreanBadgeImage = NSImage(contentsOfFile: kPath)
                }
            }
            if !englishImagePath.isEmpty {
                window.badgeView.englishBadgeImage = NSImage(contentsOfFile: englishImagePath)
            }
            let hasAny = !koreanImagePath.isEmpty || !englishImagePath.isEmpty
            window.applyBadgeSize(badgeSize, imageMode: hasAny)
        } else {
            window.applyBadgeSize(badgeSize, imageMode: false)
        }

        window.badgeView.flipHorizontal = flipHorizontal
        window.badgeView.koreanBackgroundColor = koreanBackgroundColor
        window.badgeView.koreanTextColor = koreanTextColor
        window.badgeView.englishBackgroundColor = englishBackgroundColor
        window.badgeView.englishTextColor = englishTextColor
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
            DispatchQueue.main.async { self?.fastMouseUpdate() }
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.fastMouseUpdate()
            return event
        }
        // preferCaret 모드 딤 기준: 타이핑 여부 감지
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] _ in
            DispatchQueue.main.async { self?.markTypingActive() }
        }
    }

    private func askForAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        log.info("AX trusted on launch: \(trusted)")
        if !trusted {
            log.warning("AX not granted — caretPoint() will return nil. Go to System Settings > Privacy > Accessibility and add Caticator.")
        }
    }

    fileprivate func runAXDiagnostic() -> String {
        var lines: [String] = []

        let trusted = AXIsProcessTrusted()
        lines.append("AX trusted: \(trusted ? "✅ YES" : "❌ NO")")

        guard trusted else {
            lines.append("")
            lines.append("⚠️  접근성 권한이 없습니다.")
            lines.append("아래 버튼으로 권한을 요청하거나")
            lines.append("System Settings > Privacy > Accessibility")
            lines.append("에서 Caticator를 직접 추가하세요.")
            return lines.joined(separator: "\n")
        }

        guard let app = NSWorkspace.shared.frontmostApplication else {
            lines.append("Frontmost app: none"); return lines.joined(separator: "\n")
        }
        lines.append("Frontmost: \(app.localizedName ?? "?") (pid \(app.processIdentifier))")

        // 시스템 전체 포커스
        let sysWide = AXUIElementCreateSystemWide()
        var sysRef: CFTypeRef?
        let r0 = AXUIElementCopyAttributeValue(sysWide, kAXFocusedUIElementAttribute as CFString, &sysRef)
        lines.append("SystemWide focused: \(r0 == .success ? "✅" : "❌ err=\(r0.rawValue)")")

        let appEl = AXUIElementCreateApplication(app.processIdentifier)
        var appRef: CFTypeRef?
        let r1 = AXUIElementCopyAttributeValue(appEl, kAXFocusedUIElementAttribute as CFString, &appRef)
        lines.append("App focused element: \(r1 == .success ? "✅" : "❌ err=\(r1.rawValue)")")

        guard r1 == .success, let el = appRef as! AXUIElement? else {
            lines.append("→ 텍스트 필드에 커서를 놓은 뒤 다시 진단하세요")
            return lines.joined(separator: "\n")
        }

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXRoleAttribute as CFString, &roleRef)
        lines.append("Role: \(roleRef as? String ?? "nil")")

        var rangeRef: CFTypeRef?
        let r2 = AXUIElementCopyAttributeValue(el, kAXSelectedTextRangeAttribute as CFString, &rangeRef)
        lines.append("SelectedTextRange: \(r2 == .success ? "✅" : "❌ err=\(r2.rawValue)")")

        if r2 == .success, let rv = rangeRef as! AXValue? {
            var range = CFRange()
            AXValueGetValue(rv, .cfRange, &range)
            lines.append("Range: loc=\(range.location) len=\(range.length)")

            let testLoc = range.location > 0 ? range.location - 1 : 0
            var testRange = CFRange(location: testLoc, length: 1)
            if let axRange = AXValueCreate(.cfRange, &testRange) {
                var boundsRef: CFTypeRef?
                let r3 = AXUIElementCopyParameterizedAttributeValue(
                    el, kAXBoundsForRangeParameterizedAttribute as CFString, axRange, &boundsRef)
                lines.append("BoundsForRange: \(r3 == .success ? "✅" : "❌ err=\(r3.rawValue)")")
                if r3 == .success, let bv = boundsRef as! AXValue? {
                    var rect = CGRect.zero
                    AXValueGetValue(bv, .cgRect, &rect)
                    let h = NSScreen.screens.first?.frame.height ?? 900
                    lines.append("AX rect: (\(Int(rect.midX)), \(Int(rect.midY)))")
                    lines.append("✅ AppKit 변환: (\(Int(rect.midX)), \(Int(h - rect.midY)))")
                }
            }
        } else {
            lines.append("→ 이 앱/요소는 SelectedTextRange를 지원 안 함")
            lines.append("   (브라우저 일부, 게임 등은 지원 안 할 수 있음)")
        }

        return lines.joined(separator: "\n")
    }

    fileprivate func promptAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        log.info("promptAccessibilityPermission: trusted=\(trusted)")
    }

    @objc private func tick() {
        refreshInputSourceIfNeeded(force: false)
        updateIdleOpacity()

        if blackCatMode && !cachedIsKorean {
            window.orderOut(nil)
            return
        }

        // 제외 앱이면 즉시 숨김 (grace period, keepVisible 무시)
        if let app = NSWorkspace.shared.frontmostApplication {
            let bid = (app.bundleIdentifier ?? "").lowercased()
            let name = (app.localizedName ?? "").lowercased()
            if excludedApps.contains(where: { bid == $0.lowercased() || name == $0.lowercased() }) {
                lastCaretPoint = nil
                caretLostSince = nil
                window.orderOut(nil)
                return
            }
        }

        // preferCaret 모드: 캐럿 감지 시 hideAt와 무관하게 항상 표시
        if preferCaret {
            if let p = throttledCaretPoint() {
                moveBadge(near: p)
                if !window.isVisible { window.orderFrontRegardless() }
                return
            } else if !keepVisible {
                window.orderOut(nil)
                return
            }
            // keepVisible ON → 아래 hideAt 체크 + 마우스 추적으로 계속
        }

        guard keepVisible || Date() < hideAt else {
            window.orderOut(nil)
            return
        }

        moveBadge(near: mousePoint())
        if !window.isVisible { window.orderFrontRegardless() }
    }

    @objc private func inputSourceChanged() {
        hideAt = Date().addingTimeInterval(2.0)
        lastCaretCheck = Date.distantPast
        caretLostSince = nil
        // 전환 시점을 활성 기준으로 초기화 — 즉시 dim 방지
        let now = Date()
        lastTypingActivity = now
        lastMouseActivity = now
        isDimmed = false
        window.alphaValue = activeBadgeOpacity
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
        guard !preferCaret else { return }
        guard !(blackCatMode && !cachedIsKorean) else { return }
        guard keepVisible || Date() < hideAt else { return }
        moveBadge(near: mousePoint())
        if !window.isVisible {
            window.orderFrontRegardless()
        }
    }

    private func markMouseActive() {
        lastMouseActivity = Date()
        // preferCaret 모드: 마우스로 undim 안 함 (타이핑만 활성화 기준)
        if preferCaret { return }
        guard isDimmed || window.alphaValue < activeBadgeOpacity else { return }
        isDimmed = false
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            self.window.animator().alphaValue = activeBadgeOpacity
        }
    }

    private func markTypingActive() {
        lastTypingActivity = Date()
        guard preferCaret else { return }
        guard isDimmed || window.alphaValue < activeBadgeOpacity else { return }
        isDimmed = false
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            self.window.animator().alphaValue = activeBadgeOpacity
        }
    }

    private func updateIdleOpacity() {
        guard window.isVisible else { return }
        // preferCaret 모드: 타이핑 멈춘 뒤 지정 시간 → dim
        // 일반 모드:       마우스 멈춘 뒤 지정 시간 → dim
        let elapsed = preferCaret
            ? Date().timeIntervalSince(lastTypingActivity)
            : Date().timeIntervalSince(lastMouseActivity)
        let shouldDim = elapsed >= idleDimDelay
        guard shouldDim != isDimmed else { return }
        isDimmed = shouldDim
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            self.window.animator().alphaValue = shouldDim ? idleBadgeOpacity : activeBadgeOpacity
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

    fileprivate func setIdleDimDelay(_ value: TimeInterval) {
        idleDimDelay = max(0.1, min(60, value))
        saveOptions()
    }

    fileprivate func setFlipHorizontal(_ value: Bool) {
        flipHorizontal = value
        saveOptions()
        window.badgeView.flipHorizontal = value
        window.badgeView.needsDisplay = true
    }

    fileprivate func setBadgeDisplayMode(_ mode: String) {
        badgeDisplayMode = mode
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func setBlackCatMode(_ value: Bool) {
        blackCatMode = value
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func setBlackCatGifPath(_ path: String) {
        blackCatGifPath = path
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func setKoreanImagePath(_ path: String) {
        koreanImagePath = path
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func setEnglishImagePath(_ path: String) {
        englishImagePath = path
        saveOptions()
        applyAppearanceOptions()
    }

    fileprivate func resetOptions() {
        keepVisible = false
        preferCaret = true
        badgeSize = defaultBadgeSize
        idleDimDelay = 2.0
        flipHorizontal = false
        koreanLabel = "한"
        englishLabel = "A"
        customImagePath = ""
        badgeDisplayMode = "labels"
        blackCatMode = false
        blackCatGifPath = ""
        koreanImagePath = ""
        englishImagePath = ""
        koreanBackgroundColor = NSColor(hex: defaultKoreanBackground)!
        koreanTextColor = NSColor(hex: defaultKoreanText)!
        englishBackgroundColor = NSColor(hex: defaultEnglishBackground)!
        englishTextColor = NSColor(hex: defaultEnglishText)!
        anchor = .bottomLeft
        offsetX = -4
        offsetY = -10
        excludedApps = ["com.apple.finder"]
        saveOptions()
        applyAppearanceOptions()
    }

    @objc fileprivate func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        if let mouseMonitor { NSEvent.removeMonitor(mouseMonitor) }
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
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

    private func isOnScreen(_ p: CGPoint) -> Bool {
        NSScreen.screens.contains(where: { $0.frame.contains(p) })
    }

    // AX 쿼리를 최대 0.3초에 1번으로 제한 — 웹브라우저 메인스레드 차단 방지
    private func throttledCaretPoint() -> CGPoint? {
        let now = Date()
        guard now.timeIntervalSince(lastCaretCheck) >= 0.3 else { return lastCaretPoint }
        lastCaretCheck = now

        if let p = caretPoint(), isOnScreen(p) {
            // Velocity filter: 직전 위치 대비 Y가 200px 이상 점프 → AX 오류 좌표
            if let prev = lastCaretPoint, abs(p.y - prev.y) > 200 {
                if caretLostSince == nil { caretLostSince = now }
            } else {
                // 정상 위치 — 업데이트
                caretLostSince = nil
                if let prev = lastCaretPoint,
                   (abs(p.x - prev.x) > 1 || abs(p.y - prev.y) > 1) {
                    lastTypingActivity = now
                }
                lastCaretPoint = p
                if lastBadgeSource != "caret" { lastBadgeSource = "caret" }
                return p
            }
        } else {
            // AX nil
            if caretLostSince == nil { caretLostSince = now }
        }

        // 유예 기간(1.5s): 마지막 유효 위치 유지
        let grace: TimeInterval = 1.5
        if let lost = caretLostSince, now.timeIntervalSince(lost) >= grace {
            if lastBadgeSource != "mouse" { lastBadgeSource = "mouse" }
            lastCaretPoint = nil
            caretLostSince = nil
            return nil
        }
        return lastCaretPoint
    }

    private var caretDebugEnabled = false
    private var caretDebugLines: [String] = []

    private func dbg(_ s: String) {
        guard caretDebugEnabled else { return }
        caretDebugLines.append(s)
    }

    fileprivate func startCaretDebug() {
        caretDebugEnabled = true
        caretDebugLines = ["=== Caret Debug (5초) ===", "Time: \(Date())"]
        lastCaretCheck = Date.distantPast
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.caretDebugEnabled = false
            let text = self.caretDebugLines.joined(separator: "\n")
            let path = NSHomeDirectory() + "/Desktop/hana_caret_debug.txt"
            try? text.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    private func caretPoint() -> CGPoint? {
        let trusted = AXIsProcessTrusted()
        dbg("AX trusted: \(trusted)")
        guard trusted else { return nil }

        let myPID = ProcessInfo.processInfo.processIdentifier
        let appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"
        dbg("Frontmost: \(appName)")

        // 시스템 전체 포커스
        let systemWide = AXUIElementCreateSystemWide()
        var sysRef: CFTypeRef?
        let r0 = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &sysRef)
        dbg("SystemWide focused: result=\(r0.rawValue)")

        if r0 == .success, let el = sysRef {
            let focused = el as! AXUIElement
            // 자기 앱(Settings 창) 요소는 무시
            var elPID: pid_t = 0
            guard AXUIElementGetPid(focused, &elPID) != .success || elPID != myPID else {
                dbg("  ⏭ 자기 앱 요소 → skip")
                return nil
            }
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(focused, kAXRoleAttribute as CFString, &roleRef)
            dbg("  Role: \(roleRef as? String ?? "nil")")
            if let point = caretPoint(in: focused) {
                lastCaretPoint = point
                dbg("  ✅ Caret: AppKit(\(Int(point.x)), \(Int(point.y)))")
                return point
            }
            dbg("  ❌ caretPoint(in:) returned nil")
        }

        // 앱 레벨 폴백
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        // 자기 앱이 frontmost면 (Settings 창 열린 경우) 추적 안 함
        guard app.processIdentifier != myPID else {
            dbg("  ⏭ frontmost = 자기 앱 → skip")
            return nil
        }
        let appEl = AXUIElementCreateApplication(app.processIdentifier)
        var appRef: CFTypeRef?
        let r1 = AXUIElementCopyAttributeValue(appEl, kAXFocusedUIElementAttribute as CFString, &appRef)
        dbg("App focused: result=\(r1.rawValue)")
        guard r1 == .success, let el = appRef else {
            dbg("  ❌ no focused element")
            return nil
        }
        let focused = el as! AXUIElement
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(focused, kAXRoleAttribute as CFString, &roleRef)
        dbg("  Role: \(roleRef as? String ?? "nil")")

        if let point = caretPoint(in: focused) {
            lastCaretPoint = point
            dbg("  ✅ Caret (app fallback): AppKit(\(Int(point.x)), \(Int(point.y)))")
            return point
        }
        dbg("  ❌ app caretPoint(in:) returned nil")
        return nil
    }

    // AX API는 top-left origin (y↓), AppKit은 bottom-left origin (y↑) — Y축 반전 필요
    private func axToAppKit(_ axPoint: CGPoint) -> CGPoint {
        let h = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 900
        return CGPoint(x: axPoint.x, y: h - axPoint.y)
    }

    private func caretPoint(in focusedElement: AXUIElement) -> CGPoint? {
        let textEl = bestTextElement(from: focusedElement)
        dbg("    bestTextElement: \(textEl == nil ? "nil" : "found")")
        guard let textElement = textEl else { return nil }

        // 편집 불가능한 요소면 무시 (정적 텍스트, 레이블 등)
        guard isTextLike(textElement) else {
            dbg("    ❌ not editable — skip")
            return nil
        }

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(textElement, kAXRoleAttribute as CFString, &roleRef)
        dbg("    textEl role: \(roleRef as? String ?? "nil")")

        if let rect = selectedTextRect(textElement) {
            let pt = axToAppKit(CGPoint(x: rect.midX, y: rect.midY))
            dbg("    ✅ selectionRect → AppKit(\(Int(pt.x)),\(Int(pt.y)))")
            return pt
        }
        dbg("    selectedTextRect=nil → elementRect 시도")
        if let rect = elementRect(textElement) {
            let pt = axToAppKit(CGPoint(x: rect.minX, y: rect.minY))
            dbg("    ⚠️ elementRect fallback → AppKit(\(Int(pt.x)),\(Int(pt.y)))")
            return pt
        }
        dbg("    ❌ elementRect=nil")
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

        // AXStaticText 등 읽기전용 표시 요소 제외
        let readOnlyRoles = ["AXStaticText", "AXHeading", "AXGroup", "AXList",
                             "AXTable", "AXOutline", "AXButton", "AXImage"]
        if readOnlyRoles.contains(role) { return false }

        // AXEditable 속성이 가장 신뢰할 수 있는 기준
        var editableValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, "AXEditable" as CFString, &editableValue) == .success,
           let editable = editableValue as? Bool {
            return editable
        }

        // AXEditable 없으면 역할로 판단 (명확한 입력 역할만)
        let editableRoles = ["AXTextField", "AXTextArea", "AXSearchField",
                             "AXComboBox", "AXSecureTextField"]
        return editableRoles.contains(role)
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
        // visibleFrame 대신 frame 사용 — 메뉴바·Dock 영역에도 배지 표시 허용
        let screenFrame = NSScreen.screens.first(where: { $0.frame.contains(point) })?.frame
            ?? NSScreen.main?.frame
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
        // 화면 완전 밖으로 나가는 것만 방지 (메뉴바·Dock 영역 이동 허용)
        origin.x = max(screenFrame.minX - size.width / 2, min(origin.x, screenFrame.maxX - size.width / 2))
        origin.y = max(screenFrame.minY - size.height / 2, min(origin.y, screenFrame.maxY - size.height / 2))
        window.setFrameOrigin(origin)
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
