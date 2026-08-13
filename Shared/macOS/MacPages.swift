#if os(macOS)
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Notifications (page mac)

struct MacNotificationsPage: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        store.markAllRead()
                    } label: {
                        Text("Tout lire")
                            .font(.archivo(12, .heavy))
                            .foregroundStyle(Ink.accentText)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 6)
                HRule(weight: 2)
                VStack(spacing: 0) {
                    ForEach(Array(store.notifs.enumerated()), id: \.element.id) { i, n in
                        if i > 0 { HRule() }
                        HStack(alignment: .top, spacing: 12) {
                            Rectangle()
                                .fill(n.alert ? Ink.accent : Ink.text)
                                .frame(width: 10, height: 10)
                                .padding(.top, 4)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(n.title).font(.archivo(13, .bold))
                                Text(n.sub).font(.archivo(11)).foregroundStyle(Ink.muted)
                            }
                            Spacer()
                            Text(n.timeLabel)
                                .font(.archivo(10)).monospacedDigit()
                                .foregroundStyle(Ink.muted)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(n.unread ? Ink.unreadBg : .clear)
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Réglages (page mac)

struct MacSettingsPage: View {
    @Environment(AppStore.self) private var store
    @State private var showScan = false
    @State private var importingYAML = false
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        @Bindable var store = store
        ScrollView {
            HStack(alignment: .top, spacing: 26) {
                VStack(alignment: .leading, spacing: 26) {
                    settingsBlock("Affichage") {
                        labelRow("Densité") {
                            MSeg(options: [(Density.aere, "Aéré"), (Density.compact, "Compact")], selection: $store.density)
                        }
                        HRule()
                        labelRow("Disposition") {
                            MSeg(options: [(LayoutMode.grille, "Grille"), (LayoutMode.liste, "Liste")], selection: $store.layout)
                        }
                        HRule()
                        toggleRow("Logos des services", sub: "dashboard-icons — monogramme en secours", isOn: $store.logosOn)
                        HRule()
                        toggleRow("Bandeau système", sub: "CPU, température et RAM — nécessite une source Glances.", isOn: $store.showSystemBand)
                    }

                    settingsBlock("Démarrage") {
                        toggleRow("Démarrer avec le Mac",
                                  sub: "Specula s'ouvre à l'ouverture de session, sans fenêtre.",
                                  isOn: Binding(get: { store.startsAtLogin },
                                                set: { store.setStartsAtLogin($0) }))
                        HRule()
                        toggleRow("Rester dans la barre de menus",
                                  sub: "Pas d'icône au Dock ; fermer la fenêtre n'arrête pas la surveillance.",
                                  isOn: $store.menuBarOnly)
                    }

                }
                .frame(maxWidth: 420, alignment: .leading)
                VStack(alignment: .leading, spacing: 26) {
                    settingsBlock("Services") {
                        QuotaBanner(showsUnlimited: true)
                            .padding(.vertical, 10)
                        Text("Les 4 premiers services sont offerts. Une place achetée reste acquise : supprimer un service la libère pour un autre.")
                            .font(.archivo(11))
                            .foregroundStyle(Ink.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 10)
                        // Pas de bouton en plus : le bandeau porte déjà
                        // « Débloquer ».
                    }

                    settingsBlock("Alertes") {
                        ForEach(Array(Catalog.alertRules.enumerated()), id: \.element.id) { i, rule in
                            if i > 0 { HRule() }
                            toggleRow(rule.label, sub: rule.desc, isOn: Binding(
                                get: { store.rules[rule.id] ?? false },
                                set: { store.setRule(rule.id, $0) }
                            ))
                        }
                        // Un montage plein par nature (archives figées) rejouerait
                        // l'alerte à chaque lancement : on le décoche ici.
                        if !store.monitoredVolumes.isEmpty {
                            HRule()
                            Text("Volumes surveillés")
                                .upperLabel(8.5, .heavy)
                                .foregroundStyle(Ink.muted)
                                .padding(.top, 10)
                            ForEach(store.monitoredVolumes, id: \.service.id) { entry in
                                ForEach(entry.fills, id: \.id) { v in
                                    volumeRow(entry.service, v)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 420, alignment: .leading)
                VStack(alignment: .leading, spacing: 26) {
                    settingsBlock("Configuration") {
                        labelRow("Données") {
                            MSeg(options: [(DataMode.demo, "Démo"), (DataMode.live, "Homelab")],
                                 selection: $store.dataMode)
                        }
                        HRule()
                        toggleRow("Synchroniser services.yaml",
                                  sub: "Format services.yaml — source de vérité",
                                  isOn: $store.syncOn)
                        HRule()
                        // Colonne de 420 pt : les boutons se partagent la largeur
                        // plutôt que de déborder sur des largeurs fixes.
                        HStack(spacing: 8) {
                            MSecondaryButton(title: "Importer…") { importingYAML = true }
                                .frame(maxWidth: .infinity)
                                .fileImporter(isPresented: $importingYAML,
                                              allowedContentTypes: [.yaml, .plainText, .data]) { result in
                                    guard case .success(let url) = result else { return }
                                    let scoped = url.startAccessingSecurityScopedResource()
                                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                                    if let text = try? String(contentsOf: url, encoding: .utf8) {
                                        store.importYAML(text)
                                    } else {
                                        store.fireToast(String(localized: "Import impossible — fichier illisible"))
                                    }
                                }
                            MSecondaryButton(title: "Exporter") { store.exportYAMLToFile() }
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 10)
                        MSecondaryButton(title: "Scanner le réseau…") { showScan = true }
                            .padding(.bottom, 10)
                        HRule()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Revoir le tutoriel de premier lancement.")
                                .font(.archivo(11))
                                .foregroundStyle(Ink.muted)
                            MSecondaryButton(title: "Revoir l'introduction") { hasOnboarded = false }
                        }
                        .padding(.vertical, 10)
                    }

                    settingsBlock("Langue") {
                        // Six segments ne tiennent pas à côté du libellé dans la
                        // colonne de 420 pt : le sélecteur prend sa propre ligne.
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Langue").font(.archivo(13.5, .bold))
                            MSeg(options: AppLanguage.segments,
                                 selection: $store.appLanguage, fontSize: 10)
                        }
                        .padding(.vertical, 10)
                        HRule()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Relance l'app pour appliquer partout.")
                                .font(.archivo(11))
                                .foregroundStyle(Ink.muted)
                            MSecondaryButton(title: "Relancer maintenant") { store.relaunch() }
                        }
                        .padding(.vertical, 10)
                    }

                    settingsBlock("Rafraîchissement") {
                        labelRow("Intervalle") {
                            MSeg(options: [(800, "0,8 s"), (1600, "1,6 s"), (3200, "3,2 s")],
                                 selection: Binding(get: { store.refreshMs }, set: { store.setRefresh($0) }))
                        }
                    }
                }
                .frame(maxWidth: 420, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(20)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showScan) { ScanSheet().environment(store) }
    }

    private func settingsBlock(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(title))
                .upperLabel(10.5, .heavy)
                .padding(.bottom, 5)
            HRule(weight: 2)
            content()
        }
    }

    private func labelRow(_ title: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack {
            Text(LocalizedStringKey(title)).font(.archivo(13.5, .bold))
            Spacer()
            trailing()
        }
        .padding(.vertical, 10)
    }

    /// Libellés dynamiques (nom de service, device, point de montage) : pas de
    /// LocalizedStringKey ici, ces chaînes viennent du serveur.
    private func volumeRow(_ s: Service, _ v: LiveFetcher.VolumeFill) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(s.name) — \(v.label)").font(.archivo(12.5, .bold))
                Text("\(v.mount) · \(v.percent) %")
                    .font(.archivo(10.5))
                    .foregroundStyle(v.percent > 90 ? Ink.accent2Text : Ink.muted)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            MSwitch(isOn: Binding(
                get: { !store.mutedVolumes.contains(store.volumeKey(s.id, v.id)) },
                set: { store.setVolumeMonitored(s.id, v.id, $0) }
            ), width: 36, height: 22)
        }
        .padding(.vertical, 7)
    }

    private func toggleRow(_ title: String, sub: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(title)).font(.archivo(13.5, .bold))
                Text(LocalizedStringKey(sub)).font(.archivo(11)).foregroundStyle(Ink.muted)
            }
            Spacer()
            MSwitch(isOn: isOn, width: 36, height: 22)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Ajouter un service (page mac)

