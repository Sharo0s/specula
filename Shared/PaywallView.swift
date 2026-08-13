import SwiftUI

// MARK: - Boutique (achats intégrés)
//
// Overlay plein cadre, comme la palette ⌘K : présenté depuis la racine iOS,
// la racine macOS et la feuille de scan — les trois contextes de présentation
// de l'app. Un overlay et pas une `sheet` : la feuille de scan est elle-même
// une `sheet`, et deux présentations concurrentes sur le même état ne
// s'affichent pas de façon fiable.

struct PaywallView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture { store.paywallOpen = false }

            // Le panneau est borné en hauteur : la liste défile à l'intérieur
            // plutôt que d'étirer la boutique sur toute la fenêtre d'un Mac.
            panel
                .frame(maxWidth: 460, maxHeight: 560)
                .background(Ink.bg)
                .overlay(Rectangle().strokeBorder(Ink.text, lineWidth: 2))
                .padding(20)
        }
    }

    private var billing: Billing { store.billing }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            HRule(weight: 2)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    quotaBlock
                    offersBlock
                    footer
                }
                .padding(18)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: En-tête

    private var header: some View {
        HStack(spacing: 9) {
            BrandSquare()
            Text("Débloquer des services")
                .font(.archivo(16, .heavy))
            Spacer()
            Button {
                store.paywallOpen = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 26, height: 26)
                    .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Ink.text)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: Où en est le quota

    private var quotaBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                statCell("\(store.configuredCount)", "Configurés")
                VRule()
                statCell(store.quota.capacity.map { "\($0)" } ?? "∞", "Places")
                VRule()
                statCell("\(ServiceQuota.free)", "Offerts")
            }
            .frame(height: 66)
            .fixedSize(horizontal: false, vertical: true)
            .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))

            // Deux `Text` distincts et pas un ternaire : avec deux littéraux,
            // le choix entre `Text(LocalizedStringKey)` et `Text(String)` n'est
            // plus garanti, et la seconde version ne se traduit pas.
            Group {
                if store.billing.unlimited {
                    Text("Tu as le déverrouillage illimité — ajoute autant de services que tu veux.")
                } else {
                    Text("Les \(ServiceQuota.free) premiers services sont offerts, sans limite de durée. Au-delà, chaque place s'achète une fois et reste acquise.")
                }
            }
            .font(.archivo(11.5))
            .foregroundStyle(Ink.muted)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 10)
        }
        .padding(.bottom, 18)
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.archivo(20, .heavy))
                .monospacedDigit()
            Text(LocalizedStringKey(label))
                .upperLabel(8.5)
                .foregroundStyle(Ink.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
    }

    // MARK: Offres

    @ViewBuilder private var offersBlock: some View {
        if store.billing.unlimited {
            EmptyView()
        } else if billing.offers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                if billing.loadingProducts {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Chargement de la boutique…")
                            .font(.archivo(12))
                            .foregroundStyle(Ink.muted)
                    }
                } else {
                    Text(billing.lastError ?? String(localized: "Boutique indisponible."))
                        .font(.archivo(12))
                        .foregroundStyle(Ink.accent2Text)
                        .fixedSize(horizontal: false, vertical: true)
                    MSecondaryButton(title: "Réessayer") {
                        Task { await billing.loadProducts() }
                    }
                }
            }
            .padding(.bottom, 18)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("Offres")
                    .upperLabel(10.5, .heavy)
                    .padding(.bottom, 5)
                HRule(weight: 2)
                ForEach(Array(billing.offers.enumerated()), id: \.element.id) { i, offer in
                    if i > 0 { HRule() }
                    offerRow(offer)
                }
                if let error = billing.lastError {
                    Text(error)
                        .font(.archivo(11))
                        .foregroundStyle(Ink.accent2Text)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
            }
            .padding(.bottom, 18)
        }
    }

    private func offerRow(_ offer: Billing.Offer) -> some View {
        let busy = billing.purchasing == offer.id
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 7) {
                    // Nom venu de l'App Store : pas de LocalizedStringKey, il
                    // est déjà rendu dans la langue du compte.
                    Text(offer.name)
                        .font(.archivo(13.5, .heavy))
                    if offer.isUnlimited {
                        Text("Sans limite")
                            .font(.archivo(8, .heavy))
                            .textCase(.uppercase)
                            .tracking(0.4)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Ink.accent2Bg)
                            .foregroundStyle(Ink.accent2Text)
                    }
                }
                Text(subtitle(offer))
                    .font(.archivo(11))
                    .foregroundStyle(Ink.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button {
                Task { await billing.purchase(offerID: offer.id) }
            } label: {
                Group {
                    if busy {
                        ProgressView().controlSize(.small)
                    } else {
                        // Prix rendu par StoreKit — devise et format du compte.
                        Text(offer.price)
                            .font(.archivo(12.5, .heavy))
                            .monospacedDigit()
                    }
                }
                .frame(minWidth: 74)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Ink.accent)
                .foregroundStyle(.white)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(billing.purchasing != nil)
            .opacity(billing.purchasing != nil && !busy ? 0.5 : 1)
        }
        .padding(.vertical, 11)
    }

    /// `LocalizedStringKey` et pas `String` : l'interpolation reste littérale,
    /// donc extractible dans le catalogue (« %lld places d'un coup. »).
    private func subtitle(_ offer: Billing.Offer) -> LocalizedStringKey {
        switch offer.slots {
        case 0: "Places illimitées, une fois pour toutes."
        case 1: "Une place de service de plus."
        default: "\(offer.slots) places d'un coup."
        }
    }

    // MARK: Pied

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HRule()
            Text("Paiement par ton compte App Store. Les places achetées restent acquises : supprimer un service en libère une pour un autre.")
                .font(.archivo(10.5))
                .foregroundStyle(Ink.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            MSecondaryButton(title: "Restaurer mes achats") {
                Task { await billing.restore() }
            }
        }
    }
}

