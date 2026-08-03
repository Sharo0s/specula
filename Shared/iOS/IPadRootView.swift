#if os(iOS)
import SwiftUI

// MARK: - iPadOS : colonne latérale 212 px + grille de cartes denses
// Mêmes cartes que le Mac ; tap = détail du service, double-tap = interface web.
// Suit le mode sombre, l'ordre/visibilité des groupes et le rafraîchissement.

struct IPadRootView: View {
    @Environment(AppStore.self) private var store
    /// Groupe filtré (nil = tous les services).
    @State private var group: Int?
    /// Feuille des réglages (seul accès à la config sur iPad).
    @State private var showSettings = false
    /// Service dont le détail est ouvert en feuille (tap simple sur une carte).
    @State private var detail: Service?
    /// SettingsView attend un chemin de navigation ; en feuille il reste local.
    @State private var settingsPath: [IOSRoute] = []

    var body: some View {
        VStack(spacing: 0) {
            header
            HRule(weight: 2)
            HStack(spacing: 0) {
                sidebar
                    .frame(width: 212)
                VRule(weight: 2)
                grid
            }
        }
        .background(Ink.bg)
        .sheet(isPresented: $showSettings) {
            // Feuille pleine page : la taille par défaut (~540 pt) laisse les
            // réglages en une seule colonne alors que l'écran en tient deux.
            SettingsView(path: $settingsPath)
                .environment(store)
                .presentationSizing(.page)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 9) {
            BrandSquare(size: 14)
            Text("Specula")
                .font(.archivo(17, .heavy))
            if store.dataMode == .demo {
                Text("DÉMO")
                    .font(.archivo(8, .heavy))
                    .tracking(0.4)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Ink.accent2Bg)
                    .foregroundStyle(Ink.accent2Text)
            }
            Spacer()
            Text(String(localized: "\(store.onlineCount) en ligne \(netNote)· CPU \(store.cpuText) · \(Date.now.formatted(.dateTime.hour().minute()))"))
                .font(.archivo(11)).monospacedDigit()
                .foregroundStyle(Ink.muted)
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 32, height: 30)
                    .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Ink.text)
            .accessibilityLabel("Réglages")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var netNote: String {
        store.net == .tailscale ? String(localized: "· via Tailscale ") : ""
    }

    // MARK: Colonne latérale

    private var sidebar: some View {
        VStack(spacing: 2) {
            sideItem("Tous les services", meta: "\(store.totalCount)", active: group == nil) {
                group = nil
            }
            ForEach(store.visibleGroups(of: Catalog.mainServer), id: \.index) { g in
                sideItem(g.name,
                         meta: String(format: "%02d", g.services.count),
                         active: group == g.index) {
                    group = g.index
                }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Ink.surface)
    }

    private func sideItem(_ label: String, meta: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey(label))
                    .font(.archivo(12.5, active ? .heavy : .semibold))
                    .lineLimit(1)
                Spacer()
                Text(meta)
                    .font(.archivo(10.5)).monospacedDigit()
                    .opacity(0.55)
            }
            .padding(8)
            .background(active ? Ink.text : .clear)
            .foregroundStyle(active ? Ink.bg : Ink.text)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: Grille

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groups, id: \.index) { g in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            Text(LocalizedStringKey(g.name))
                                .upperLabel(11, .heavy)
                            Text(String(format: "%02d", g.services.count))
                                .font(.archivo(10.5)).monospacedDigit()
                                .foregroundStyle(Ink.muted)
                            HRule(weight: 2)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 235), spacing: 14, alignment: .topLeading)],
                                  alignment: .leading, spacing: 14) {
                            ForEach(g.services) { s in
                                ServiceCard(service: s,
                                            onOpen: { store.openWeb(s) }) { detail = s }
                            }
                        }
                    }
                }
            }
            .padding(18)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        // Feuille portée par la grille, pas par la vue racine : celle-ci
        // présente déjà les réglages (deux présentations sur la même vue
        // s'annulent).
        .sheet(item: $detail) { s in
            ServiceDetailView(service: s).environment(store)
        }
    }

    private var groups: [(index: Int, name: String, services: [Service])] {
        store.visibleGroups(of: Catalog.mainServer).filter { group == nil || $0.index == group }
    }
}
#endif
