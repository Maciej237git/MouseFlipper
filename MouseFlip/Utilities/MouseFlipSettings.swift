import Foundation

enum MouseFlipSettings {
    static let automaticSwitchingEnabled = "automaticSwitchingEnabled"
    static let mouseScrollDirection = "mouseScrollDirection"
    static let trackpadScrollDirection = "trackpadScrollDirection"

    private static let recommendedDefaultsAppliedKey = "recommendedScrollDefaultsApplied_v1"

    static func ensureDefaults(in defaults: UserDefaults = .standard) {
        if defaults.object(forKey: automaticSwitchingEnabled) == nil {
            defaults.set(true, forKey: automaticSwitchingEnabled)
        }
        if defaults.object(forKey: mouseScrollDirection) == nil {
            defaults.set(ScrollDirection.standard.rawValue, forKey: mouseScrollDirection)
        }
        if defaults.object(forKey: trackpadScrollDirection) == nil {
            defaults.set(ScrollDirection.natural.rawValue, forKey: trackpadScrollDirection)
        }

        // One-time migration: ensure the expected "set once, forget" defaults.
        if !defaults.bool(forKey: recommendedDefaultsAppliedKey) {
            defaults.set(ScrollDirection.standard.rawValue, forKey: mouseScrollDirection)
            defaults.set(ScrollDirection.natural.rawValue, forKey: trackpadScrollDirection)
            defaults.set(true, forKey: automaticSwitchingEnabled)
            defaults.set(true, forKey: recommendedDefaultsAppliedKey)
        }
    }

    static func loadAutomaticSwitching(from defaults: UserDefaults = .standard) -> Bool {
        if defaults.object(forKey: automaticSwitchingEnabled) == nil {
            return true
        }
        return defaults.bool(forKey: automaticSwitchingEnabled)
    }

    static func loadMouseDirection(from defaults: UserDefaults = .standard) -> ScrollDirection {
        guard let raw = defaults.string(forKey: mouseScrollDirection),
              let direction = ScrollDirection(rawValue: raw) else {
            return .standard
        }
        return direction
    }

    static func loadTrackpadDirection(from defaults: UserDefaults = .standard) -> ScrollDirection {
        guard let raw = defaults.string(forKey: trackpadScrollDirection),
              let direction = ScrollDirection(rawValue: raw) else {
            return .natural
        }
        return direction
    }

    static func saveAutomaticSwitching(_ enabled: Bool, to defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: automaticSwitchingEnabled)
    }

    static func saveMouseDirection(_ direction: ScrollDirection, to defaults: UserDefaults = .standard) {
        defaults.set(direction.rawValue, forKey: mouseScrollDirection)
    }

    static func saveTrackpadDirection(_ direction: ScrollDirection, to defaults: UserDefaults = .standard) {
        defaults.set(direction.rawValue, forKey: trackpadScrollDirection)
    }
}
