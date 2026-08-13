import Foundation
import IOKit
import IOKit.hid

enum MouseFlipLogger {
    static func log(_ message: String) {
        #if DEBUG
        print("[MouseFlip] \(message)")
        #endif
    }

    static func logLaunch() {
        log("App launch")
    }

    static func logHIDInit() {
        log("HID registry monitor initialization")
    }

    static func logDeviceAttached(_ device: HIDMouseDevice) {
        log("Device attached: \(device.productName) [\(device.id)]")
    }

    static func logDeviceRemoved(_ device: HIDMouseDevice) {
        log("Device removed: \(device.productName) [\(device.id)]")
    }

    static func logEnumeration(count: Int) {
        log("Device enumeration complete: \(count) external mouse(es)")
    }

    static func logDeviceMetadata(_ service: io_registry_entry_t, event: String) {
        #if DEBUG
        let product = IORegistryHID.stringProperty(kIOHIDProductKey, on: service) ?? "—"
        let manufacturer = IORegistryHID.stringProperty(kIOHIDManufacturerKey, on: service) ?? "—"
        let vendorID = IORegistryHID.intProperty(kIOHIDVendorIDKey, on: service)
        let productID = IORegistryHID.intProperty(kIOHIDProductIDKey, on: service)
        let usagePage = IORegistryHID.intProperty(kIOHIDPrimaryUsagePageKey, on: service)
        let usage = IORegistryHID.intProperty(kIOHIDPrimaryUsageKey, on: service)
        let transport = IORegistryHID.stringProperty(kIOHIDTransportKey, on: service) ?? "—"
        let builtIn = IORegistryHID.boolProperty(kIOHIDBuiltInKey, on: service)
        let registryEntryID = IORegistryHID.registryEntryID(for: service).map(String.init) ?? "—"
        let pairs = IORegistryHID.usagePairs(on: service)
            .map { "(\($0.page), \($0.usage))" }
            .joined(separator: ", ")

        print("""
        [MouseFlip]
        \(event)

        Product:
        \(product)

        Manufacturer:
        \(manufacturer)

        Vendor ID:
        \(vendorID.map(String.init) ?? "—")

        Product ID:
        \(productID.map(String.init) ?? "—")

        Usage Page:
        \(usagePage.map(String.init) ?? "—")

        Usage:
        \(usage.map(String.init) ?? "—")

        Usage Pairs:
        \(pairs.isEmpty ? "—" : pairs)

        Transport:
        \(transport)

        Built-in:
        \(builtIn.map { $0 ? "true" : "false" } ?? "—")

        Registry Entry ID:
        \(registryEntryID)
        """)
        #endif
    }

    static func logRejectedDevice(_ service: io_registry_entry_t, reason: String) {
        #if DEBUG
        let product = IORegistryHID.stringProperty(kIOHIDProductKey, on: service) ?? "Unknown"
        log("Rejected HID device '\(product)': \(reason)")
        #endif
    }

    static func logPreferenceRead(_ direction: ScrollDirection?) {
        log("Current scrolling preference: \(direction?.rawValue ?? "nil")")
    }

    static func logPreferenceWrite(requested: ScrollDirection, synchronizeSuccess: Bool, valueAfter: ScrollDirection?) {
        log("Requested scrolling preference: \(requested.rawValue)")
        log("CFPreferencesSynchronize success: \(synchronizeSuccess)")
        log("Value after write: \(valueAfter?.rawValue ?? "nil")")
    }

    static func logPreferenceError(_ message: String) {
        log("Preference error: \(message)")
    }

    static func logWake() {
        log("Mac wake notification received")
    }

    static func logLaunchAtLogin(_ message: String) {
        log("Launch at login: \(message)")
    }
}