struct MacAddServicePage: View {
    @Environment(AppStore.self) private var store
    @Bindable var ui: MacUIState
    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
    @State private var group = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                QuotaBanner()
                field("Nom", text: $name, placeholder: "Jellyfin")
                field("URL", text: $url, placeholder: "http://jellyfin.local:8096")
                field("Clé API (optionnelle — rangée dans le Keychain)", text: $apiKey, placeholder: "")
                VStack(alignment: .leading, spacing: 5) {
                    Text("Groupe")
                        .font(.archivo(12))
                        .foregroundStyle(Ink.text.opacity(0.7))
                    MSeg(options: Array(store.mainGroups.enumerated()).map { ($0.offset, $0.element) },
                         selection: $group, fontSize: 10)
                }
                Text("Détection automatique du type de service à la connexion.")
                    .font(.archivo(11))
                    .foregroundStyle(Ink.muted)
                HStack(spacing: 8) {
                    MPrimaryButton(title: "Ajouter le service") {
                        // Refus faute de place : on reste sur le formulaire, la
                        // boutique s'ouvre par-dessus et la saisie est
                        // toujours là au retour.
                        if store.addService(name: name.isEmpty ? "Nouveau service" : name,
                                            url: url, group: group, apiKey: apiKey) {
                            ui.view = .dash
                        }
                    }
                    .frame(width: 220)
                    MSecondaryButton(title: "Tester la connexion") {
                        store.testConnection(url: url)
                    }
                    .frame(width: 220)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: 480, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedStringKey(label))
                .font(.archivo(12))
                .foregroundStyle(Ink.text.opacity(0.7))
            TextField(LocalizedStringKey(placeholder), text: text)
                .textFieldStyle(.plain)
                .font(.archivo(14))
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(Ink.surface)
                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
        }
    }
}
#endif
