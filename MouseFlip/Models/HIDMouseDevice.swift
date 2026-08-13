import Foundation
import IOKit
import IOKit.hid

enum IORegistryHID {
    private static let deviceUsagePairsKey = "DeviceUsagePairs"

    struct UsagePair {
        let page: Int
        let usage: Int
    }

    static func stringProperty(_ key: String, on service: io_registry_entry_t) -> String? {
        guard let value = copyProperty(key, on: service) else { return nil }
        return value as? String
    }

    static func intProperty(_ key: String, on service: io_registry_entry_t) -> Int? {
        guard let value = copyProperty(key, on: service) else { return nil }
        if let number = value as? NSNumber { return number.intValue }
        if let number = value as? Int { return number }
        return nil
    }

    static func boolProperty(_ key: String, on service: io_registry_entry_t) -> Bool? {
        guard let value = copyProperty(key, on: service) else { return nil }
        if let number = value as? NSNumber { return number.boolValue }
        if let boolean = value as? Bool { return boolean }
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            let boolean = (value as! CFBoolean)
            return CFBooleanGetValue(boolean)
        }
        return nil
    }

    static func registryEntryID(for service: io_registry_entry_t) -> UInt64? {
        var entryID: UInt64 = 0
        guard IORegistryEntryGetRegistryEntryID(service, &entryID) == KERN_SUCCESS else {
            return nil
        }
        return entryID
    }

    static func usagePairs(on service: io_registry_entry_t) -> [UsagePair] {
        guard let value = copyProperty(deviceUsagePairsKey, on: service) else {
            return []
        }

        guard let array = value as? [Any] else {
            return []
        }

        var pairs: [UsagePair] = []
        for element in array {
            guard let dict = element as? [String: Any] else { continue }

            let page = int(fromAny: dict["UsagePage"])
                ?? int(fromAny: dict[kIOHIDDeviceUsagePageKey])
            let usage = int(fromAny: dict["Usage"])
                ?? int(fromAny: dict[kIOHIDDeviceUsageKey])

            if let page, let usage {
                pairs.append(UsagePair(page: page, usage: usage))
            }
        }

        return pairs
    }

    static func conformsToMouse(_ service: io_registry_entry_t) -> Bool {
        if let page = intProperty(kIOHIDPrimaryUsagePageKey, on: service),
           let usage = intProperty(kIOHIDPrimaryUsageKey, on: service),
           page == kHIDPage_GenericDesktop,
           usage == kHIDUsage_GD_Mouse {
            return true
        }

        let pairs = usagePairs(on: service)
        return pairs.contains(where: { $0.page == kHIDPage_GenericDesktop && $0.usage == kHIDUsage_GD_Mouse })
    }

    static func rejectionReason(for service: io_registry_entry_t) -> String? {
        if !conformsToMouse(service) {
            return "no mouse usage"
        }

        if boolProperty(kIOHIDBuiltInKey, on: service) == true {
            return "built-in device"
        }

        let product = stringProperty(kIOHIDProductKey, on: service)?.lowercased() ?? ""
        if product.contains("trackpad") || product.contains("internal") {
            return "trackpad/internal name"
        }

        return nil
    }

    private static func copyProperty(_ key: String, on service: io_registry_entry_t) -> CFTypeRef? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }

    private static func int(fromAny value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let number = value as? Int { return number }
        return nil
    }
}

struct HIDMouseDevice: Identifiable, Hashable {
    let id: String
    let productName: String
    let manufacturer: String?
    let vendorID: Int?
    let productID: Int?
    let transport: String?
    let locationID: Int?
    let registryEntryID: UInt64?
    let serialNumber: String?

    static func make(from service: io_registry_entry_t) -> HIDMouseDevice? {
        let productName = IORegistryHID.stringProperty(kIOHIDProductKey, on: service) ?? "Unknown Mouse"
        let manufacturer = IORegistryHID.stringProperty(kIOHIDManufacturerKey, on: service)
        let vendorID = IORegistryHID.intProperty(kIOHIDVendorIDKey, on: service)
        let productID = IORegistryHID.intProperty(kIOHIDProductIDKey, on: service)
        let transport = IORegistryHID.stringProperty(kIOHIDTransportKey, on: service)
        let locationID = IORegistryHID.intProperty(kIOHIDLocationIDKey, on: service)
        let serialNumber = IORegistryHID.stringProperty(kIOHIDSerialNumberKey, on: service)
        let registryEntryID = IORegistryHID.registryEntryID(for: service)

        let id = makeIdentifier(
            registryEntryID: registryEntryID,
            vendorID: vendorID,
            productID: productID,
            locationID: locationID,
            transport: transport,
            serialNumber: serialNumber
        )

        return HIDMouseDevice(
            id: id,
            productName: productName,
            manufacturer: manufacturer,
            vendorID: vendorID,
            productID: productID,
            transport: transport,
            locationID: locationID,
            registryEntryID: registryEntryID,
            serialNumber: serialNumber
        )
    }

    private static func makeIdentifier(
        registryEntryID: UInt64?,
        vendorID: Int?,
        productID: Int?,
        locationID: Int?,
        transport: String?,
        serialNumber: String?
    ) -> String {
        if let registryEntryID {
            return "registry-\(registryEntryID)"
        }

        let parts = [
            vendorID.map(String.init),
            productID.map(String.init),
            locationID.map(String.init),
            transport,
            serialNumber
        ]
        .compactMap { $0 }

        if parts.isEmpty {
            return UUID().uuidString
        }

        return parts.joined(separator: "-")
    }
}
