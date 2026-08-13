import Combine
import AppKit
import Foundation

@MainActor
final class MouseFlipViewModel: ObservableObject {
    @Published var automaticSwitchingEnabled: Bool
    @Published var mouseDirection: ScrollDirection
    @Published var trackpadDirection: ScrollDirection
    @Published var launchAtLogin: Bool
    @Published private(set) var currentDirection: ScrollDirection?
    @Published var lastErrorMessage: String?

    let hidMonitor = HIDMouseMonitor()
    let scrollDirectionManager = ScrollDirectionManager()

    private let launchAtLoginManager = LaunchAtLoginManager()
    private let wakeMonitor = WakeMonitor(graceDelaySeconds: 0.5)
    private var cancellables = Set<AnyCancellable>()
    private var isMonitoring = false
    private var backgroundRefreshTimer: Timer?
    private static var didStartAtLaunch = false

    private let backgroundRefreshInterval: TimeInterval = 15

    var connectedMice: [HIDMouseDevice] {
        hidMonitor.connectedMice
    }

    var isExternalMouseConnected: Bool {
        !connectedMice.isEmpty
    }

    var currentEffectiveDirection: ScrollDirection? {
        guard automaticSwitchingEnabled else {
            return currentDirection
        }
        return isExternalMouseConnected ? mouseDirection : trackpadDirection
    }

    var primaryMouse: HIDMouseDevice? {
        connectedMice.first
    }

    var additionalMouseCount: Int {
        max(0, connectedMice.count - 1)
    }

    init() {
        MouseFlipSettings.ensureDefaults()

        automaticSwitchingEnabled = MouseFlipSettings.loadAutomaticSwitching()
        mouseDirection = MouseFlipSettings.loadMouseDirection()
        trackpadDirection = MouseFlipSettings.loadTrackpadDirection()
        launchAtLogin = false
        currentDirection = nil

        hidMonitor.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        hidMonitor.$connectedMice
            .receive(on: RunLoop.main)
            .sink { [weak self] mice in
                guard let self, self.isMonitoring, self.automaticSwitchingEnabled else { return }
                MouseFlipLogger.log("Connected mice changed: \(mice.count)")
                self.reconcileScrollDirection()
            }
            .store(in: &cancellables)

        Task { @MainActor in
            guard !Self.didStartAtLaunch else { return }
            Self.didStartAtLaunch = true
            self.start()
        }
    }

    func start() {
        MouseFlipLogger.logLaunch()
        currentDirection = scrollDirectionManager.currentDirection()
        MouseFlipLogger.logPreferenceRead(currentDirection)

        launchAtLogin = launchAtLoginManager.isEnabled
        hidMonitor.start()
        isMonitoring = true

        wakeMonitor.start { [weak self] in
            Task { @MainActor in
                self?.handleWake()
            }
        }

        reconcileScrollDirection()
        enableLaunchAtLoginIfNeeded()
        startBackgroundRefreshTimer()
    }

    func stop() {
        isMonitoring = false
        backgroundRefreshTimer?.invalidate()
        backgroundRefreshTimer = nil
        wakeMonitor.stop()
        hidMonitor.stop()
    }

    func quit() {
        if automaticSwitchingEnabled {
            applyDirection(trackpadDirection, force: true)
        }
        stop()
        NSApplication.shared.terminate(nil)
    }

    func refreshDevices() {
        hidMonitor.refreshDevices()
        reconcileScrollDirection()
    }

    func setAutomaticSwitchingEnabled(_ enabled: Bool) {
        automaticSwitchingEnabled = enabled
        MouseFlipSettings.saveAutomaticSwitching(enabled)

        if enabled {
            reconcileScrollDirection()
        }
    }

    func setMouseDirection(_ direction: ScrollDirection) {
        mouseDirection = direction
        MouseFlipSettings.saveMouseDirection(direction)

        if automaticSwitchingEnabled && isExternalMouseConnected {
            applyDirection(direction, force: true)
        }
    }

    func setTrackpadDirection(_ direction: ScrollDirection) {
        trackpadDirection = direction
        MouseFlipSettings.saveTrackpadDirection(direction)

        if automaticSwitchingEnabled && !isExternalMouseConnected {
            applyDirection(direction, force: true)
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        lastErrorMessage = nil
        let previous = launchAtLogin
        launchAtLogin = enabled

        do {
            try launchAtLoginManager.setEnabled(enabled)
            launchAtLogin = launchAtLoginManager.isEnabled
        } catch {
            launchAtLogin = previous
            lastErrorMessage = error.localizedDescription
        }
    }

    func reconcileScrollDirection() {
        guard automaticSwitchingEnabled else { return }

        let target = isExternalMouseConnected ? mouseDirection : trackpadDirection
        MouseFlipLogger.log(
            "Auto reconcile: mice=\(connectedMice.count) target=\(target.rawValue)"
        )
        applyDirection(target, force: true)
    }

    private func handleWake() {
        hidMonitor.refreshDevices()
        reconcileScrollDirection()
    }

    private func startBackgroundRefreshTimer() {
        backgroundRefreshTimer?.invalidate()
        backgroundRefreshTimer = Timer.scheduledTimer(
            withTimeInterval: backgroundRefreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.performBackgroundRefresh()
            }
        }
    }

    private func performBackgroundRefresh() {
        guard isMonitoring else { return }

        hidMonitor.refreshDevices()

        guard automaticSwitchingEnabled else { return }

        let target = isExternalMouseConnected ? mouseDirection : trackpadDirection
        if scrollDirectionManager.currentDirection() != target {
            MouseFlipLogger.log("Background refresh: scroll drift detected, re-applying \(target.rawValue)")
            reconcileScrollDirection()
        }
    }

    private func enableLaunchAtLoginIfNeeded() {
        guard !launchAtLogin else { return }
        guard Bundle.main.bundlePath.hasPrefix("/Applications/") else { return }

        do {
            try launchAtLoginManager.setEnabled(true)
            launchAtLogin = launchAtLoginManager.isEnabled
            MouseFlipLogger.log("Enabled launch at login automatically")
        } catch {
            MouseFlipLogger.log("Could not auto-enable launch at login: \(error.localizedDescription)")
        }
    }

    private func applyDirection(_ direction: ScrollDirection, force: Bool = false) {
        lastErrorMessage = nil

        do {
            if force {
                _ = try scrollDirectionManager.apply(direction)
            } else {
                _ = try scrollDirectionManager.applyIfNecessary(direction)
            }
            currentDirection = scrollDirectionManager.currentDirection()
        } catch {
            lastErrorMessage = error.localizedDescription
            MouseFlipLogger.logPreferenceError(error.localizedDescription)
        }
    }
}
