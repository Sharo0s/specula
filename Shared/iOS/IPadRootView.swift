#if os(iOS)
import SwiftUI

// MARK: - iPadOS : colonne latérale 212 px + grille de cartes denses
// Mêmes cartes que le Mac ; tap = ouvre l'interface web.
// Suit le mode sombre, l'ordre/visibilité des groupes et le rafraîchissement.

struct IPadRootView: View {
    @Environment(AppStore.self) private var store
    /// Groupe filtré (nil = tous les services).
    @State private var group: Int?

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
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 9) {
            BrandSquare(size: 14)
            Text("Specula")
                .font(.archivo(17, .heavy))
            Spacer()
            Text(String(localized: "\(store.onlineCount) en ligne \(netNote)· CPU \(store.cpuText) · \(Date.now.formatted(.dateTime.hour().minute()))"))
                .font(.archivo(11)).monospacedDigit()
                .foregroundStyle(Ink.muted)
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
                                ServiceCard(service: s) { store.openWeb(s) }
                            }
                        }
                    }
                }
            }
            .padding(18)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
    }

    private var groups: [(index: Int, name: String, services: [Service])] {
        store.visibleGroups(of: Catalog.mainServer).filter { group == nil || $0.index == group }
    }
}
#endif