// MARK: - Bandeau de quota

/// Où en est le quota, là où l'utilisateur ajoute des services (formulaire
/// d'ajout, scan réseau, réglages). Muet quand l'illimité est acquis : il n'y a
/// alors plus rien à surveiller.
struct QuotaBanner: View {
    @Environment(AppStore.self) private var store
    /// Afficher aussi l'état « illimité ». Utile dans les Réglages, où l'on
    /// vient vérifier ce qu'on possède ; ailleurs, un quota levé n'a plus rien
    /// à signaler.
    var showsUnlimited = false

    var body: some View {
        // `remainingSlots` vaut nil quand la limite est levée.
        if let remaining = store.remainingSlots {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(remaining == 0 ? Ink.accent : Ink.text.opacity(0.25))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(remaining == 0
                         ? String(localized: "Limite atteinte")
                         : (remaining == 1 ? String(localized: "1 place libre")
                                           : String(localized: "\(remaining) places libres")))
                        .font(.archivo(12, .heavy))
                        .foregroundStyle(remaining == 0 ? Ink.accentText : Ink.text)
                    Text("\(store.configuredCount) / \(store.quota.capacity ?? store.configuredCount) services · \(ServiceQuota.free) offerts")
                        .font(.archivo(10.5))
                        .monospacedDigit()
                        .foregroundStyle(Ink.muted)
                }
                Spacer(minLength: 8)
                Button {
                    store.openPaywall()
                } label: {
                    Text("Débloquer")
                        .font(.archivo(11, .heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(remaining == 0 ? Ink.accent : .clear)
                        .foregroundStyle(remaining == 0 ? .white : Ink.text)
                        .overlay(Rectangle().strokeBorder(
                            remaining == 0 ? .clear : Ink.divider, lineWidth: 1))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .overlay(Rectangle().strokeBorder(
                remaining == 0 ? Ink.accentRing : Ink.divider, lineWidth: 1))
        } else if showsUnlimited {
            unlimitedRow
        }
    }

    private var unlimitedRow: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Ink.accent2)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text("Places illimitées")
                    .font(.archivo(12, .heavy))
                Text("\(store.configuredCount) services configurés · aucune limite")
                    .font(.archivo(10.5))
                    .monospacedDigit()
                    .foregroundStyle(Ink.muted)
            }
            Spacer(minLength: 8)
            Text("Acquis")
                .upperLabel(8.5, .heavy)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Ink.accent2Bg)
                .foregroundStyle(Ink.accent2Text)
        }
        .padding(10)
        .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
    }
}

// MARK: - Présentation

private struct PaywallPresenter: ViewModifier {
    @Environment(AppStore.self) private var store

    func body(content: Content) -> some View {
        ZStack {
            content
            if store.paywallOpen {
                PaywallView()
            }
        }
    }
}

extension View {
    /// Ajoute la boutique en overlay, pilotée par `AppStore.paywallOpen`.
    /// À poser une fois par contexte de présentation — racine iOS, racine
    /// macOS, feuille de scan — et pas davantage : deux overlays actifs
    /// dessineraient deux panneaux l'un sur l'autre.
    func speculaPaywall() -> some View {
        modifier(PaywallPresenter())
    }
}
