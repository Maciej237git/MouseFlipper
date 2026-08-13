import SwiftUI

struct StartupSettingsCard: View {
    @Binding var launchAtLogin: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("URUCHAMIANIE")

            Toggle(isOn: $launchAtLogin) {
                Text("Uruchamiaj razem z macOS")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mouseFlipPrimaryText)
            }
            .toggleStyle(.switch)

            Text("Włącz, żeby MouseFlip startował w tle razem z Macem i sam przełączał scroll po podłączeniu lub odłączeniu myszy.")
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
