#if os(macOS)
import SwiftUI

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
    var selection: String? = "jellyfin"
    var paletteOpen = false
    var forceDark = false
}

struct MacRootView: View {
    @Environment(AppStore.self) private var store
    @State private var ui = MacUIState()

    var body: some View {
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
        .frame(minWidth: 1180, minHeight: 720)
        .environment(ui)
        .preferredColorScheme(ui.forceDark ? .dark : nil)
        .environment(\.locale, Locale(identifier: "fr_FR"))
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
            Text(title)
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
#endif
