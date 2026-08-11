#if os(iOS)
import SwiftUI

// MARK: - Détail service iPhone

struct ServiceDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let service: Service
    @State private var metric: DetailMetric = .lat
    /// Feuille d'édition du service.
    @State private var showEdit = false
    /// Suppression en deux temps — pas de dialogue système.
    @State private var confirmDelete = false

    var body: some View {
        VStack(spacing: 0) {
            // Retour
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.backward")
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
                    identity
                    HRule(weight: 2).padding(.top, 14)
                    chart
                    HRule(weight: 2)
                    metricsGrid
                    nowPlayingBlock
                    journal
                    actions
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
        .onChange(of: service.id) { confirmDelete = false }
        .sheet(isPresented: $showEdit) { EditServiceSheet(service: service).environment(store) }
    }

    private var isDown: Bool { store.isDown(service) }

    // MARK: Identité

    private var identity: some View {
        HStack(alignment: .top, spacing: 14) {
            ServiceTile(service: service, size: 54, down: isDown)
            VStack(alignment: .leading, spacing: 3) {
                Text(service.name)
                    .font(.archivo(24, .heavy))
                Text(store.statusText(service))
                    .upperLabel(10, .heavy)
                    .monospacedDigit()
                    .foregroundStyle(isDown ? Ink.accentText : Ink.text)
                Text(store.fullURL(service))
                    .font(.archivo(11))
                    .foregroundStyle(Ink.muted)
            }
        }
    }

    // MARK: Graphe

    private var chart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                MSeg(options: DetailMetric.allCases.map { ($0, $0.label) }, selection: $metric)
                Spacer()
                Text(store.bigValue(service, metric: metric))
                    .font(.archivo(24, .heavy))
                    .monospacedDigit()
                    .foregroundStyle(isDown && metric == .lat ? Ink.accentText : Ink.text)
            }
            BarChart(values: store.bars(service.id, metric: metric),
                     color: isDown && metric == .lat ? Ink.accent : Ink.text)
                .frame(height: 96)
            HStack {
                Text(verbatim: metric == .lat ? "-64 s" : "-24 h")
                Spacer()
                Text("maintenant")
            }
            .font(.archivo(8.5))
            .foregroundStyle(Ink.muted)
        }
        .padding(.vertical, 14)
    }

    // MARK: Grille 2 colonnes — 2 rangées d'ordinaire, 3 si l'intégration
    // rend plus de trois métriques (OpenMediaVault, Nextcloud…).

    private var metricsGrid: some View {
        let m = store.metrics(service)
        let cells: [[String]] = m + [[store.availability(service), "Dispo. 30 j"]]
        return VStack(alignment: .leading, spacing: 12) {
            if m.isEmpty && store.needsAPIKey(service) {
                VStack(alignment: .leading, spacing: 3) {
                    KeyRequiredNote()
                    Text(LiveFetcher.keyHint(for: store.type(of: service)) ?? "")
                        .font(.archivo(11))
                        .foregroundStyle(Ink.muted)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .topLeading),
                                GridItem(.flexible(), alignment: .topLeading)],
                      alignment: .leading, spacing: 16) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    MetricCell(value: cell[0], label: cell[1])
                }
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: Lecture en cours (Jellyfin)

    @ViewBuilder
    private var nowPlayingBlock: some View {
        if let sessions = store.nowPlaying[service.id], !sessions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(sessions.prefix(3)), id: \.self) { session in
                    NowPlayingRow(session: session) {
                        store.togglePause(service, session: session)
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: Journal

    private var journal: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Journal du conteneur")
                .upperLabel(9, .heavy)
                .foregroundStyle(Ink.muted)
            ConsoleLog(lines: isDown
                       ? [String(localized: "ERROR Connexion refusée (timeout après 5 000 ms)"),
                          String(localized: "ERROR 3 tentatives échouées — abandon"),
                          String(localized: "INFO  Prochaine tentative dans 30 s")]
                       : store.logs)
        }
        .padding(.bottom, 16)
    }

    // MARK: Actions

    // Mêmes actions que le panneau de détail du Mac : le redémarrage ne dépend
    // pas de l'état du service, et l'édition/suppression n'ont de sens qu'en
    // mode live (la démo travaille sur un catalogue figé).

    private var actions: some View {
        VStack(spacing: 8) {
            MPrimaryButton(title: "Ouvrir l'interface web") { store.openWeb(service) }
            MSecondaryButton(title: "Copier l'URL") { store.copyURL(service) }
            MSecondaryButton(title: "Redémarrer le conteneur") { store.restart(service) }
            if store.dataMode == .live {
                MSecondaryButton(title: "Modifier…") { showEdit = true }
                // Suppression en deux temps — pas de dialogue système
                Button {
                    if confirmDelete {
                        store.removeService(service)
                        // Le service n'existe plus : la vue de détail sortirait
                        // sur une fiche fantôme.
                        dismiss()
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
    }
}
#endif
