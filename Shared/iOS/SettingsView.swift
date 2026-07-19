#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Réglages iPhone (style Réglages Apple, interrupteurs carrés Modernist)

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var path: [IOSRoute]
    @State private var showScan = false
    @State private var importingYAML = false

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Retour")
                            .font(.archivo(13, .semibold))
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Ink.text)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Réglages")
                        .font(.archivo(24, .heavy))
                        .padding(.bottom, 14)

                    // Pictogrammes
                    section("Pictogrammes") {
                        toggleRow("Logos des services",
                                  sub: "dashboard-icons — monogramme en secours",
                                  isOn: $store.logosOn)
                    }

                    // Connexion
                    section("Connexion") {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Tailscale")
                                    .font(.archivo(13.5, .bold))
                                Text(store.net == .tailscale
                                     ? "Connecté via tail1a2b.ts.net — +18 ms"
                                     : "Réseau local détecté")
                                    .font(.archivo(11))
                                    .foregroundStyle(Ink.muted)
                            }
                            Spacer()
                            Rectangle()
                                .fill(store.net == .tailscale ? Ink.accent : Ink.text.opacity(0.25))
                                .frame(width: 10, height: 10)
                        }
                        .padding(.vertical, 10)
                        HRule()
                        toggleRow("Bascule automatique",
                                  sub: "Choisit l'URL locale ou Tailscale selon le réseau",
                                  isOn: $store.tsAuto)
                        HRule()
                        HStack {
                            Text("Simulateur")
                                .font(.archivo(13.5, .bold))
                            Spacer()
                            MSeg(options: [(NetMode.local, "Maison"), (NetMode.tailscale, "Déplacement")],
                                 selection: $store.net)
                        }
                        .padding(.vertical, 10)
                    }

                    // Groupes
                    section("Groupes") {
                        ForEach(Array(store.gOrder.enumerated()), id: \.element) { idx, gi in
                            if idx > 0 { HRule() }
                            HStack(spacing: 8) {
                                Text(store.mainGroups[gi])
                                    .font(.archivo(13.5, .bold))
                                    .foregroundStyle(store.gHidden.contains(gi) ? Ink.muted : Ink.text)
                                Spacer()
                                squareButton("arrow.up", disabled: idx == 0) { store.moveGroup(idx, -1) }
                                squareButton("arrow.down", disabled: idx == store.gOrder.count - 1) { store.moveGroup(idx, 1) }
                                squareButton(store.gHidden.contains(gi) ? "eye.slash" : "eye") {
                                    if store.gHidden.contains(gi) {
                                        store.gHidden.remove(gi)
                                    } else {
                                        store.gHidden.insert(gi)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // Épinglés
                    section("Épinglés", note: "Affichés dans le widget, la barre de menus et sur la Watch — 4 maximum.") {
                        chips(Catalog.services.map(\.id),
                              isOn: { store.pins.contains($0) },
                              toggle: { store.togglePin($0) })
                            .padding(.vertical, 10)
                    }

                    // Alertes
                    section("Alertes") {
                        ForEach(Array(Catalog.alertRules.enumerated()), id: \.element.id) { i, rule in
                            if i > 0 { HRule() }
                            toggleRow(rule.label, sub: rule.desc, isOn: Binding(
                                get: { store.rules[rule.id] ?? false },
                                set: { store.rules[rule.id] = $0 }
                            ))
                        }
                    }

                    // Partage famille
                    section("Partage famille") {
                        toggleRow("Profil invité",
                                  sub: "Accès limité aux services autorisés",
                                  isOn: $store.guestOn)
                        if store.guestOn {
                            HRule()
                            chips(Catalog.guestChoices,
                                  isOn: { store.guestIds.contains($0) },
                                  toggle: { id in
                                      if store.guestIds.contains(id) {
                                          store.guestIds.remove(id)
                                      } else {
                                          store.guestIds.insert(id)
                                      }
                                  })
                                .padding(.vertical, 10)
                            MSecondaryButton(title: "Prévisualiser le profil invité") {
                                store.guestPreview = true
                                path.removeAll()
                                store.fireToast("Aperçu invité — « Quitter » pour revenir")
                            }
                            .padding(.bottom, 10)
                        }
                    }

                    // Configuration
                    section("Configuration", note: "services.yaml (format gethomepage.dev) est la source de vérité.") {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Données")
                                    .font(.archivo(13.5, .bold))
                                Text(store.dataMode == .live
                                     ? "Vraies requêtes vers tes services"
                                     : "Simulation du prototype")
                                    .font(.archivo(11))
                                    .foregroundStyle(Ink.muted)
                            }
                            Spacer()
                            MSeg(options: [(DataMode.demo, "Démo"), (DataMode.live, "Homelab")],
                                 selection: $store.dataMode)
                        }
                        .padding(.vertical, 10)
                        HRule()
                        toggleRow("Synchroniser services.yaml",
                                  sub: "Groupes, widgets et clés API repris tels quels",
                                  isOn: $store.syncOn)
                        HRule()
                        HStack(spacing: 8) {
                            MSecondaryButton(title: "Importer…") { importingYAML = true }
                            MSecondaryButton(title: "Exporter") { store.exportYAML() }
                        }
                        .padding(.vertical, 10)
                        MSecondaryButton(title: "Scanner le réseau (Bonjour)…") { showScan = true }
                            .padding(.bottom, 10)
                    }

                    // Rafraîchissement
                    section("Rafraîchissement") {
                        HStack {
                            Text("Intervalle")
                                .font(.archivo(13.5, .bold))
                            Spacer()
                            MSeg(options: [(800, "0,8 s"), (1600, "1,6 s"), (3200, "3,2 s")],
                                 selection: Binding(get: { store.refreshMs }, set: { store.setRefresh($0) }))
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showScan) { ScanSheet().environment(store) }
        .fileImporter(isPresented: $importingYAML,
                      allowedContentTypes: [.yaml, .plainText, .data]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                store.importYAML(text)
            } else {
                store.fireToast("Import impossible — fichier illisible")
            }
        }
    }

    // MARK: Blocs

    private func section(_ title: String, note: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(title))
                .upperLabel(10.5, .heavy)
                .padding(.bottom, 5)
            HRule(weight: 2)
            content()
            if let note {
                Text(LocalizedStringKey(note))
                    .font(.archivo(10.5))
                    .foregroundStyle(Ink.muted)
                    .padding(.bottom, 10)
            }
        }
        .padding(.bottom, 22)
    }

    private func toggleRow(_ title: String, sub: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(title))
                    .font(.archivo(13.5, .bold))
                Text(LocalizedStringKey(sub))
                    .font(.archivo(11))
                    .foregroundStyle(Ink.muted)
            }
            Spacer()
            MSwitch(isOn: isOn)
        }
        .padding(.vertical, 10)
    }

    private func squareButton(_ symbol: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 30, height: 30)
                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Ink.text)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
    }

    private func chips(_ ids: [String], isOn: @escaping (String) -> Bool, toggle: @escaping (String) -> Void) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(ids, id: \.self) { id in
                let service = Catalog.services.first { $0.id == id }
                let on = isOn(id)
                Button {
                    toggle(id)
                } label: {
                    Text(service?.name ?? id)
                        .font(.archivo(11, .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(on ? Ink.text : .clear)
                        .foregroundStyle(on ? Ink.bg : Ink.text)
                        .overlay(Rectangle().strokeBorder(on ? .clear : Ink.divider, lineWidth: 1))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Flow layout minimal pour les chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (subview, point) in zip(subviews, result.points) {
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var points: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, width: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowH = max(rowH, size.height)
            width = max(width, x - spacing)
        }
        return (CGSize(width: width, height: y + rowH), points)
    }
}
#endif
