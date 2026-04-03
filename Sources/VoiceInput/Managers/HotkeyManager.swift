import AppKit
import CoreGraphics

/// Manages global Fn key monitoring via CGEvent tap
class HotkeyManager {

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onFnDown: (() -> Void)?
    var onFnUp: (() -> Void)?

    private var isFnDown = false

    init(onFnDown: @escaping () -> Void, onFnUp: @escaping () -> Void) {
        self.onFnDown = onFnDown
        self.onFnUp = onFnUp
    }

    deinit {
        stop()
    }

    // MARK: - Start / Stop

    func start() {
        guard AXIsProcessTrusted() else {
            print("⚠️ Accessibility permission not granted. Please enable it in System Settings → Privacy & Security → Accessibility.")
            promptAccessibilityPermission()
            // Retry after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.start()
            }
            return
        }

        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)

        // Store `self` in a raw pointer for the C callback
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: hotkeyEventCallback,
            userInfo: userInfo
        ) else {
            print("❌ Failed to create CGEvent tap. Ensure Accessibility permission is granted.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        print("✅ Fn key event tap started")
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
    }

    // MARK: - Event Handling

    fileprivate func handleFlagsChanged(_ event: CGEvent) -> CGEvent? {
        let flags = event.flags

        // The Fn key corresponds to NX_DEVICELCTLFLAG on some keyboards
        // and .maskSecondaryFn in CGEventFlags (rawValue 0x800000)
        let fnFlag = CGEventFlags(rawValue: 0x800000) // secondaryFn / NX_SECONDARYFNMASK
        let hasFn = flags.contains(fnFlag)

        // Check no other modifiers are held (pure Fn press only)
        let otherModifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        let hasOtherModifiers = !flags.intersection(otherModifiers).isEmpty

        if hasFn && !isFnDown && !hasOtherModifiers {
            isFnDown = true
            DispatchQueue.main.async { [weak self] in
                self?.onFnDown?()
            }
            return nil // Suppress the event to prevent emoji picker
        } else if !hasFn && isFnDown {
            isFnDown = false
            DispatchQueue.main.async { [weak self] in
                self?.onFnUp?()
            }
            return nil // Suppress the release event too
        }

        return Unmanaged.passRetained(event).autorelease().takeUnretainedValue()
    }

    // MARK: - Accessibility Prompt

    private func promptAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

// MARK: - C Callback

private func hotkeyEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // Handle tap disabled events (system can disable taps under load)
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo = userInfo {
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
            if let tap = manager.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
        return Unmanaged.passRetained(event)
    }

    guard type == .flagsChanged, let userInfo = userInfo else {
        return Unmanaged.passRetained(event)
    }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()

    if let resultEvent = manager.handleFlagsChanged(event) {
        return Unmanaged.passRetained(resultEvent)
    }

    return nil // Event suppressed
}
