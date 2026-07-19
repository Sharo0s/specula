import SwiftUI

// MARK: - Specula — dashboard homelab natif iOS / macOS
// Design system Modernist : flat, architectural, radius 0, un seul accent rouge.

@main
struct SpeculaApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MacRootView()
                .environment(store)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1320, height: 820)

        // Mode TV / kiosque — menu Fenêtre → Mode TV
        Window("Mode TV", id: "tv") {
            MacTVView()
                .environment(store)
        }
        .defaultSize(width: 1280, height: 720)

        // Barre de menus : carré rouge + badge panne
        MenuBarExtra {
            MenuBarPopover()
                .environment(store)
        } label: {
            Image(systemName: store.anyDown ? "exclamationmark.square.fill" : "square.fill")
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            IOSRootView()
                .environment(store)
                .environment(\.locale, Locale(identifier: "fr_FR"))
        }
        #endif
    }
}
