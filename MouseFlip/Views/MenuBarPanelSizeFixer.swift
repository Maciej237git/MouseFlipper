import AppKit
import SwiftUI

/// MenuBarExtra windows often ignore SwiftUI frame — resize the NSWindow directly.
struct MenuBarPanelSizeFixer: NSViewRepresentable {
    let size: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        applySize(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        applySize(from: nsView)
    }

    private func applySize(from view: NSView) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.setContentSize(size)
            window.minSize = NSSize(width: size.width, height: size.height)
            window.maxSize = NSSize(width: size.width, height: size.height + 120)
        }
    }
}
