#if os(iOS)
import SwiftUI

// MARK: - Onboarding : Bienvenue → Scan → Import & groupes

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    let done: () -> Void

    @State private var step = 0
    @State private var scanned = 0
    @State private var scanTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Marqueur d'étape
            HStack(spacing: 8) {
                BrandSquare()
                Text("Specula")
                    .font(.archivo(16, .heavy))
                Spacer()
                Text(LocalizedStringKey(["1 — Bienvenue", "2 — Scan", "3 — Import & groupes"][step]))
                    .upperLabel(9, .bold)
                    .foregroundStyle(Ink.muted)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            HRule(weight: 2).padding(.horizontal, 24)

            Group {
                switch step {
                case 0: welcome
                case 1: scan
                default: importStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }
        .background(Ink.bg)
    }

    // MARK: 1 — Bienvenue

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Rectangle().fill(Ink.accent).frame(width: 44, height: 44)
                .padding(.bottom, 24)
            Text("Tout ton homelab.\nUne seule app.")
                .font(.archivo(34, .heavy))
                .lineSpacing(2)
                .padding(.bottom, 12)
            Text("Jellyfin, Proxmox, Home Assistant, AdGuard… tes services selfhosted, leurs métriques en direct et les pannes qui comptent — sur iPhone, iPad, Mac et Watch.")
                .font(.archivo(13))
                .foregroundStyle(Ink.muted)
                .padding(.bottom, 32)
            MPrimaryButton(title: "Scanner mon réseau") {
                step = 1
                startScan()
            }
            .padding(.bottom, 8)
            MSecondaryButton(title: "Importer une config Homepage") { step = 2 }
            Spacer()
        }
    }

    // MARK: 2 — Scan

    private var scan: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(scanned >= 17 ? "Scan terminé" : "Scan en cours…")
                .font(.archivo(24, .heavy))
                .padding(.bottom, 4)
            Text("Bonjour + balayage du sous-réseau 192.168.1.0/24")
                .font(.archivo(11.5))
                .foregroundStyle(Ink.muted)
                .padding(.bottom, 16)

            // Progression
            HStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Ink.divider.opacity(0.4)
                        Ink.accent.frame(width: geo.size.width * CGFloat(scanned) / 17)
                    }
                }
                .frame(height: 6)
                Text("\(scanned)/17")
                    .font(.archivo(13, .heavy)).monospacedDigit()
            }
            .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(Array(Catalog.services.prefix(scanned).suffix(6).enumerated()), id: \.element.id) { i, s in
                    if i > 0 { HRule() }
                    HStack(spacing: 10) {
                        ZStack {
                            Ink.text
                            Text(s.mono)
                                .font(.archivo(11, .heavy))
                                .foregroundStyle(Ink.bg)
                        }
                        .frame(width: 28, height: 28)
                        Text(s.name)
                            .font(.archivo(13, .heavy))
                        Spacer()
                        Text(s.url)
                            .font(.archivo(10.5)).monospacedDigit()
                            .foregroundStyle(Ink.muted)
                    }
                    .padding(.vertical, 8)
                }
            }
            Spacer()
            if scanned >= 17 {
                MPrimaryButton(title: "Continuer") { step = 2 }
            }
        }
    }

    private func startScan() {
        scanned = 0
        scanTask?.cancel()
        scanTask = Task {
            while scanned < 17 && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(280))
                scanned += 1
            }
        }
    }

    // MARK: 3 — Import & groupes

    private var importStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Import & groupes")
                .font(.archivo(24, .heavy))
                .padding(.bottom, 16)

            Button {
                store.fireToast("Sélection du fichier services.yaml…")
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("services.yaml")
                        .font(.archivo(14, .heavy))
                    Text("Ta config Homepage existante — groupes, widgets et clés API repris tels quels.")
                        .font(.archivo(11))
                        .foregroundStyle(Ink.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .overlay(Rectangle().strokeBorder(Ink.divider, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Ink.text)
            .padding(.bottom, 24)

            Text("Groupes reconnus")
                .upperLabel(10.5, .heavy)
                .padding(.bottom, 5)
            HRule(weight: 2)
            ForEach(Array(Catalog.mainServer.groups.enumerated()), id: \.offset) { gi, g in
                if gi > 0 { HRule() }
                HStack {
                    Text(g)
                        .font(.archivo(13.5, .bold))
                    Spacer()
                    Text(String(format: "%02d", Catalog.services.filter { $0.group == gi }.count))
                        .font(.archivo(11)).monospacedDigit()
                        .foregroundStyle(Ink.muted)
                }
                .padding(.vertical, 10)
            }
            Spacer()
            MPrimaryButton(title: "Commencer") {
                store.fireToast("Configuration terminée — bienvenue dans Specula")
                done()
            }
        }
    }
}
#endif
