import SwiftUI

@main
struct MouseFlipApp: App {
    @StateObject private var viewModel = MouseFlipViewModel()

    var body: some Scene {
        MenuBarExtra("MouseFlip", systemImage: "computermouse") {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
