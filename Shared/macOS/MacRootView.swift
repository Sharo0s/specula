#if os(macOS)
import SwiftUI
import AppKit

enum MacView: Hashable {
    case dash, status, notifs, settings, add
}

@MainActor
@Observable
final class MacUIState {
    var view: MacView = .dash
    /// Groupe filtré dans le dashboard (nil = tous).
    var group: Int?
    /// Service sélectionné → inspecteur.
    var selection: String? = "immich"
    var paletteOpen = false
    var forceDark = false
}

struct MacRootView: View {
    @Environment(AppStore.self) private var store
    @State private var ui = MacUIState()
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        gate
            .speculaPaywall()
            .background(WindowSizer())
            .task {
                // Ouverture de session : on applique la visibilité du Dock puis
                // on referme la fenêtre — le relevé tourne dans la barre de menus
                // sans s'imposer à l'écran au démarrage du Mac.
                LoginItem.applyDockVisibility(hidden: store.menuBarOnly)
                if LoginItem.launchedAtLogin {
                    LoginItem.closeMainWindow()
                }
            }
    }

    @ViewBuilder private var gate: some View {
        if hasOnboarded {
            mainContent
        } else {
            OnboardingView(done: {
                hasOnboarded = true
                store.finishOnboarding()
            })
                .frame(minWidth: 760, minHeight: 640)
                .preferredColorScheme(ui.forceDark ? .dark : nil)
        }
    }

    private var mainContent: some View {
        ZStack {
            HStack(spacing: 0) {
                MacSidebar(ui: ui)
                    .frame(width: 230)
                VRule(weight: 2)
                VStack(spacing: 0) {
                    MacToolbar(ui: ui)
                    HRule(weight: 2)
                    content
                }
                .frame(maxWidth: .infinity)
            }
            .background(Ink.bg)

            if ui.paletteOpen {
                MacPalette(ui: ui)
            }

            ToastOverlay()
        }
        .frame(minWidth: 1280, minHeight: 800)
        .environment(ui)
        .preferredColorScheme(ui.forceDark ? .dark : nil)
        .background {
            // ⌘K global
            Button("") { ui.paletteOpen.toggle() }
                .keyboardShortcut("k", modifiers: .command)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch ui.view {
        case .dash: MacDashboard(ui: ui)
        case .status: MacStatusView()
        case .notifs: MacNotificationsPage()
        case .settings: MacSettingsPage()
        case .add: MacAddServicePage(ui: ui)
        }
    }
}

// MARK: - Toolbar (bande custom sous la barre de titre)

struct MacToolbar: View {
    @Environment(AppStore.self) private var store
    @Bindable var ui: MacUIState

    var body: some View {
        @Bindable var store = store
        HStack(spacing: 14) {
            Text(LocalizedStringKey(title))
                .font(.archivo(19, .heavy))
            Spacer()
            if ui.view == .dash {
                MSeg(options: [(Density.aere, "Aéré"), (Density.compact, "Compact")], selection: $store.density)
                MSeg(options: [(LayoutMode.grille, "Grille"), (LayoutMode.liste, "Liste")], selection: $store.layout)
            }
            Button {
                ui.paletteOpen.toggle()
            } label: {
                Text("⌘K")
                    .font(.archivo(11, .heavy))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Button {
                ui.forceDark.toggle()
            } label: {
                Image(systemName: ui.forceDark ? "sun.max" : "moon")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 30, height: 28)
                    .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Text(Date.now, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .font(.archivo(12)).monospacedDigit()
                .foregroundStyle(Ink.muted)
        }
        .foregroundStyle(Ink.text)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var title: String {
        switch ui.view {
        case .dash:
            if let g = ui.group, g < store.groups(of: store.server).count {
                return store.groups(of: store.server)[g]
            }
            return "Tableau de bord"
        case .status: return "Statut"
        case .notifs: return "Notifications"
        case .settings: return "Réglages"
        case .add: return "Ajouter un service"
        }
    }
}

// MARK: - Dimensionnement adaptatif de la fenêtre

/// Ouvre la fenêtre à une taille proportionnelle à l'écran (adaptée à la résolution),
/// centrée, au lancement — indépendamment de la taille mémorisée par macOS.
private struct WindowSizer: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window,
                  let screen = window.screen ?? NSScreen.main else { return }
            let visible = screen.visibleFrame
            let w = min(visible.width, max(1280, visible.width * 0.90))
            let h = min(visible.height, max(800, visible.height * 0.92))
            window.setFrame(NSRect(x: visible.minX + (visible.width - w) / 2,
                                   y: visible.minY + (visible.height - h) / 2,
                                   width: w, height: h),
                            display: true, animate: false)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
