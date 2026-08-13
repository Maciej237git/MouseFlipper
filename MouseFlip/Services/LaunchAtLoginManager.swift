import AppKit
import Foundation
import ServiceManagement

enum LaunchAtLoginError: LocalizedError {
    case registrationFailed
    case unregistrationFailed
    case automationPermissionRequired

    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "Nie udało się włączyć uruchamiania razem z macOS."
        case .unregistrationFailed:
            return "Nie udało się wyłączyć uruchamiania razem z macOS."
        case .automationPermissionRequired:
            return "Zezwól MouseFlip na sterowanie „System Events” w Ustawieniach → Prywatność → Automatyzacja."
        }
    }
}

/// Registers the app to launch at login.
/// Uses SMAppService when signed; falls back to login items (works without code signing).
final class LaunchAtLoginManager {
    private var appPath: String {
        Bundle.main.bundlePath
    }

    var isEnabled: Bool {
        if SMAppService.mainApp.status == .enabled {
            return true
        }
        return LoginItemsScript.isRegistered(appPath: appPath)
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try register()
        } else {
            try unregister()
        }
    }

    private func register() throws {
        if try registerWithSMAppService() {
            MouseFlipLogger.logLaunchAtLogin("Registered via SMAppService")
            return
        }

        do {
            try LoginItemsScript.register(appPath: appPath)
            MouseFlipLogger.logLaunchAtLogin("Registered via login items")
        } catch {
            MouseFlipLogger.logLaunchAtLogin("Error: \(error.localizedDescription)")
            throw LaunchAtLoginError.registrationFailed
        }
    }

    private func unregister() throws {
        if SMAppService.mainApp.status == .enabled {
            do {
                try SMAppService.mainApp.unregister()
                MouseFlipLogger.logLaunchAtLogin("Unregistered via SMAppService")
            } catch {
                MouseFlipLogger.logLaunchAtLogin("SMAppService unregister error: \(error.localizedDescription)")
            }
        }

        do {
            try LoginItemsScript.unregister(appPath: appPath)
            MouseFlipLogger.logLaunchAtLogin("Unregistered via login items")
        } catch {
            MouseFlipLogger.logLaunchAtLogin("Error: \(error.localizedDescription)")
            throw LaunchAtLoginError.unregistrationFailed
        }
    }

    private func registerWithSMAppService() throws -> Bool {
        guard SMAppService.mainApp.status != .enabled else { return true }

        do {
            try SMAppService.mainApp.register()
            return SMAppService.mainApp.status == .enabled
        } catch {
            MouseFlipLogger.logLaunchAtLogin("SMAppService unavailable: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Login items fallback (no code signing required)

private enum LoginItemsScript {
    static func isRegistered(appPath: String) -> Bool {
        let script = """
        tell application "System Events"
            repeat with li in login items
                if path of li is "\(escaped(appPath))" then
                    return true
                end if
            end repeat
            return false
        end tell
        """

        guard let result = run(script), result.booleanValue else {
            return false
        }
        return true
    }

    static func register(appPath: String) throws {
        let script = """
        tell application "System Events"
            set targetPath to "\(escaped(appPath))"
            repeat with li in login items
                if path of li is targetPath then
                    return "ok"
                end if
            end repeat
            make login item at end with properties {path:targetPath, hidden:false}
            return "ok"
        end tell
        """

        guard run(script) != nil else {
            throw LaunchAtLoginError.automationPermissionRequired
        }
    }

    static func unregister(appPath: String) throws {
        let script = """
        tell application "System Events"
            set targetPath to "\(escaped(appPath))"
            repeat with li in login items
                if path of li is targetPath then
                    delete li
                    exit repeat
                end if
            end repeat
            return "ok"
        end tell
        """

        guard run(script) != nil else {
            throw LaunchAtLoginError.automationPermissionRequired
        }
    }

    private static func escaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func run(_ source: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)

        if let error {
            MouseFlipLogger.logLaunchAtLogin("AppleScript error: \(error)")
            return nil
        }

        return result
    }
}
