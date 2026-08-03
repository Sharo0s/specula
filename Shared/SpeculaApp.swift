import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Specula — dashboard homelab natif iOS / macOS
// Design system Modernist : flat, architectural, radius 0, un seul accent rouge.

@main
struct SpeculaApp: App {
    @State private var store = AppStore()

    #if os(macOS)
    /// Taille de fenêtre par défaut adaptée à la résolution de l'écran
    /// (~82 % de la zone visible), avec un plancher, sans dépasser l'écran.
    /// macOS conserve ensuite la taille choisie par l'utilisateur.
    private static var defaultWindowSize: CGSize {
        guard let visible = NSScreen.main?.visibleFrame.size else {
            return CGSize(width: 1480, height: 920)
        }
        return CGSize(width: min(visible.width, max(1280, visible.width * 0.82)),
                      height: min(visible.height, max(800, visible.height * 0.88)))
    }
    #endif

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MacRootView()
                .environment(store)
                .environment(\.locale, store.localeOverride ?? .autoupdatingCurrent)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(Self.defaultWindowSize)

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
                .environment(\.locale, store.localeOverride ?? .autoupdatingCurrent)
        }
        #endif
    }
}
