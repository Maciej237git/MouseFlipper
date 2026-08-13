import SwiftUI

struct StartupSettingsCard: View {
    @Binding var launchAtLogin: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("URUCHAMIANIE")

            Toggle(isOn: Binding(
                get: { launchAtLogin },
                set: { onToggle($0) }
            )) {
                Text("Uruchamiaj razem z macOS")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mouseFlipPrimaryText)
            }
            .toggleStyle(.switch)

            Text("Włącz, żeby MouseFlip działał w tle od startu Maca i sam przełączał scroll po podłączeniu lub odłączeniu myszy. Skopiuj aplikację do folderu Aplikacje przed włączeniem.")
                .font(.system(size: 11))
                .foregroundStyle(Color.mouseFlipTertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.mouseFlipSecondaryText)
            .tracking(0.5)
    }
}
