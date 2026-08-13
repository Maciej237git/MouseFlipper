import Foundation
import ServiceManagement

enum LaunchAtLoginError: LocalizedError {
    case registrationFailed
    case unregistrationFailed

    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "Nie udało się włączyć uruchamiania razem z macOS."
        case .unregistrationFailed:
            return "Nie udało się wyłączyć uruchamiania razem z macOS."
        }
    }
}

final class LaunchAtLoginManager {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                MouseFlipLogger.logLaunchAtLogin("Registered")
            } else {
                try SMAppService.mainApp.unregister()
                MouseFlipLogger.logLaunchAtLogin("Unregistered")
            }
        } catch {
            MouseFlipLogger.logLaunchAtLogin("Error: \(error.localizedDescription)")
            throw enabled ? LaunchAtLoginError.registrationFailed : LaunchAtLoginError.unregistrationFailed
        }
    }
}
