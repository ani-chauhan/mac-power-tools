// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Carbon.HIToolbox
import ScreenCaptureKit

/// The pixel ruler: hover anywhere to see live pixel distances from the
/// cursor to the nearest detected edge in each direction, styled after
/// PixelSnap. Purely on demand — nothing runs until the shortcut is pressed,
/// and everything (the overlay panel, the ScreenCaptureKit stream, the event
/// monitors) tears down the moment it's dismissed.
///
/// Tracks one screen at a time — the one the cursor is on. Moving the
/// cursor to a different display tears the session down and starts a fresh
/// one there, rather than keeping a stream running per display; a cursor is
/// only ever on one screen at once, so that keeps the CPU/battery cost to
/// exactly one active stream regardless of how many displays are attached.
final class PixelRulerService: NSObject, ObservableObject {
    static let shared = PixelRulerService()

    @Published private(set) var shortcutRegistrationFailed = false
    @Published private(set) var isActive = false
    @Published private(set) var tolerance: PixelRulerTolerance
    @Published private(set) var unit: PixelRulerUnit

    private let hotkey = QuickToolHotkey(id: 21)

    private var panel: PixelRulerPanel?
    private var overlayView: PixelRulerOverlayView?
    private var stream: SCStream?
    private let streamQueue = DispatchQueue(label: "com.vorssaint.pixelruler.capture")

    private let bufferLock = NSLock()
    private var latestBuffer: CVPixelBuffer?

    private var screenFrame: CGRect = .zero
    private var scale: CGFloat = 1
    private var displayID: CGDirectDisplayID = 0
    private var streamGeneration = 0

    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var localFlagsMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var isShiftHeld = false
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localDragMonitor: Any?
    private var dragOrigin: CGPoint?
    private var pollTimer: Timer?
    private var screenChangeObserver: Any?

    private override init() {
        tolerance = PixelRulerTolerance.sanitized(
            UserDefaults.standard.string(forKey: DefaultsKey.pixelRulerTolerance))
        unit = PixelRulerUnit.sanitized(
            UserDefaults.standard.string(forKey: DefaultsKey.pixelRulerUnit))
        super.init()
        hotkey.onPress = { [weak self] in self?.toggle() }
    }

    func syncWithPreferences() {
        let available = AppFeature.pixelRuler.isAvailable
        let enabled = available
            && UserDefaults.standard.bool(forKey: DefaultsKey.pixelRulerShortcutEnabled)
        let shortcut = GlobalShortcut.saved(for: DefaultsKey.pixelRulerShortcut,
                                            fallback: .pixelRulerDefault)
        shortcutRegistrationFailed = !hotkey.sync(enabled: enabled, shortcut: shortcut)
        if !available { stop() }
    }

    func suspend() {
        hotkey.unregister()
        stop()
    }

    /// Every window this session put on screen, so a screenshot or recording
    /// taken while measuring never captures the ruler's own chrome.
    var protectedWindowIDs: Set<CGWindowID> {
        guard let panel, panel.isVisible, panel.windowNumber > 0 else { return [] }
        return [CGWindowID(panel.windowNumber)]
    }

    func toggle() {
        isActive ? stop() : start()
    }

    // MARK: - Session

    private func start() {
        guard panel == nil,
              let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
                ?? NSScreen.main
        else { return }
        beginSession(on: screen)
        isActive = true
        installGlobalMonitors()
    }

