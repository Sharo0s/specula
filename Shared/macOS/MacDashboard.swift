#if os(macOS)
import SwiftUI

// MARK: - Dashboard macOS : bandeau 5 cellules + cartes par groupe + inspecteur 312 px

struct MacDashboard: View {
    @Environment(AppStore.self) private var store
    @Bindable var ui: MacUIState
    @State private var showScan = false

    private var pad: CGFloat { store.density == .compact ? 9 : 14 }
    private var gap: CGFloat { store.density == .compact ? 10 : 16 }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    systemBand
                    if store.services.isEmpty {
                        emptyState
                    }
                    ForEach(groups, id: \.index) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            GroupHeader(name: group.name, count: group.services.count)
                                .padding(.top, 20)
                            if store.layout == .grille {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 236), spacing: gap, alignment: .topLeading)],
                                          alignment: .leading, spacing: gap) {
                                    ForEach(group.services) { s in
                                        ServiceCard(service: s, pad: pad,
                                                    selected: ui.selection == s.id) {
                                            ui.selection = s.id
                                        }
                                    }
                                }
                                .padding(.top, 12)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(group.services.enumerated()), id: \.element.id) { i, s in
                                        if i > 0 { HRule() }
                                        MacServiceRow(service: s, selected: ui.selection == s.id) {
                                            ui.selection = s.id
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)

            if let sel = selectedService {
                VRule(weight: 2)
                MacInspector(service: sel)
                    .frame(width: 312)
            }
        }
    }

    private var groups: [(index: Int, name: String, services: [Service])] {
        store.visibleGroups().filter { ui.group == nil || $0.index == ui.group }
    }

    // MARK: État vide (mode Homelab sans services configurés)

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Aucun service configuré")
                .font(.archivo(19, .heavy))
            Text("Mode Homelab : Specula n'interroge que tes services. Importe ta config gethomepage ou scanne le réseau pour commencer.")
                .font(.archivo(12.5))
                .foregroundStyle(Ink.muted)
                .frame(maxWidth: 420, alignment: .leading)
            HStack(spacing: 8) {
                MPrimaryButton(title: "Importer services.yaml…") { ui.view = .settings }
                    .frame(width: 230)
                MSecondaryButton(title: "Scanner le réseau…") { showScan = true }
                    .frame(width: 200)
                MSecondaryButton(title: "Ajouter à la main") { ui.view = .add }
                    .frame(width: 180)
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 40)
        .sheet(isPresented: $showScan) { ScanSheet().environment(store) }
    }

    private var selectedService: Service? {
        guard let id = ui.selection else { return nil }
        return store.services.first { $0.id == id }
    }

    // MARK: Bandeau 5 cellules avec mini-barres

    private var systemBand: some View {
        // En live sans source Glances configurée : « — », pas de barres.
        let hasSystem = store.dataMode == .demo || store.systemLive
        let hasNet = store.dataMode == .demo
        return VStack(spacing: 0) {
            HRule(weight: 2)
            HStack(spacing: 0) {
                bandCell(store.cpuText, "CPU", progress: hasSystem ? store.cpu / 100 : nil)
                VRule()
                bandCell(store.tempLongText, "Température", progress: hasSystem ? store.temp / 70 : nil)
                VRule()
                bandCell(store.ramLongText, "RAM libre", progress: hasSystem ? store.ram / 16 : nil)
                VRule()
                bandCell(store.rxText, "Réception", progress: hasNet ? store.rx / 3.2 : nil)
                VRule()
                bandCell(store.txText, "Envoi", progress: hasNet ? store.tx / 0.9 : nil)
            }
            HRule(weight: 2)
        }
    }

    private func bandCell(_ value: String, _ label: String, progress: Double?) -> some View {
        SystemBandCell(value: value, label: label, progress: progress)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
    }
}

// MARK: - Rangée service (disposition liste)

struct MacServiceRow: View {
    @Environment(AppStore.self) private var store
    let service: Service
    let selected: Bool
    let select: () -> Void

