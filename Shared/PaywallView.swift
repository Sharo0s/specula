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
    /// Places à acheter d'un coup. Amorcé sur ce qu'il a manqué au dernier
    /// import : celui qui vient de perdre onze services trouve onze au
    /// compteur, pas un.
    @State private var quantity = 1

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
        .onAppear { quantity = store.suggestedSlotCount }
    }

    private var billing: Billing { store.billing }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            HRule(weight: 2)
            // Le panneau épouse son contenu et ne défile que s'il déborde.
            // Une `ScrollView` seule prend toute la hauteur qu'on lui offre :
            // elle laissait un grand vide sous « Restaurer mes achats » tant
            // que la boutique tenait dans le cadre.
            ViewThatFits(in: .vertical) {
                sections
                ScrollView { sections }
                    .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: 0) {
            quotaBlock
            offersBlock
            footer
        }
        .padding(18)
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

    /// Les places s'achètent en quantité : sélecteur, et le bouton porte le
    /// total. L'illimité s'achète une fois, sa rangée reste sur une ligne.
    @ViewBuilder
    private func offerRow(_ offer: Billing.Offer) -> some View {
        if offer.isUnlimited {
            HStack(alignment: .center, spacing: 12) {
                offerLabel(offer)
                Spacer(minLength: 8)
                buyButton(offer, quantity: 1)
            }
            .padding(.vertical, 11)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                offerLabel(offer)
                HStack(spacing: 12) {
                    stepper
                    Spacer(minLength: 8)
                    buyButton(offer, quantity: quantity)
                }
            }
            .padding(.vertical, 11)
        }
    }

    private func offerLabel(_ offer: Billing.Offer) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 7) {
                // Nom venu de l'App Store : pas de LocalizedStringKey, il
                // est déjà rendu dans la langue du compte.
                Text(offer.name)
                    .font(.archivo(13.5, .heavy))
                if offer.isUnlimited {
                    Text("Soutien")
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func buyButton(_ offer: Billing.Offer, quantity: Int) -> some View {
        let busy = billing.purchasing == offer.id
        return Button {
            Task { await billing.purchase(offerID: offer.id, quantity: quantity) }
        } label: {
            Group {
                if busy {
                    ProgressView().controlSize(.small)
                } else {
                    // Total rendu par StoreKit — devise et format du compte.
                    Text(billing.displayTotal(offer.id, quantity: quantity))
                        .font(.archivo(12.5, .heavy))
                        .monospacedDigit()
                }
            }
            .frame(minWidth: 80)
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

    /// Sélecteur de quantité — carrés bordés, comme le reste du système.
    private var stepper: some View {
        HStack(spacing: 0) {
            stepButton("minus", enabled: quantity > 1) { quantity -= 1 }
            // `Text(_:format:)` et pas une interpolation : un nombre nu
            // déposerait une clé « %lld » dans le catalogue, à traduire dans
            // les cinq langues pour n'y rien dire.
            Text(quantity, format: .number)
                .font(.archivo(13, .heavy))
                .monospacedDigit()
                .frame(minWidth: 38)
            stepButton("plus", enabled: quantity < SlotProduct.maxQuantity) { quantity += 1 }
        }
        .frame(height: 30)
        .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
    }

    private func stepButton(_ symbol: String, enabled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 30, height: 30)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Ink.text)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
    }

    /// `LocalizedStringKey` et pas `String` : l'interpolation reste littérale,
    /// donc extractible dans le catalogue (« %lld places d'un coup. »).
    ///
    /// L'illimité coûte plus cher que d'acheter les places une à une, et on le
    /// dit. Le taire ferait de la boutique un calcul caché — celui que
    /// l'utilisateur refera de toute façon, et qu'il nous reprochera. Annoncé,
    /// c'est un choix qu'il fait en connaissance de cause.
    private func subtitle(_ offer: Billing.Offer) -> LocalizedStringKey {
        offer.isUnlimited
            ? "Plus cher que les places à l'unité — c'est ce qui finance un projet libre, sans pub et sans mouchard."
            : "\(offer.price) la place, acquise définitivement."
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
