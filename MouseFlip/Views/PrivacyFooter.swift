import SwiftUI

struct PrivacyFooter: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 14))
                .foregroundStyle(Color.mouseFlipSecondaryText)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("100% lokalnie")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.mouseFlipSecondaryText)
                Text("Brak internetu i telemetrii")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mouseFlipTertiaryText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("100% lokalnie. Brak internetu i telemetrii.")
    }
}
