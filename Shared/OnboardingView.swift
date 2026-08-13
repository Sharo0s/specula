import SwiftUI
#if os(iOS) || os(macOS)
import UniformTypeIdentifiers

// MARK: - Onboarding / tutoriel de premier lancement (iPhone · iPad · Mac)
// Transforme l'ouverture (mode Démo, config vierge) en un vrai parcours Homelab.
// Voies : Scanner (recommandé, zéro prérequis) ou Importer un services.yaml (filet
// si le scan ne trouve rien). Étape clés API optionnelle. Sortie « démo » possible.

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    /// Marque l'onboarding comme terminé (persisté par l'appelant).
    let done: () -> Void

    private enum Step { case welcome, method, netPermission, importStep, scanStep, keysStep, ready }
    @State private var step: Step = .welcome

    @State private var importing = false
    @State private var added: Set<String> = []
    @State private var keyInputs: [String: String] = [:]
    @State private var userInputs: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            HRule(weight: 2).padding(.horizontal, hPad)
            content
                .frame(maxWidth: 540, maxHeight: .infinity, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(hPad)
        }
        .background(Ink.bg)
        .onDisappear { store.scanner.stop() }
    }

    private let hPad: CGFloat = 24

    // MARK: En-tête + marqueur d'étape

    private var stepLabel: String {
        switch step {
        case .welcome: "1 — Bienvenue"
        case .method, .netPermission, .importStep, .scanStep, .keysStep: "2 — Tes services"
        case .ready: "3 — Prêt"
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            BrandSquare()
            Text("Specula").font(.archivo(16, .heavy))
            Spacer()
            Text(LocalizedStringKey(stepLabel))
                .upperLabel(9, .bold)
                .foregroundStyle(Ink.muted)
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, 16)
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .welcome: welcome
        case .method: method
        case .netPermission: netPermission
        case .importStep: importStep
        case .scanStep: scanStep
        case .keysStep: keysStep
        case .ready: ready
        }
    }

    // MARK: 1 — Bienvenue

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Rectangle().fill(Ink.accent).frame(width: 44, height: 44)
                .padding(.bottom, 24)
            Text("Ton homelab,\nen un coup d'œil.")
                .font(.archivo(34, .heavy))
                .lineSpacing(2)
                .padding(.bottom, 12)
            Text("Tes services self-hosted, leurs métriques en direct et les pannes qui comptent.")
                .font(.archivo(13))
                .foregroundStyle(Ink.muted)
                .padding(.bottom, 32)
            MPrimaryButton(title: "Configurer mon homelab") {
                store.switchToLive()
                step = .method
            }
            .padding(.bottom, 4)
            Button { done() } label: {
                Text("Explorer la démo d'abord")
                    .font(.archivo(12.5, .bold))
                    .foregroundStyle(Ink.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: 2 — Choisir la méthode

    private var method: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Comment ajouter\ntes services ?")
                .font(.archivo(24, .heavy))
                .padding(.bottom, 6)
            Text("Trois façons de commencer. Tu pourras toujours en ajouter d'autres après.")
                .font(.archivo(12.5))
                .foregroundStyle(Ink.muted)
                .padding(.bottom, 18)

            methodRow("Scanner le réseau",
                      "Rien à préparer — détecte tes services automatiquement.",
                      recommended: true) {
                #if os(iOS)
                step = .netPermission
                #else
                store.scanner.start()
                step = .scanStep
                #endif
            }
            .padding(.bottom, 10)
            methodRow("Importer services.yaml",
                      "Tu en as déjà un ? Choisis-le dans les fichiers ou reçois-le par AirDrop.",
                      recommended: false) { importing = true }
                .padding(.bottom, 10)
            methodRow("Ajouter à la main",
                      "Une URL, un nom. Pour un service à la fois.",
                      recommended: false) { done() }
            Spacer()
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.yaml, .plainText, .data]) { handleImport($0) }
    }

    private func methodRow(_ title: String, _ sub: String, recommended: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(LocalizedStringKey(title)).font(.archivo(13.5, .heavy))
                        if recommended {
                            Text("Recommandé")
                                .font(.archivo(8, .heavy))
                                .textCase(.uppercase)
                                .tracking(0.4)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Ink.accent2Bg)
                                .foregroundStyle(Ink.accent2Text)
                        }
                    }
                    Text(LocalizedStringKey(sub))
                        .font(.archivo(11))
                        .foregroundStyle(Ink.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Text("→").font(.archivo(15, .heavy)).foregroundStyle(Ink.muted)
            }
            .padding(13)
            .overlay(Rectangle().strokeBorder(recommended ? Ink.text : Ink.divider,
                                              lineWidth: recommended ? 2 : 1))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Ink.text)
    }

    // MARK: 2b — Autorisation réseau local (iOS uniquement)

    @ViewBuilder private var netPermission: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 0) {
            Text("Autorise le\nréseau local")
                .font(.archivo(24, .heavy))
                .padding(.bottom, 10)
            Text("Specula interroge tes services directement chez toi. iOS va te demander l'accès à ton réseau local — sans lui, impossible de scanner ni de contacter tes machines.")
                .font(.archivo(13))
                .foregroundStyle(Ink.muted)
            Spacer()
            VStack(alignment: .leading, spacing: 6) {
                Text("« Specula » souhaite trouver et se connecter aux appareils de ton réseau local")
                    .font(.archivo(12.5, .heavy))
                Text("Une alerte système va s'afficher au lancement du scan. Touche « Autoriser » pour continuer.")
                    .font(.archivo(11))
                    .foregroundStyle(Ink.muted)
            }
            .padding(14)
            .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
            .padding(.bottom, 20)
            MPrimaryButton(title: "Lancer le scan") {
                store.scanner.start()
                step = .scanStep
            }
        }
        #else
        EmptyView()
        #endif
    }

    // MARK: 2c — Import services.yaml (confirmation)

    private var importStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Config importée")
                .font(.archivo(24, .heavy))
                .padding(.bottom, 6)
            HStack(spacing: 7) {
                Text("✓").font(.archivo(9, .heavy)).foregroundStyle(.white)
                    .frame(width: 15, height: 15).background(Ink.accent2)
                Text("\(store.mainServices.count) services · \(store.mainGroups.count) groupes · \(keyServiceCount) clés à compléter")
                    .font(.archivo(12, .heavy))
                    .foregroundStyle(Ink.accent2Text)
            }
            .padding(.bottom, 16)
            // Un toast passe en deux secondes : si le fichier contenait plus de
            // services que de places, ça se dit ici, en toutes lettres.
            if store.lastImportDropped > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(store.lastImportDropped) services de ton fichier n'ont pas été importés faute de place.")
                        .font(.archivo(12, .heavy))
                        .foregroundStyle(Ink.accentText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Débloque des places puis réimporte le fichier : il reste ta source de vérité, rien n'est perdu de ton côté.")
                        .font(.archivo(11))
                        .foregroundStyle(Ink.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    MSecondaryButton(title: "Débloquer des services") { store.openPaywall() }
                }
                .padding(12)
                .overlay(Rectangle().strokeBorder(Ink.accentRing, lineWidth: 2))
                .padding(.bottom, 16)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(Array(store.mainGroups.enumerated()), id: \.offset) { gi, g in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                Text(g).upperLabel(10.5, .heavy)
                                Text(String(format: "%02d", servicesIn(gi).count))
                                    .font(.archivo(10)).monospacedDigit()
                                    .foregroundStyle(Ink.muted)
                                Spacer()
                            }
                            .padding(.bottom, 5)
                            HRule(weight: 2)
                            ForEach(Array(servicesIn(gi).enumerated()), id: \.element.id) { i, s in
                                if i > 0 { HRule() }
                                importRow(s)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .frame(maxHeight: .infinity)
            MPrimaryButton(title: "Continuer") { goToKeysOrReady() }
                .padding(.top, 14)
        }
    }

    private var keyServiceCount: Int { servicesNeedingKey.count }

    private func servicesIn(_ gi: Int) -> [Service] {
        store.mainServices.filter { $0.group == gi }
    }

    private func importRow(_ s: Service) -> some View {
        let type = store.type(of: s)
        let needsKey = LiveFetcher.keyHint(for: type) != nil && store.apiKey(for: s.id) == nil
        return HStack(spacing: 10) {
            ZStack {
                Ink.text
                Text(s.mono).font(.archivo(11, .heavy)).foregroundStyle(Ink.bg)
            }
            .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(s.name).font(.archivo(13, .heavy)).lineLimit(1)
                Text(s.url).font(.archivo(9.5)).monospaced()
                    .foregroundStyle(Ink.muted).lineLimit(1)
            }
            Spacer(minLength: 8)
            if type != .generic {
                Text(type.rawValue).font(.archivo(9.5)).foregroundStyle(Ink.muted).lineLimit(1)
            }
            if needsKey {
                Text("Clé")
                    .font(.archivo(8, .heavy)).textCase(.uppercase).tracking(0.3)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Ink.accent2Bg).foregroundStyle(Ink.accent2Text)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: 2d — Scan Bonjour

    private var scanStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(store.scanner.scanning ? "Scan du réseau…" : "Scan terminé")
                .font(.archivo(24, .heavy))
                .padding(.bottom, 4)
            Text("Bonjour sur ton réseau local")
                .font(.archivo(11.5))
                .foregroundStyle(Ink.muted)
                .padding(.bottom, 14)
            QuotaBanner()
                .padding(.bottom, 14)

            if store.scanner.found.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    if store.scanner.scanning {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Recherche des services…").font(.archivo(12)).foregroundStyle(Ink.muted)
                        }
                    } else {
                        Text("Aucun service annoncé en Bonjour.").font(.archivo(14, .heavy))
                        Text("Beaucoup de homelabs (reverse proxy, Docker) n'annoncent pas en Bonjour. Tu peux importer ton services.yaml à la place.")
                            .font(.archivo(11.5))
                            .foregroundStyle(Ink.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        MSecondaryButton(title: "Importer un services.yaml") { importing = true }
                    }
                }
                .padding(.vertical, 10)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(store.scanner.found.enumerated()), id: \.element.id) { i, f in
                            if i > 0 { HRule() }
                            scanRow(f)
                        }
                    }
                }
            }
            Spacer()
            MPrimaryButton(title: added.isEmpty ? "Continuer" : "Continuer avec \(added.count) services") {
                store.scanner.stop()
                goToKeysOrReady()
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.yaml, .plainText, .data]) { handleImport($0) }
    }

    private func scanRow(_ f: BonjourScanner.Found) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Ink.text
                Text(YamlConfig.mono(f.name)).font(.archivo(11, .heavy)).foregroundStyle(Ink.bg)
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(f.name).font(.archivo(13, .heavy)).lineLimit(1)
                Text("\(f.host):\(String(f.port))\(f.type.map { " · \($0.rawValue)" } ?? "")")
                    .font(.archivo(10.5)).monospacedDigit()
                    .foregroundStyle(Ink.muted).lineLimit(1)
            }
            Spacer()
            if added.contains(f.id) {
                Text("AJOUTÉ").upperLabel(9, .heavy).foregroundStyle(Ink.muted)
            } else {
                Button {
                    // Refus faute de place : la rangée reste « à ajouter » et
                    // la boutique s'ouvre par-dessus le tutoriel.
                    if store.addScanned(f) { added.insert(f.id) }
                } label: {
                    Text("Ajouter")
                        .font(.archivo(11, .heavy))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Ink.accent).foregroundStyle(.white)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 9)
    }

    // MARK: 2e — Clés API (optionnel)

    private var servicesNeedingKey: [Service] {
        store.mainServices.filter {
            LiveFetcher.keyHint(for: store.type(of: $0)) != nil && store.apiKey(for: $0.id) == nil
        }
    }

    private func goToKeysOrReady() {
        step = servicesNeedingKey.isEmpty ? .ready : .keysStep
    }

    private var keysStep: some View {
        let needing = servicesNeedingKey
        return VStack(alignment: .leading, spacing: 0) {
            Text("Quelques clés API")
                .font(.archivo(24, .heavy))
                .padding(.bottom, 8)
            Text("Certains services demandent une clé pour afficher leurs métriques. Optionnel — tu peux le faire plus tard, dans le détail du service.")
                .font(.archivo(12.5))
                .foregroundStyle(Ink.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
            Text("\(needing.count) service\(needing.count > 1 ? "s" : "") concerné\(needing.count > 1 ? "s" : "")")
                .upperLabel(10.5, .heavy)
                .padding(.bottom, 5)
            HRule(weight: 2)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(needing.enumerated()), id: \.element.id) { i, s in
                        if i > 0 { HRule() }
                        keyRow(s)
                    }
                }
            }
            Spacer()
            MPrimaryButton(title: "Enregistrer") {
                saveKeys(needing)
                step = .ready
            }
            .padding(.bottom, 2)
            Button { step = .ready } label: {
                Text("Plus tard")
                    .font(.archivo(12.5, .bold))
                    .foregroundStyle(Ink.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    private func keyRow(_ s: Service) -> some View {
        let style = LiveFetcher.keyStyle(for: store.type(of: s))
        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                ZStack {
                    Ink.text
                    Text(s.mono).font(.archivo(11, .heavy)).foregroundStyle(Ink.bg)
                }
                .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(s.name).font(.archivo(13, .heavy)).lineLimit(1)
                    if style == .token, let hint = LiveFetcher.keyHint(for: store.type(of: s)) {
                        Text(hint).font(.archivo(9.5)).foregroundStyle(Ink.muted).lineLimit(1)
                    }
                }
                Spacer()
            }
            switch style {
            case .userPassword:
                HStack(spacing: 8) {
                    keyField("Utilisateur", text: bindUser(s.id))
                    keyField("Mot de passe", text: bindKey(s.id), secure: true)
                }
            case .password:
                keyField("Mot de passe", text: bindKey(s.id), secure: true)
            case .token:
                keyField("Clé", text: bindKey(s.id))
            }
        }
        .padding(.vertical, 12)
    }

    private func keyField(_ placeholder: String, text: Binding<String>, secure: Bool = false) -> some View {
        Group {
            if secure {
                SecureField(LocalizedStringKey(placeholder), text: text)
            } else {
                TextField(LocalizedStringKey(placeholder), text: text)
            }
        }
        .textFieldStyle(.plain)
        .font(.archivo(11)).monospaced()
        .autocorrectionDisabled()
        .frame(maxWidth: .infinity)
        .padding(8)
        .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
    }

    private func bindKey(_ id: String) -> Binding<String> {
        Binding(get: { keyInputs[id] ?? "" }, set: { keyInputs[id] = $0 })
    }
    private func bindUser(_ id: String) -> Binding<String> {
        Binding(get: { userInputs[id] ?? "" }, set: { userInputs[id] = $0 })
    }

    private func saveKeys(_ services: [Service]) {
        for s in services {
            let value: String
            if LiveFetcher.keyStyle(for: store.type(of: s)) == .userPassword {
                let u = (userInputs[s.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let p = (keyInputs[s.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                value = u.isEmpty && p.isEmpty ? "" : "\(u):\(p)"
            } else {
                value = (keyInputs[s.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if !value.isEmpty { store.setKey(value, for: s.id) }
        }
    }

    // MARK: 3 — Prêt

    private var ready: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Rectangle().fill(Ink.accent).frame(width: 44, height: 44)
                .padding(.bottom, 24)
            Text("Ton homelab\nest prêt.")
                .font(.archivo(32, .heavy))
                .lineSpacing(2)
                .padding(.bottom, 12)
            Text("Specula interroge désormais tes services. Le mode Démo est désactivé — tu peux le réactiver dans Réglages à tout moment.")
                .font(.archivo(13))
                .foregroundStyle(Ink.muted)
                .padding(.bottom, 8)
            Text("Réglages → Exporter enregistre un services.yaml : c'est ce fichier qui te sert à reprendre la même configuration sur un autre appareil.")
                .font(.archivo(13))
                .foregroundStyle(Ink.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 22)
            HStack(spacing: 0) {
                statCell("\(store.mainServices.count)", "Services")
                VRule()
                statCell(String(format: "%02d", store.mainGroups.count), "Groupes")
                VRule()
                statCell("ON", "Homelab")
            }
            .frame(height: 78)
            .fixedSize(horizontal: false, vertical: true)
            .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
            .padding(.bottom, 24)
            Spacer()
            MPrimaryButton(title: "Ouvrir le tableau de bord") { done() }
        }
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.archivo(22, .heavy)).monospacedDigit()
            Text(LocalizedStringKey(label)).upperLabel(8.5).foregroundStyle(Ink.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 14)
    }

    // MARK: Import

    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            store.fireToast(String(localized: "Import impossible — fichier illisible"))
            return
        }
        store.scanner.stop()
        store.importYAML(text)   // bascule en Homelab + charge services/groupes
        step = .importStep
    }
}
#endif
