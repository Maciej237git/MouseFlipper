# MouseFlip — API Documentation

## Public APIs used

| API | Framework | Purpose |
|-----|-----------|---------|
| `IOHIDManagerCreate`, `IOHIDManagerOpen/Close` | IOKit | HID device manager lifecycle |
| `IOHIDManagerSetDeviceMatching` | IOKit | Match Generic Desktop / Mouse devices |
| `IOHIDManagerRegisterDeviceMatchingCallback` | IOKit | Device connect notifications |
| `IOHIDManagerRegisterDeviceRemovalCallback` | IOKit | Device disconnect notifications |
| `IOHIDManagerCopyDevices` | IOKit | Enumerate / refresh connected devices |
| `IOHIDDeviceConformsTo` | IOKit | Accept composite multi-usage mouse devices |
| `IOHIDDeviceGetService` + `IORegistryEntryGetRegistryEntryID` | IOKit | Session/runtime device identity |
| `CFPreferencesCopyValue/SetValue/Synchronize` | CoreFoundation | Read/write global scroll preference |
| `SMAppService.mainApp` | ServiceManagement | Launch at Login |
| `NSWorkspace.didWakeNotification` | AppKit | Wake reconciliation |
| `MenuBarExtra` | SwiftUI | Menu bar utility UI |

## Undocumented mechanisms (isolated)

| Mechanism | Status | Location |
|-----------|--------|----------|
| `com.apple.swipescrolldirection` | Undocumented preference key | `ScrollDirectionManager.swift` only |
| Undocumented notifications | **Not used** | — |
| Private frameworks / dlopen | **Not used** | — |

## Explicitly excluded (verified absent from source)

- `CGEventTap`
- `IOHIDManagerRegisterInputValueCallback`
- Accessibility APIs
- Input Monitoring
- Network / analytics / telemetry
- `dlopen` / `dlsym` / `PreferencePanesSupport`

## Build

```bash
xcodebuild \
  -project MouseFlip.xcodeproj \
  -scheme MouseFlip \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Requires full Xcode. Alternative syntax check: compile all `.swift` files with `swiftc` against macOS 13 SDK.

## Manual testing checklist

1. App starts with no mouse → trackpad mode, natural scrolling
2. App starts with Bluetooth mouse connected → mouse mode, standard scrolling
3. Connect mouse while running → switch to standard once
4. Disconnect mouse → switch to natural once
5. USB mouse → detected
6. Wireless receiver mouse → detected
7. Two mice → mouse mode
8. Disconnect one of two → remain in mouse mode
9. Disconnect final mouse → trackpad mode
10. Disable automatic switching → UI updates, scroll unchanged
11. Re-enable automatic switching → correct direction applied
12. Sleep/wake with mouse connected → state reconciled
13. Mouse off during sleep → trackpad mode after wake + grace delay
14. Launch at Login ON (app in `/Applications`) → launches at login
15. Launch at Login OFF → no auto-launch