    var body: some View {
        let down = store.isDown(service)
        Button(action: select) {
            HStack(spacing: 12) {
                ServiceTile(service: service, size: 30, down: down)
                Text(service.name)
                    .font(.archivo(13.5, .heavy))
                    .foregroundStyle(down ? Ink.accentText : Ink.text)
                Text(LocalizedStringKey(service.desc))
                    .font(.archivo(11))
                    .foregroundStyle(Ink.muted)
                Spacer()
                ForEach(Array(store.metrics(service).prefix(3).enumerated()), id: \.offset) { _, m in
                    HStack(spacing: 4) {
                        Text(m[0]).font(.archivo(12, .heavy)).monospacedDigit()
                        Text(LocalizedStringKey(m[1])).upperLabel(7.5).foregroundStyle(Ink.muted)
                    }
                    .frame(minWidth: 76, alignment: .leading)
                }
                LatencyTag(text: store.pingText(service), down: down)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(selected ? Ink.surface : .clear)
            .overlay(Rectangle().strokeBorder(selected ? Ink.accent : .clear, lineWidth: 2))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Inspecteur 312 px

struct MacInspector: View {
    @Environment(AppStore.self) private var store
    let service: Service
    @State private var metric: DetailMetric = .lat
    @State private var confirmDelete = false

    var body: some View {
        let down = store.isDown(service)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Identité
                HStack(alignment: .top, spacing: 12) {
                    ServiceTile(service: service, size: 44, down: down)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.name)
                            .font(.archivo(17, .heavy))
                        Text(store.statusText(service))
                            .upperLabel(8.5, .heavy)
                            .monospacedDigit()
                            .foregroundStyle(down ? Ink.accentText : Ink.text)
                        Text(store.fullURL(service))
                            .font(.archivo(10))
                            .foregroundStyle(Ink.muted)
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 14)
                HRule(weight: 2)

                // Graphes
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        MSeg(options: DetailMetric.allCases.map { ($0, $0.label) }, selection: $metric, fontSize: 9)
                        Spacer()
                    }
                    HStack(alignment: .bottom) {
                        BarChart(values: store.bars(service.id, metric: metric),
                                 color: down && metric == .lat ? Ink.accent : Ink.text)
                            .frame(height: 64)
                        Text(store.bigValue(service, metric: metric))
                            .font(.archivo(19, .heavy))
                            .monospacedDigit()
                            .foregroundStyle(down && metric == .lat ? Ink.accentText : Ink.text)
                    }
                }
                .padding(.vertical, 12)
                HRule(weight: 2)

                // Tableau de métriques
                VStack(spacing: 0) {
                    ForEach(Array(store.metrics(service).enumerated()), id: \.offset) { i, m in
                        if i > 0 { HRule() }
                        HStack {
                            Text(LocalizedStringKey(m[1]))
                                .upperLabel(8.5)
                                .foregroundStyle(Ink.muted)
                            Spacer()
                            Text(m[0])
                                .font(.archivo(13, .heavy)).monospacedDigit()
                        }
                        .padding(.vertical, 7)
                    }
                }
                .padding(.vertical, 6)
                HRule(weight: 2)

                // Journal
                Text("Journal")
                    .upperLabel(8.5, .heavy)
                    .foregroundStyle(Ink.muted)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                ConsoleLog(lines: down
                           ? [String(localized: "ERROR Connexion refusée (timeout après 5 000 ms)"),
                              String(localized: "ERROR 3 tentatives échouées — abandon"),
                              String(localized: "INFO  Prochaine tentative dans 30 s")]
                           : store.logs)

                // Actions empilées
                VStack(spacing: 6) {
                    MPrimaryButton(title: "Ouvrir l'interface web") { store.openWeb(service) }
                    MSecondaryButton(title: "Copier l'URL") { store.copyURL(service) }
                    MSecondaryButton(title: "Redémarrer le conteneur") { store.restart(service) }
                    if store.dataMode == .live {
                        // Suppression en deux temps — pas de dialogue système
                        Button {
                            if confirmDelete {
                                store.removeService(service)
                            } else {
                                confirmDelete = true
                            }
                        } label: {
                            Text(confirmDelete ? "Confirmer la suppression" : "Supprimer le service")
                                .font(.archivo(14, .heavy))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(confirmDelete ? Ink.accent : .clear)
                                .foregroundStyle(confirmDelete ? .white : Ink.accentText)
                                .overlay(Rectangle().strokeBorder(
                                    confirmDelete ? .clear : Ink.accentRing, lineWidth: 1))
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 14)
            }
            .padding(16)
        }
        .background(Ink.bg)
        .onChange(of: service.id) { confirmDelete = false }
    }
}
#endif