    private func beginSession(on screen: NSScreen) {
        screenFrame = screen.frame
        scale = screen.backingScaleFactor
        displayID = screen.displayID
        streamGeneration += 1
        let generation = streamGeneration

        let view = PixelRulerOverlayView(frame: CGRect(origin: .zero, size: screen.frame.size))
        view.showsFullScreenCrosshair = isShiftHeld
        let panel = PixelRulerPanel(contentRect: screen.frame,
                                    styleMask: [.borderless, .nonactivatingPanel],
                                    backing: .buffered,
                                    defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // One below the status bar: above ordinary windows, below the menu
        // bar, matching the recorder's own click-through region guide.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue - 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        // Takes mouse input itself (not click-through): the area tool needs
        // real mouseDown/dragged/up to draw rectangles, and as a side effect
        // this is what keeps every keystroke from leaking to whatever app
        // used to be in front — clicking through to another app was the only
        // way this panel could lose key-window status and start letting
        // typed keys go elsewhere.
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.contentView = view
        panel.orderFrontRegardless()
        panel.makeKey()

        self.panel?.orderOut(nil)
        self.panel = panel
        overlayView = view

        installSessionKeyMonitor()
        installDragMonitor()
        Task { await startStream(generation: generation) }
    }

    private func stop() {
        guard isActive || panel != nil else { return }
        isActive = false
        streamGeneration += 1
        let stream = self.stream
        self.stream = nil
        Task { try? await stream?.stopCapture() }

        removeSessionKeyMonitor()
        removeDragMonitor()
        removeGlobalMonitors()
        panel?.orderOut(nil)
        panel = nil
        // Drops every pinned rectangle and guide line along with the view:
        // Escape (or toggling off) is a full teardown, and a fresh session
        // starts clean.
        overlayView = nil

        bufferLock.lock()
        latestBuffer = nil
        bufferLock.unlock()
    }

    // MARK: - Stream

    private func startStream(generation: Int) async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true)
            guard generation == streamGeneration,
                  let display = content.displays.first(where: { $0.displayID == displayID })
            else { return }
            // Matched by owning process rather than a specific window number
            // (as ScreenshotCaptureEngine does for the same reason): a single
            // windowID lookup that ever misses leaves the ruler's own
            // crosshair/pill in its own capture, which then feeds back into
            // the next scan and reads as a slowly creeping false edge.
            let ownWindows = content.windows.filter { $0.owningApplication?.processID == getpid() }
            let filter = SCContentFilter(display: display, excludingWindows: ownWindows)

            let configuration = SCStreamConfiguration()
            configuration.width = Int(screenFrame.width * scale)
            configuration.height = Int(screenFrame.height * scale)
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            configuration.colorSpaceName = CGColorSpace.sRGB
            configuration.showsCursor = false
            configuration.queueDepth = 3

