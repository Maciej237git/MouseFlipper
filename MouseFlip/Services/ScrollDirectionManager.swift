import Darwin
import Foundation

enum ScrollDirectionError: LocalizedError {
    case readFailed
    case writeFailed
    case verifyFailed(expected: ScrollDirection, actual: ScrollDirection?)

    var errorDescription: String? {
        switch self {
        case .readFailed:
            return "Could not read scrolling preference."
        case .writeFailed:
            return "Could not change scrolling preference."
        case .verifyFailed(let expected, let actual):
            return "Scrolling preference verification failed. Expected \(expected.displayName), got \(actual?.displayName ?? "unknown")."
        }
    }
}

struct ScrollApplyResult {
    let valueBefore: ScrollDirection?
    let requested: ScrollDirection
    let synchronizeSuccess: Bool
    let valueAfter: ScrollDirection?
    let verifyMatch: Bool
    let notificationPosted: Bool
    let privateAPIApplied: Bool
}

/// Sole owner of macOS natural-scrolling preference read/write logic.
final class ScrollDirectionManager {
    // macOS does not expose a documented public high-level API
    // for programmatically changing the global natural scrolling setting.
    // Keep this implementation isolated so it can be replaced if macOS changes.
    private let preferenceKey = "com.apple.swipescrolldirection"
    private let domain = kCFPreferencesAnyApplication

    // Phase 2B: undocumented notification observed by System Settings / input subsystem.
    private let scrollDirectionChangedNotification = Notification.Name("SwipeScrollDirectionDidChangeNotification")

    func currentDirection() -> ScrollDirection? {
        guard let value = CFPreferencesCopyValue(
            preferenceKey as CFString,
            domain,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        ) else {
            return nil
        }

        if let boolValue = value as? Bool {
            return ScrollDirection(preferenceBoolValue: boolValue)
        }

        if let number = value as? NSNumber {
            return ScrollDirection(preferenceBoolValue: number.boolValue)
        }

        return nil
    }

    func apply(_ direction: ScrollDirection) throws -> ScrollApplyResult {
        let valueBefore = currentDirection()
        MouseFlipLogger.logPreferenceRead(valueBefore)
        MouseFlipLogger.log("Applying scroll direction: \(direction.rawValue)")

        CFPreferencesSetValue(
            preferenceKey as CFString,
            direction.preferenceBoolValue as CFPropertyList,
            domain,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )

        let synchronizeSuccess = CFPreferencesSynchronize(
            domain,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )

        let privateAPIApplied = PreferencePanesSupportBridge.applyNaturalScrolling(direction == .natural)
        let notificationPosted = postScrollDirectionChangedNotification()

        let valueAfter = currentDirection()
        let verifyMatch = valueAfter == direction

        MouseFlipLogger.logPreferenceWrite(
            requested: direction,
            synchronizeSuccess: synchronizeSuccess,
            valueAfter: valueAfter
        )

        if privateAPIApplied {
            MouseFlipLogger.log("Applied via PreferencePanesSupport (private API)")
        } else {
            MouseFlipLogger.log("PreferencePanesSupport unavailable; CFPreferences + notification only")
        }

        if notificationPosted {
            MouseFlipLogger.log("Posted SwipeScrollDirectionDidChangeNotification")
        }

        if !verifyMatch {
            MouseFlipLogger.logPreferenceError("Re-read did not match requested value")
            throw ScrollDirectionError.verifyFailed(expected: direction, actual: valueAfter)
        }

        return ScrollApplyResult(
            valueBefore: valueBefore,
            requested: direction,
            synchronizeSuccess: synchronizeSuccess,
            valueAfter: valueAfter,
            verifyMatch: verifyMatch,
            notificationPosted: notificationPosted,
            privateAPIApplied: privateAPIApplied
        )
    }

    func applyIfNecessary(_ direction: ScrollDirection) throws -> ScrollApplyResult? {
        if currentDirection() == direction {
            let privateAPIApplied = PreferencePanesSupportBridge.applyNaturalScrolling(direction == .natural)
            _ = postScrollDirectionChangedNotification()
            MouseFlipLogger.log(
                "Preference already \(direction.rawValue); refreshed system (private API=\(privateAPIApplied))"
            )
            return nil
        }
        return try apply(direction)
    }

    @discardableResult
    private func postScrollDirectionChangedNotification() -> Bool {
        DistributedNotificationCenter.default().post(
            name: scrollDirectionChangedNotification,
            object: nil,
            userInfo: nil
        )
        return true
    }
}

// MARK: - Private API fallback (isolated)
//
// Phase 2A (CFPreferences) and Phase 2B (notification) are insufficient on current macOS
// to change live scroll behavior. This uses dynamic loading of Apple's private
// PreferencePanesSupport.framework — undocumented and may break in future macOS versions.
private enum PreferencePanesSupportBridge {
    private static let frameworkPath =
        "/System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/PreferencePanesSupport"

    static func applyNaturalScrolling(_ natural: Bool) -> Bool {
        guard let handle = dlopen(frameworkPath, RTLD_LAZY) else {
            return false
        }
        defer { dlclose(handle) }

        guard let symbol = dlsym(handle, "setSwipeScrollDirection") else {
            return false
        }

        typealias SetSwipeScrollDirection = @convention(c) (Bool) -> Void
        let function = unsafeBitCast(symbol, to: SetSwipeScrollDirection.self)
        function(natural)
        return true
    }
}
