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
    @State private var exportingYAML = false
    @State private var exportChoice = false
    @State private var exportDoc: YAMLDocument?
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
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

            // iPad : deux colonnes dès que la feuille est assez large ;
            // sur iPhone la pile reste la seule mise en page possible.
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Réglages")
                            .font(.archivo(24, .heavy))
                            .padding(.bottom, 14)
                        if geo.size.width > 820 {
                            HStack(alignment: .top, spacing: 26) {
                                VStack(alignment: .leading, spacing: 0) { columnA }
                                VStack(alignment: .leading, spacing: 0) { columnB }
                            }
                        } else {
                            columnA
                            columnB
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showScan) { ScanSheet().environment(store) }
    }

    // MARK: Colonnes (empilées sur iPhone, côte à côte sur iPad)

    @ViewBuilder private var columnA: some View {
        @Bindable var store = store
        // Pictogrammes
        section("Pictogrammes") {
            toggleRow("Logos des services",
                      sub: "dashboard-icons — monogramme en secours",
                      isOn: $store.logosOn)
            HRule()
            toggleRow("Bandeau système",
                      sub: "CPU, température et RAM — nécessite une source Glances.",
                      isOn: $store.showSystemBand)
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
            chips(store.mainServices.map(\.id),
                  isOn: { store.pins.contains($0) },
                  toggle: { store.togglePin($0) })
                .padding(.vertical, 10)
        }
    }

    @ViewBuilder private var columnB: some View {
        @Bindable var store = store
        // Alertes
        section("Alertes") {
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

        // Partage famille
        section("Partage famille") {
            toggleRow("Profil invité",
                      sub: "Accès limité aux services autorisés",
                      isOn: $store.guestOn)
            if store.guestOn {
                HRule()
                chips(store.mainServices.map(\.id),
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
                    store.fireToast(String(localized: "Aperçu invité — « Quitter » pour revenir"))
                }
                .padding(.bottom, 10)
            }
        }

        // Configuration
        section("Configuration", note: "services.yaml est ta source de vérité (import et export).") {
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
                MSecondaryButton(title: "Exporter") { exportChoice = true }
            }
            .padding(.vertical, 10)
            // Le fichier emporte les clés en clair si on le lui demande : le
            // choix se fait avant la feuille d'enregistrement, pas après.
            .confirmationDialog("Exporter services.yaml", isPresented: $exportChoice,
                                titleVisibility: .visible) {
                Button("Avec les clés API") { prepareExport(includeKeys: true) }
                Button("Sans les clés") { prepareExport(includeKeys: false) }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Avec les clés, le fichier suffit à rejouer la configuration ailleurs — et se range comme un secret. Sans elles, les clés sont remplacées par des variables Homepage.")
            }
            .fileExporter(isPresented: $exportingYAML, document: exportDoc,
                          // « services » seul donnerait services.yml : l'extension
                          // préférée du type système. Or tout, ici et chez
                          // gethomepage, s'appelle services.yaml.
                          contentType: .yaml, defaultFilename: "services.yaml") { result in
                if case .success = result {
                    store.fireToast(String(localized: "services.yaml enregistré"))
                } else {
                    store.fireToast(String(localized: "Export impossible"))
                }
            }
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
            MSecondaryButton(title: "Scanner le réseau (Bonjour)…") { showScan = true }
                .padding(.bottom, 10)
            MSecondaryButton(title: "Revoir l'introduction") {
                path.removeAll()
                hasOnboarded = false
            }
            .padding(.bottom, 10)
        }

        // Langue
        section("Langue", note: "Relance l'app pour appliquer partout.") {
            // Six segments ne tiennent plus sur une ligne d'iPhone : libellé au-dessus
            // et défilement horizontal plutôt qu'un rognage silencieux.
            VStack(alignment: .leading, spacing: 8) {
                Text("Langue")
                    .font(.archivo(13.5, .bold))
                ScrollView(.horizontal, showsIndicators: false) {
                    MSeg(options: AppLanguage.segments,
                         selection: $store.appLanguage, fontSize: 9.5)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(.vertical, 10)
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

    private func prepareExport(includeKeys: Bool) {
        guard let text = store.exportYAMLText(includeKeys: includeKeys) else { return }
        exportDoc = YAMLDocument(text: text)
        exportingYAML = true
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
                let service = store.mainServices.first { $0.id == id }
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

/// Enveloppe minimale pour `fileExporter` — le contenu est déjà du texte, seul
/// le type déclaré compte pour que la feuille propose « services.yaml ».
struct YAMLDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.yaml]
    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
#endif
