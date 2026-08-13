import SwiftUI

// MARK: - Scan du réseau (Bonjour) — feuille partagée iOS / macOS

struct ScanSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var added: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(store.scanner.scanning ? "Scan en cours…" : "Scan terminé")
                    .font(.archivo(17, .heavy))
                Spacer()
                Button {
                    store.scanner.stop()
                    dismiss()
                } label: {
                    Text("Fermer")
                        .font(.archivo(12, .heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Ink.text)
            }
            .padding(.bottom, 4)
            Text("Bonjour (_http._tcp) sur le réseau local")
                .font(.archivo(11))
                .foregroundStyle(Ink.muted)
                .padding(.bottom, 12)
            QuotaBanner()
                .padding(.bottom, 12)
            HRule(weight: 2)

            if store.scanner.found.isEmpty {
                VStack(spacing: 8) {
                    if store.scanner.scanning {
                        ProgressView()
                        Text("Recherche des services…")
                    } else {
                        Text("Aucun service annoncé en Bonjour sur ce réseau.")
                    }
                }
                .font(.archivo(12))
                .foregroundStyle(Ink.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(store.scanner.found.enumerated()), id: \.element.id) { i, f in
                            if i > 0 { HRule() }
                            HStack(spacing: 10) {
                                ZStack {
                                    Ink.text
                                    Text(YamlConfig.mono(f.name))
                                        .font(.archivo(11, .heavy))
                                        .foregroundStyle(Ink.bg)
                                }
                                .frame(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(f.name)
                                        .font(.archivo(13, .heavy))
                                        .lineLimit(1)
                                    Text("\(f.host):\(String(f.port))\(f.type.map { " · \($0.rawValue)" } ?? "")")
                                        .font(.archivo(10.5)).monospacedDigit()
                                        .foregroundStyle(Ink.muted)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if added.contains(f.id) {
                                    Text("AJOUTÉ")
                                        .upperLabel(9, .heavy)
                                        .foregroundStyle(Ink.muted)
                                } else {
                                    Button {
                                        // Quota plein : `addScanned` refuse et
                                        // ouvre la boutique — la rangée ne doit
                                        // pas passer à « AJOUTÉ » pour autant.
                                        if store.addScanned(f) { added.insert(f.id) }
                                    } label: {
                                        Text("Ajouter")
                                            .font(.archivo(11, .heavy))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Ink.accent)
                                            .foregroundStyle(.white)
                                            .contentShape(.rect)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 9)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(minWidth: 380, minHeight: 340)
        .background(Ink.bg)
        // La feuille est son propre contexte de présentation : sans ça, la
        // boutique ouverte depuis une rangée s'afficherait derrière elle.
        .speculaPaywall()
        .onAppear { store.scanner.start() }
        .onDisappear { store.scanner.stop() }
    }
}
