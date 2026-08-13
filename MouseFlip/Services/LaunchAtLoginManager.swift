import Darwin
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

/// Launch-at-login via LaunchAgent plist — works without code signing or Automation permission.
final class LaunchAtLoginManager {
    private let label = "com.maciejcybula.MouseFlip"

    private var appPath: String {
        Bundle.main.bundlePath
    }

    private var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    private var launchctlDomain: String {
        "gui/\(getuid())"
    }

    var isEnabled: Bool {
        if SMAppService.mainApp.status == .enabled {
            return true
        }
        return FileManager.default.fileExists(atPath: plistURL.path)
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
            try writeLaunchAgent()
            try loadLaunchAgent()
            MouseFlipLogger.logLaunchAtLogin("Registered via LaunchAgent")
        } catch {
            MouseFlipLogger.logLaunchAtLogin("Error: \(error.localizedDescription)")
            throw LaunchAtLoginError.registrationFailed
        }
    }

    private func unregister() throws {
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        }

        do {
            try unloadLaunchAgent()
            try? FileManager.default.removeItem(at: plistURL)
            MouseFlipLogger.logLaunchAtLogin("Unregistered LaunchAgent")
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

    private func writeLaunchAgent() throws {
        let agentsDirectory = plistURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: agentsDirectory, withIntermediateDirectories: true)

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": ["/usr/bin/open", "-a", appPath],
            "RunAtLoad": true,
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: plistURL, options: .atomic)
    }

    private func loadLaunchAgent() throws {
        try? runLaunchctl(["bootout", "\(launchctlDomain)/\(label)"])
        try runLaunchctl(["bootstrap", launchctlDomain, plistURL.path])
    }

    private func unloadLaunchAgent() throws {
        try runLaunchctl(["bootout", "\(launchctlDomain)/\(label)"])
    }

    private func runLaunchctl(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw NSError(
                domain: "LaunchAtLoginManager",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: output.trimmingCharacters(in: .whitespacesAndNewlines)]
            )
        }
    }
}