            let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: streamQueue)
            try await stream.startCapture()
            guard generation == streamGeneration else {
                try? await stream.stopCapture()
                return
            }
            self.stream = stream
        } catch {
            guard generation == streamGeneration else { return }
            QuickToolHUD.show(icon: "exclamationmark.triangle",
                              message: FeatureStrings.pixelRuler(L10n.shared.language).streamFailedHUD)
            stop()
        }
    }

    // MARK: - Cursor tracking (fires while ANY screen has the pointer, so a
    // move to another display can restart the session there)

    private func installGlobalMonitors() {
        let moves: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: moves) { [weak self] event in
            self?.rescan()
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: moves) { [weak self] _ in
            self?.rescan()
        }
        // Global, not just local: clicking into another app while measuring
        // (expected, since the overlay is click-through) can hand key-window
        // status to that app, and Shift still needs to register afterward.
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.setShiftHeld(event.modifierFlags.contains(.shift))
            return event
        }
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.setShiftHeld(event.modifierFlags.contains(.shift))
        }
        // A non-activating panel that owns its own mouse events (needed for
        // the area tool's drag) is not a reliable source of `.mouseMoved` —
        // AppKit can go quiet on it in ways a plain click-through overlay
        // never hit. Polling the cursor directly means the crosshair can't
        // silently go stale no matter what the event monitors above do.
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.rescan()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            // Simplest safe response to a display added/removed/resized mid
            // session: end it rather than risk measuring against a stale
            // frame or a display that no longer exists.
            self?.stop()
        }
    }

    private func removeGlobalMonitors() {
        for monitor in [localMouseMonitor, globalMouseMonitor, localFlagsMonitor, globalFlagsMonitor] {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
        localMouseMonitor = nil
        globalMouseMonitor = nil
        localFlagsMonitor = nil
        globalFlagsMonitor = nil
        isShiftHeld = false
        pollTimer?.invalidate()
        pollTimer = nil
        if let screenChangeObserver { NotificationCenter.default.removeObserver(screenChangeObserver) }
        screenChangeObserver = nil
    }

    private func setShiftHeld(_ held: Bool) {
        guard held != isShiftHeld else { return }
        isShiftHeld = held
        overlayView?.showsFullScreenCrosshair = held
        overlayView?.needsDisplay = true
    }

    private func installSessionKeyMonitor() {
        // Matches keyUp too and swallows it unconditionally, so nothing typed
        // while this panel is key can leak a character into whatever the
        // key-down half of a keystroke would otherwise have reached.
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self, event.window is PixelRulerPanel else { return event }
            if event.type == .keyDown { self.handleKey(event) }
            return nil
        }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == UInt16(kVK_Escape) else { return }
            self?.stop()
        }
    }

    private func removeSessionKeyMonitor() {
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
        if let globalKeyMonitor { NSEvent.removeMonitor(globalKeyMonitor) }
        localKeyMonitor = nil
        globalKeyMonitor = nil
    }

    private func handleKey(_ event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_Escape:
            stop()
        case kVK_ANSI_Equal, kVK_ANSI_KeypadPlus:
            setTolerance(tolerance.stepped(by: -1)) // more sensitive
        case kVK_ANSI_Minus, kVK_ANSI_KeypadMinus:
            setTolerance(tolerance.stepped(by: 1)) // less sensitive
        case kVK_Tab:
            setTolerance(tolerance.cycled())
        case kVK_ANSI_U:
            setUnit(unit.toggled())
        case kVK_ANSI_H:
            addGuideLine(horizontal: true, fullScreen: event.modifierFlags.contains(.shift))
        case kVK_ANSI_V:
            addGuideLine(horizontal: false, fullScreen: event.modifierFlags.contains(.shift))
        default:
            break
        }
    }

    /// Pins a guide line at the cursor's current row/column. Bare H/V match
    /// the segment already shown by the live crosshair (edge to edge);
    /// Shift-H/Shift-V span the whole screen instead.
    private func addGuideLine(horizontal: Bool, fullScreen: Bool) {
        guard let overlayView, let reading = overlayView.reading else { return }
        let point = overlayView.cursorPoint
        let line: PixelRulerGuideLine
        if horizontal {
            let start = fullScreen ? 0 : point.x - CGFloat(reading.left) / scale
            let end = fullScreen ? overlayView.bounds.width : point.x + CGFloat(reading.right) / scale
            line = PixelRulerGuideLine(orientation: .horizontal, position: point.y, start: start, end: end)
        } else {
            let start = fullScreen ? 0 : point.y - CGFloat(reading.up) / scale
            let end = fullScreen ? overlayView.bounds.height : point.y + CGFloat(reading.down) / scale
            line = PixelRulerGuideLine(orientation: .vertical, position: point.x, start: start, end: end)
        }
        overlayView.pinnedLines.append(line)
        overlayView.needsDisplay = true
    }

    // MARK: - Area tool (drag to measure a rectangle)

    private func installDragMonitor() {
        localDragMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            guard let self, event.window is PixelRulerPanel else { return event }
            self.handleDrag(event)
            return nil
        }
    }

    private func removeDragMonitor() {
        if let localDragMonitor { NSEvent.removeMonitor(localDragMonitor) }
        localDragMonitor = nil
        dragOrigin = nil
    }

    /// Shift constrains to a square; Option anchors the drag's start point as
    /// the center instead of a corner. Every completed rectangle is kept —
    /// there's no discard-on-release — until Escape ends the whole session.
    private func handleDrag(_ event: NSEvent) {
        guard let overlayView else { return }
        let point = overlayView.convert(event.locationInWindow, from: nil)
        switch event.type {
        case .leftMouseDown:
            dragOrigin = point
            overlayView.dragRect = CGRect(origin: point, size: .zero)
        case .leftMouseDragged:
            guard let dragOrigin else { return }
            overlayView.dragRect = PixelRulerArea.dragRect(
                from: dragOrigin, to: point,
                squareConstrained: event.modifierFlags.contains(.shift),
                centeredOnOrigin: event.modifierFlags.contains(.option))
        case .leftMouseUp:
            if let rect = overlayView.dragRect, rect.width > 2, rect.height > 2 {
                overlayView.pinnedRects.append(rect)
            }
            dragOrigin = nil
            overlayView.dragRect = nil
        default:
            break
        }
        overlayView.needsDisplay = true
    }

    private func setTolerance(_ value: PixelRulerTolerance) {
        guard value != tolerance else { return }
        tolerance = value
        UserDefaults.standard.set(value.rawValue, forKey: DefaultsKey.pixelRulerTolerance)
        rescan()
    }

    private func setUnit(_ value: PixelRulerUnit) {
        guard value != unit else { return }
        unit = value
        UserDefaults.standard.set(value.rawValue, forKey: DefaultsKey.pixelRulerUnit)
        rescan()
    }

    // MARK: - Scan

    private func rescan() {
        let cursor = NSEvent.mouseLocation
        guard isActive else { return }
        guard screenFrame.contains(cursor) else {
            // Moved off the current screen: hand the session to whichever
            // screen the cursor is on now, if any.
            if let screen = NSScreen.screens.first(where: { $0.frame.contains(cursor) }) {
                beginSession(on: screen)
            }
            return
        }

        let devicePoint = CGPoint(x: (cursor.x - screenFrame.minX) * scale,
                                  y: (screenFrame.maxY - cursor.y) * scale)
        bufferLock.lock()
        let buffer = latestBuffer
        bufferLock.unlock()
        guard let buffer else { return }

        guard let reading = Self.scan(buffer: buffer,
                                      x: Int(devicePoint.x),
                                      y: Int(devicePoint.y),
                                      tolerance: tolerance.threshold)
        else { return }

        overlayView?.reading = reading
        overlayView?.unit = unit
        overlayView?.scale = scale
        overlayView?.cursorPoint = CGPoint(x: cursor.x - screenFrame.minX,
                                          y: screenFrame.maxY - cursor.y)
        overlayView?.needsDisplay = true
    }

    private static func scan(buffer: CVPixelBuffer,
                             x: Int,
                             y: Int,
                             tolerance: Int) -> PixelRulerScan.Reading? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        guard x >= 0, x < width, y >= 0, y < height else { return nil }

        func luminance(_ px: Int, _ py: Int) -> Int {
            let offset = py * stride + px * 4 // BGRA
            let pointer = base.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
            return PixelRulerScan.luminance(b: pointer[0], g: pointer[1], r: pointer[2])
        }

        return PixelRulerScan.scan(x: x, y: y, width: width, height: height,
                                   tolerance: tolerance, luminance: luminance)
    }
}

