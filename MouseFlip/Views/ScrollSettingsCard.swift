import SwiftUI

struct ScrollSettingsCard: View {
    @Binding var mouseDirection: ScrollDirection
    @Binding var trackpadDirection: ScrollDirection
    let onMouseDirectionChange: (ScrollDirection) -> Void
    let onTrackpadDirectionChange: (ScrollDirection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("KIERUNEK PRZEWIJANIA")

            directionRow(
                icon: "computermouse",
                title: "Mysz",
                selection: mouseDirection,
                onChange: { direction in
                    mouseDirection = direction
                    onMouseDirectionChange(direction)
                }
            )

            directionRow(
                icon: "rectangle.and.hand.point.up.left",
                title: "Trackpad",
                selection: trackpadDirection,
                onChange: { direction in
                    trackpadDirection = direction
                    onTrackpadDirectionChange(direction)
                }
            )

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Color.mouseFlipTertiaryText)
                    .accessibilityHidden(true)
                Text("macOS używa jednego globalnego kierunku przewijania. MouseFlip przełącza go między trybem myszy a gładzika — nie obsługuje dwóch kierunków jednocześnie.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mouseFlipTertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .help("macOS używa jednego globalnego kierunku przewijania dla wszystkich urządzeń wejściowych.")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.mouseFlipSecondaryText)
            .tracking(0.5)
    }

    private func directionRow(
        icon: String,
        title: String,
        selection: ScrollDirection,
        onChange: @escaping (ScrollDirection) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.mouseFlipPrimaryText)

            Picker(title, selection: Binding(
                get: { selection },
                set: { onChange($0) }
            )) {
                Text("Normalny").tag(ScrollDirection.standard)
                Text("Naturalny").tag(ScrollDirection.natural)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
}
