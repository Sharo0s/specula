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
        // Identifiée : la barre de menus doit pouvoir rouvrir une fenêtre
        // quand l'app tourne sans Dock et que la dernière a été fermée.
        WindowGroup(id: "main") {
            MacRootView()
                .environment(store)
                .environment(\.locale, store.localeOverride ?? .autoupdatingCurrent)
                // `transformEnvironment` et pas `environment` : en mode « Système »
                // la direction héritée du réglage iOS/macOS doit rester intacte.
                .transformEnvironment(\.layoutDirection) {
                    if let direction = store.layoutDirectionOverride { $0 = direction }
                }
                // Posé sur la fenêtre, comme la langue : appliqué plus bas dans
                // la hiérarchie, il laisserait les feuilles et les popovers au
                // thème du système.
                .preferredColorScheme(store.colorSchemeOverride)
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
            Image(systemName: store.anyDown || store.homelabUnreachable
                  ? "exclamationmark.square.fill" : "square.fill")
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            IOSRootView()
                .environment(store)
                .environment(\.locale, store.localeOverride ?? .autoupdatingCurrent)
                // `transformEnvironment` et pas `environment` : en mode « Système »
                // la direction héritée du réglage iOS/macOS doit rester intacte.
                .transformEnvironment(\.layoutDirection) {
                    if let direction = store.layoutDirectionOverride { $0 = direction }
                }
                .preferredColorScheme(store.colorSchemeOverride)
        }
        #endif
    }
}
