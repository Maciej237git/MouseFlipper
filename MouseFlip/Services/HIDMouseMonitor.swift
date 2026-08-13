import Foundation
import IOKit

@MainActor
final class HIDMouseMonitor: ObservableObject {
    @Published private(set) var connectedMice: [HIDMouseDevice] = []

    private var miceByID: [String: HIDMouseDevice] = [:]
    private var notificationPort: IONotificationPortRef?
    private var isRunning = false

    func start() {
        guard !isRunning else { return }

        guard let port = IONotificationPortCreate(kIOMainPortDefault) else {
            MouseFlipLogger.log("Failed to create IONotificationPort")
            return
        }
        notificationPort = port

        let runLoopSource = IONotificationPortGetRunLoopSource(port)!.takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        let context = Unmanaged.passUnretained(self).toOpaque()

        var addedIterator: io_iterator_t = 0
        let addResult = IOServiceAddMatchingNotification(
            port,
            kIOFirstMatchNotification,
            IOServiceMatching(kIOHIDDeviceKey),
            Self.deviceAddedCallback,
            context,
            &addedIterator
        )

        if addResult != KERN_SUCCESS {
            MouseFlipLogger.log("Failed to register device added notification: \(addResult)")
            stop()
            return
        }

        drainIterator(addedIterator, handler: handleServiceAdded)

        var removedIterator: io_iterator_t = 0
        let removeResult = IOServiceAddMatchingNotification(
            port,
            kIOTerminatedNotification,
            IOServiceMatching(kIOHIDDeviceKey),
            Self.deviceRemovedCallback,
            context,
            &removedIterator
        )

        if removeResult != KERN_SUCCESS {
            MouseFlipLogger.log("Failed to register device removed notification: \(removeResult)")
            stop()
            return
        }

        drainIterator(removedIterator, handler: handleServiceRemoved)

        isRunning = true
        MouseFlipLogger.logHIDInit()
        refreshDevices()
    }

    func stop() {
        guard isRunning || notificationPort != nil else { return }

        if let port = notificationPort {
            let source = IONotificationPortGetRunLoopSource(port)!.takeUnretainedValue()
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            IONotificationPortDestroy(port)
            notificationPort = nil
        }

        isRunning = false
        miceByID = [:]
        connectedMice = []
    }

    func refreshDevices() {
        var freshMiceByID: [String: HIDMouseDevice] = [:]

        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching(kIOHIDDeviceKey), &iterator)

        guard result == KERN_SUCCESS else {
            MouseFlipLogger.log("IOServiceGetMatchingServices failed: \(result)")
            return
        }

        defer { IOObjectRelease(iterator) }

        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }

            if let mouse = mouseDevice(from: service) {
                freshMiceByID[mouse.id] = mouse
            }

            IOObjectRelease(service)
        }

        let previousIDs = Set(miceByID.keys)
        let newIDs = Set(freshMiceByID.keys)

        for addedID in newIDs.subtracting(previousIDs) {
            if let mouse = freshMiceByID[addedID] {
                MouseFlipLogger.logDeviceAttached(mouse)
            }
        }

        for removedID in previousIDs.subtracting(newIDs) {
            if let mouse = miceByID[removedID] {
                MouseFlipLogger.logDeviceRemoved(mouse)
            }
        }

        miceByID = freshMiceByID
        connectedMice = freshMiceByID.values.sorted { $0.productName < $1.productName }
        MouseFlipLogger.logEnumeration(count: connectedMice.count)
    }

    // MARK: - Callbacks

    private static let deviceAddedCallback: IOServiceMatchingCallback = { refCon, iterator in
        guard let refCon else { return }
        let monitor = Unmanaged<HIDMouseMonitor>.fromOpaque(refCon).takeUnretainedValue()
        Task { @MainActor in
            monitor.drainIterator(iterator, handler: monitor.handleServiceAdded)
        }
    }

    private static let deviceRemovedCallback: IOServiceMatchingCallback = { refCon, iterator in
        guard let refCon else { return }
        let monitor = Unmanaged<HIDMouseMonitor>.fromOpaque(refCon).takeUnretainedValue()
        Task { @MainActor in
            monitor.drainIterator(iterator, handler: monitor.handleServiceRemoved)
        }
    }

    private func drainIterator(_ iterator: io_iterator_t, handler: (io_service_t) -> Void) {
        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }
            handler(service)
            IOObjectRelease(service)
        }
    }

    private func handleServiceAdded(_ service: io_service_t) {
        MouseFlipLogger.logDeviceMetadata(service, event: "Device attached")

        guard let mouse = mouseDevice(from: service) else { return }
        guard miceByID[mouse.id] == nil else { return }

        miceByID[mouse.id] = mouse
        connectedMice = miceByID.values.sorted { $0.productName < $1.productName }
        MouseFlipLogger.logDeviceAttached(mouse)
    }

    private func handleServiceRemoved(_ service: io_service_t) {
        MouseFlipLogger.logDeviceMetadata(service, event: "Device removed")

        guard let mouse = mouseDevice(from: service) else {
            if let reason = IORegistryHID.rejectionReason(for: service) {
                MouseFlipLogger.logRejectedDevice(service, reason: reason)
            }
            return
        }

        guard miceByID.removeValue(forKey: mouse.id) != nil else { return }

        connectedMice = miceByID.values.sorted { $0.productName < $1.productName }
        MouseFlipLogger.logDeviceRemoved(mouse)
    }

    // MARK: - Device parsing

    private func mouseDevice(from service: io_service_t) -> HIDMouseDevice? {
        if let reason = IORegistryHID.rejectionReason(for: service) {
            MouseFlipLogger.logRejectedDevice(service, reason: reason)
            return nil
        }

        return HIDMouseDevice.make(from: service)
    }
}