extension PixelRulerService: SCStreamOutput {
    func stream(_ stream: SCStream,
               didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
               of type: SCStreamOutputType) {
        guard type == .screen, CMSampleBufferIsValid(sampleBuffer),
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        bufferLock.lock()
        latestBuffer = pixelBuffer
        bufferLock.unlock()
    }
}

/// `canBecomeKey` is what lets a click-through panel still own Esc and the
/// tolerance/unit keys: see the comment on `ignoresMouseEvents` in
/// `beginSession(on:)`.
private final class PixelRulerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// A pinned guide line (from the H/V keys), in view-space points. `position`
/// is the fixed row (horizontal) or column (vertical); `start`/`end` are the
/// perpendicular extent.
private struct PixelRulerGuideLine {
    enum Orientation { case horizontal, vertical }
    let orientation: Orientation
    let position: CGFloat
    let start: CGFloat
    let end: CGFloat
}

private final class PixelRulerOverlayView: NSView {
    var reading: PixelRulerScan.Reading?
    var unit: PixelRulerUnit = .pixel
    var scale: CGFloat = 1
    var cursorPoint: CGPoint = .zero
    /// True while Shift is held: draws guide lines across the whole screen
    /// for alignment, on top of (or instead of) the measured segment.
    var showsFullScreenCrosshair = false
    /// The in-progress area-tool drag, in view points, or nil when not
    /// dragging. Takes over the red "live" styling from the crosshair.
    var dragRect: CGRect?
    /// Every completed area-tool rectangle. These stay until the whole
    /// session ends (Escape) — there's no discard-on-release.
    var pinnedRects: [CGRect] = []
    /// Every guide line pinned with H/V. Same lifetime as `pinnedRects`.
    var pinnedLines: [PixelRulerGuideLine] = []

