#if os(iOS)
import SwiftUI

// MARK: - Statut : mur de disponibilité
//
// Le mur du Mac, remis d'aplomb pour un écran étroit. Deux écarts, tous deux
// dictés par la largeur :
//
// - le nom du service passe au-dessus des blocs au lieu de leur prendre 150 pt
//   sur la gauche. Sur un iPhone, c'est la seule façon de laisser aux blocs une
//   taille qu'on puisse viser du pouce ;
// - l'iPhone n'en montre que quatorze, l'iPad les trente. `AppStore` garde
//   toujours trente jours d'historique : c'est l'affichage qui se resserre, pas
//   la donnée.

struct StatusView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var incident: IncidentSelection?

    /// Sur iPad la page s'ouvre en feuille depuis l'en-tête ; sur iPhone elle
    /// est empilée dans la `NavigationStack`. Le bouton de sortie suit.
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    /// Jours affichés, en comptant aujourd'hui.
    private var days: Int { isPad ? Self.history : 14 }

    /// Profondeur de l'historique tenu par `AppStore` — `Incident.day` va de 0
    /// (J-29) à 29 (aujourd'hui).
    private static let history = 30

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Disponibilité")
                            .upperLabel(10.5, .heavy)
                        Spacer()
                        Text("J-\(days - 1) → aujourd'hui")
                            .font(.archivo(10))
                            .foregroundStyle(Ink.muted)
                    }
                    .padding(.bottom, 6)
                    HRule(weight: 2)

                    if let inc = incident {
                        incidentPanel(inc)
                    }

                    if store.services.isEmpty {
                        Text("Aucun service configuré — le mur se remplit dès qu'un service est suivi.")
                            .font(.archivo(12))
                            .foregroundStyle(Ink.muted)
                            .padding(.top, 16)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(store.services.enumerated()), id: \.element.id) { i, s in
                                if i > 0 { HRule() }
                                row(s)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(18)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: Barre supérieure

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isPad ? "xmark" : "chevron.backward")
                        .font(.system(size: 13, weight: .semibold))
                    Text(isPad ? "Fermer" : "Retour")
                        .font(.archivo(13, .semibold))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Ink.text)
            Spacer()
            Text("Statut")
                .font(.archivo(13, .heavy))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: Panneau d'incident

    private func incidentPanel(_ inc: IncidentSelection) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle().fill(Ink.accent).frame(width: 10, height: 10)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "INCIDENT — \(inc.service)"))
                    .upperLabel(10, .heavy)
                    .foregroundStyle(Ink.accentText)
                Text(verbatim: "\(inc.when) · \(inc.duration)")
                    .font(.archivo(12, .bold)).monospacedDigit()
                Text(inc.cause)
                    .font(.archivo(11.5))
                    .foregroundStyle(Ink.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button {
                incident = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Ink.text)
        }
        .padding(14)
        .background(Ink.surface)
        .overlay(Rectangle().strokeBorder(Ink.accentRing, lineWidth: 2))
        .padding(.top, 12)
    }

    // MARK: Rangée d'un service

    private func row(_ s: Service) -> some View {
        let incs = store.incidents(for: s)
        let liveDown = store.isDown(s)
        let hasIssue = !incs.isEmpty || liveDown
        // Les `days` derniers jours de l'historique, aujourd'hui en dernier.
        let shown = (Self.history - days)..<Self.history
        return VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                Text(s.name)
                    .font(.archivo(13, .heavy))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(store.availability(s))
                    .font(.archivo(13, .heavy)).monospacedDigit()
                    .foregroundStyle(hasIssue ? Ink.accentText : Ink.text)
            }
            HStack(spacing: 4) {
                ForEach(Array(shown), id: \.self) { day in
                    let inc = incs.first { $0.day == day }
                    let live = day == Self.history - 1 && liveDown
                    let bad = inc != nil || live
                    Rectangle()
                        .fill(bad ? Ink.accent : Ink.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)
                        .contentShape(.rect)
                        .onTapGesture {
                            guard bad else { return }
                            incident = IncidentSelection(
                                service: s.name,
                                when: live ? String(localized: "aujourd'hui · en cours")
                                           : String(localized: "J-\(Self.history - 1 - day)"),
                                duration: live ? String(localized: "\(store.downDurationMin) min")
                                               : (inc?.duration ?? ""),
                                cause: live ? String(localized: "Délai dépassé (timeout) — 3 tentatives échouées")
                                            : (inc?.cause ?? ""))
                        }
                }
            }
        }
        .padding(.vertical, 11)
    }
}
#endif
