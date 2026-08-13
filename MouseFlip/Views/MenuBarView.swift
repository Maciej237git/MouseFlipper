import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MouseFlipViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if let error = viewModel.lastErrorMessage {
                    errorBanner(error)
                }

                StatusCard(
                    isExternalMouseConnected: viewModel.isExternalMouseConnected,
                    primaryMouse: viewModel.primaryMouse,
                    additionalMouseCount: viewModel.additionalMouseCount,
                    effectiveDirection: viewModel.currentEffectiveDirection
                )

                automaticSection
                scrollSettingsSection
                startupSection

                Button {
                    viewModel.refreshDevices()
                } label: {
                    Label("Odśwież urządzenia", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .help("Zwykle niepotrzebne — MouseFlip działa w tle automatycznie.")

                PrivacyFooter()

                Button("Zakończ MouseFlip") {
                    viewModel.quit()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.mouseFlipSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .frame(width: 380)
        .background(Color.mouseFlipBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "computermouse")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.mouseFlipPrimaryText)
                    .accessibilityLabel("Ikona myszy")
                Text("MouseFlip")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.mouseFlipPrimaryText)
            }
            Text("Scroll switcher")
                .font(.system(size: 12))
                .foregroundStyle(Color.mouseFlipSecondaryText)
                .padding(.leading, 26)
        }
    }

    private var automaticSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("AUTOMATYKA")

            Toggle(isOn: Binding(
                get: { viewModel.automaticSwitchingEnabled },
                set: { viewModel.setAutomaticSwitchingEnabled($0) }
            )) {
                Text("Automatyczne przełączanie")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mouseFlipPrimaryText)
            }
            .toggleStyle(.switch)

            Text("Ustaw kierunki myszy i gładzika raz — aplikacja sama przełącza scroll po podłączeniu lub odłączeniu myszy.")
                .font(.system(size: 11))
                .foregroundStyle(Color.mouseFlipTertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var scrollSettingsSection: some View {
        ScrollSettingsCard(
            mouseDirection: Binding(
                get: { viewModel.mouseDirection },
                set: { _ in }
            ),
            trackpadDirection: Binding(
                get: { viewModel.trackpadDirection },
                set: { _ in }
            ),
            onMouseDirectionChange: { viewModel.setMouseDirection($0) },
            onTrackpadDirectionChange: { viewModel.setTrackpadDirection($0) }
        )
    }

    private var startupSection: some View {
        StartupSettingsCard(
            launchAtLogin: Binding(
                get: { viewModel.launchAtLogin },
                set: { _ in }
            ),
            onToggle: { viewModel.setLaunchAtLogin($0) }
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.mouseFlipSecondaryText)
            .tracking(0.5)
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12))
            .foregroundStyle(.red)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