    override var isFlipped: Bool { true }

    private let labelAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: NSColor.white,
    ]

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        if showsFullScreenCrosshair {
            context.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.6).cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 0, y: cursorPoint.y))
            context.addLine(to: CGPoint(x: bounds.width, y: cursorPoint.y))
            context.strokePath()
            context.move(to: CGPoint(x: cursorPoint.x, y: 0))
            context.addLine(to: CGPoint(x: cursorPoint.x, y: bounds.height))
            context.strokePath()
        }

        drawGuideLines(context)
        for rect in pinnedRects {
            drawAreaRect(rect, color: .systemBlue, context: context)
        }

        if let dragRect {
            drawAreaRect(dragRect, color: .systemRed, context: context)
            return
        }
        guard let reading else { return }
        drawCrosshair(reading, context: context)
    }

    /// Half-length of the tick mark capping each ray where it meets its
    /// detected edge — perpendicular to the ray, like a ruler's end mark.
    private static let endCapHalfLength: CGFloat = 4

    private func drawCrosshair(_ reading: PixelRulerScan.Reading, context: CGContext) {
        let color = NSColor.systemRed.cgColor
        // `reading` is in DEVICE pixels (the buffer is Retina-scale); the view
        // draws in points, so every offset must come back down by `scale`
        // before it's used as a view-space coordinate.
        let left = CGFloat(reading.left) / scale
        let right = CGFloat(reading.right) / scale
        let up = CGFloat(reading.up) / scale
        let down = CGFloat(reading.down) / scale

        context.setStrokeColor(color)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: cursorPoint.x - left, y: cursorPoint.y))
        context.addLine(to: CGPoint(x: cursorPoint.x + right, y: cursorPoint.y))
        context.strokePath()
        context.move(to: CGPoint(x: cursorPoint.x, y: cursorPoint.y - up))
        context.addLine(to: CGPoint(x: cursorPoint.x, y: cursorPoint.y + down))
        context.strokePath()

        drawEndCap(at: CGPoint(x: cursorPoint.x - left, y: cursorPoint.y), vertical: true, context: context)
        drawEndCap(at: CGPoint(x: cursorPoint.x + right, y: cursorPoint.y), vertical: true, context: context)
        drawEndCap(at: CGPoint(x: cursorPoint.x, y: cursorPoint.y - up), vertical: false, context: context)
        drawEndCap(at: CGPoint(x: cursorPoint.x, y: cursorPoint.y + down), vertical: false, context: context)

        context.setFillColor(color)
        context.fillEllipse(in: CGRect(x: cursorPoint.x - 2, y: cursorPoint.y - 2, width: 4, height: 4))

        // A single size readout instead of four per-end labels: the total
        // span of each ray, in a pill below-right of where they cross. `at:`
        // is the text's own origin (see drawLabel), offset from the pill's
        // near corner by its own padding, so adding `labelGap` to both axes
        // here is what actually keeps the pill's edge equidistant on both
        // sides — the padding alone is asymmetric (wider than it is tall).
        let widthLabel = unit.label(devicePixels: reading.left + reading.right, scale: scale)
        let heightLabel = unit.label(devicePixels: reading.up + reading.down, scale: scale)
        drawLabel("\(widthLabel) × \(heightLabel)",
                 at: CGPoint(x: cursorPoint.x + Self.labelGap + Self.labelPadding.width,
                            y: cursorPoint.y + Self.labelGap + Self.labelPadding.height))
    }

    /// A short tick mark perpendicular to a ray, drawn at one of its ends.
    private func drawEndCap(at point: CGPoint, vertical: Bool, context: CGContext) {
        context.setStrokeColor(NSColor.systemRed.cgColor)
        context.setLineWidth(1)
        if vertical {
            context.move(to: CGPoint(x: point.x, y: point.y - Self.endCapHalfLength))
            context.addLine(to: CGPoint(x: point.x, y: point.y + Self.endCapHalfLength))
        } else {
            context.move(to: CGPoint(x: point.x - Self.endCapHalfLength, y: point.y))
            context.addLine(to: CGPoint(x: point.x + Self.endCapHalfLength, y: point.y))
        }
        context.strokePath()
    }

    private func drawGuideLines(_ context: CGContext) {
        for line in pinnedLines {
            context.setStrokeColor(NSColor.systemBlue.cgColor)
            context.setLineWidth(1)
            let start: CGPoint
            let end: CGPoint
            let labelCenter: CGPoint
            switch line.orientation {
            case .horizontal:
                start = CGPoint(x: line.start, y: line.position)
                end = CGPoint(x: line.end, y: line.position)
                labelCenter = CGPoint(x: (line.start + line.end) / 2, y: line.position)
            case .vertical:
                start = CGPoint(x: line.position, y: line.start)
                end = CGPoint(x: line.position, y: line.end)
                labelCenter = CGPoint(x: line.position, y: (line.start + line.end) / 2)
            }
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()

            let lengthDevicePixels = Int((abs(line.end - line.start) * scale).rounded())
            drawCenteredLabel(unit.label(devicePixels: lengthDevicePixels, scale: scale), at: labelCenter)
        }
    }

    /// Outline plus the size in the middle and the reduced aspect ratio at
    /// the bottom, shared by both the live drag and every pinned rectangle.
    private func drawAreaRect(_ rect: CGRect, color: NSColor, context: CGContext) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1)
        context.stroke(rect)

        let deviceWidth = Int((rect.width * scale).rounded())
        let deviceHeight = Int((rect.height * scale).rounded())
        guard deviceWidth > 0, deviceHeight > 0 else { return }
        let sizeText = "\(unit.label(devicePixels: deviceWidth, scale: scale)) × "
            + "\(unit.label(devicePixels: deviceHeight, scale: scale))"
        drawCenteredLabel(sizeText, at: CGPoint(x: rect.midX, y: rect.midY))
        drawCenteredLabel(PixelRulerArea.aspectRatioLabel(width: deviceWidth, height: deviceHeight),
                          at: CGPoint(x: rect.midX, y: rect.maxY + 16))
    }

    /// Gap between the crosshair's crossing point and the near edge of the
    /// size pill, in both directions equally.
    private static let labelGap: CGFloat = 10
    private static let labelPadding = CGSize(width: 7, height: 3)

    /// `point` is the text's own origin, same as `NSString.draw(at:)` — the
    /// pill is measured and filled behind it using the same text size.
    private func drawLabel(_ text: String, at point: CGPoint) {
        guard !text.isEmpty else { return }
        let size = (text as NSString).size(withAttributes: labelAttributes)
        let padding = Self.labelPadding
        let pillRect = CGRect(x: point.x - padding.width, y: point.y - padding.height,
                             width: size.width + padding.width * 2, height: size.height + padding.height * 2)
        let pill = NSBezierPath(roundedRect: pillRect, xRadius: pillRect.height / 2, yRadius: pillRect.height / 2)
        NSColor(white: 0.32, alpha: 1).setFill()
        pill.fill()
        (text as NSString).draw(at: point, withAttributes: labelAttributes)
    }

    private func drawCenteredLabel(_ text: String, at point: CGPoint) {
        guard !text.isEmpty else { return }
        let size = (text as NSString).size(withAttributes: labelAttributes)
        drawLabel(text, at: CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2))
    }
}
