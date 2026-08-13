import SwiftUI

struct StatusCard: View {
    let isExternalMouseConnected: Bool
    let primaryMouse: HIDMouseDevice?
    let additionalMouseCount: Int
    let effectiveDirection: ScrollDirection?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isExternalMouseConnected, let mouse = primaryMouse {
                mouseConnectedContent(mouse: mouse)
            } else {
                trackpadModeContent
            }

            Divider()

            HStack {
                Text("Scroll")
                    .foregroundStyle(Color.mouseFlipSecondaryText)
                Spacer()
                Text(effectiveDirection?.statusLabel ?? "—")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mouseFlipPrimaryText)
            }
        }
        .padding(16)
        .background(Color.mouseFlipCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.mouseFlipCardBorder, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isExternalMouseConnected)
        .animation(.easeInOut(duration: 0.2), value: primaryMouse?.id)
    }

    private func mouseConnectedContent(mouse: HIDMouseDevice) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.mouseFlipSuccess)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text("Mysz podłączona")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.mouseFlipPrimaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Mysz podłączona")

            Text(mouse.productName)
                .font(.system(size: 14))
                .foregroundStyle(Color.mouseFlipPrimaryText)

            if let transport = mouse.transport {
                Text(transport)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mouseFlipSecondaryText)
            }

            if additionalMouseCount == 1 {
                Text("+ 1 dodatkowa mysz")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mouseFlipSecondaryText)
            } else if additionalMouseCount > 1 {
                Text("+\(additionalMouseCount) dodatkowe mysze")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mouseFlipSecondaryText)
            }
        }
    }

    private var trackpadModeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.mouseFlipAccent)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text("Tryb gładzika")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.mouseFlipPrimaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tryb gładzika")

            Text("Brak zewnętrznej myszy")
                .font(.system(size: 13))
                .foregroundStyle(Color.mouseFlipSecondaryText)
        }
    }
}
