import AppKit
import Foundation

/// Stub for Phase 4 — wake reconciliation with configurable one-shot grace delay.
final class WakeMonitor {
    private var observer: NSObjectProtocol?
    private let graceDelaySeconds: TimeInterval
    private var onWake: (() -> Void)?

    init(graceDelaySeconds: TimeInterval = 0.5) {
        self.graceDelaySeconds = graceDelaySeconds
    }

    func start(onWake: @escaping () -> Void) {
        self.onWake = onWake
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleWake()
        }
    }

    func stop() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
        onWake = nil
    }

    private func handleWake() {
        MouseFlipLogger.logWake()
        let callback = onWake
        Task { @MainActor in
            let delay = UInt64((self.graceDelaySeconds * 1_000_000_000).rounded())
            try? await Task.sleep(nanoseconds: delay)
            callback?()
        }
    }
}
