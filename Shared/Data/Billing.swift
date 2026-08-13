import Foundation
import Observation
import StoreKit

// MARK: - Achats intégrés (StoreKit 2)
//
// Modèle : les quatre premiers services sont offerts, les suivants s'achètent.
// Trois produits, à déclarer dans App Store Connect avec ces identifiants :
//
//   <bundle>.slot.one    consommable      une place de service
//   <bundle>.slot.five   consommable      cinq places (pack)
//   <bundle>.unlimited   non consommable  places illimitées
//
// Aucun prix n'est écrit ici. Il vient de `Product.displayPrice`, dans la
// devise et le format du compte App Store de l'utilisateur — une valeur codée
// en dur mentirait dès le premier changement de palier ou de pays.

/// Identifiants produits, dérivés de l'identifiant d'app : un fork qui pose son
/// propre `SPECULA_BUNDLE_PREFIX` obtient ses propres produits sans toucher au
/// code, comme pour l'App Group.
enum SlotProduct {
    private static var prefix: String {
        Bundle.main.bundleIdentifier ?? "com.smalard.specula"
    }

    static var one: String { prefix + ".slot.one" }
    static var five: String { prefix + ".slot.five" }
    static var unlimited: String { prefix + ".unlimited" }

    /// Ordre d'affichage de la boutique : l'unité d'abord, l'illimité en dernier.
    static var all: [String] { [one, five, unlimited] }

    /// Places débloquées par un exemplaire du produit (0 pour l'illimité, qui
    /// ne se compte pas en places).
    static func slots(_ id: String) -> Int {
        if id == one { return 1 }
        if id == five { return 5 }
        return 0
    }
}

@MainActor
@Observable
final class Billing {

    /// Produits chargés depuis l'App Store, dans l'ordre de `SlotProduct.all`.
    private(set) var products: [Product] = []
    /// Places achetées, cumulées.
    private(set) var purchasedSlots: Int
    /// Déverrouillage illimité (non consommable).
    private(set) var unlimited: Bool
    /// Chargement du catalogue en cours.
    private(set) var loadingProducts = false
    /// Identifiant du produit dont l'achat est en cours (bouton en attente).
    private(set) var purchasing: String?
    /// Dernier échec présentable à l'utilisateur.
    var lastError: String?

    /// Appelé à chaque changement pour que l'appelant persiste le décompte.
    var onChange: (@MainActor (Int, Bool) -> Void)?

    /// Écoute des transactions arrivées hors de l'app (achat sur un autre
    /// appareil, « Demander à acheter » approuvé plus tard, remboursement).
    private var updatesTask: Task<Void, Never>?

    init(purchasedSlots: Int = 0, unlimited: Bool = false) {
        self.purchasedSlots = max(0, purchasedSlots)
        self.unlimited = unlimited
        updatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else { return }
                guard let transaction = try? update.payloadValue else { continue }
                await transaction.finish()
                await self.refresh()
            }
        }
    }

    // MARK: Catalogue

    /// Charge les produits — appelé à l'ouverture de la boutique, pas au
    /// lancement : c'est une requête réseau, et la plupart des sessions ne
    /// verront jamais le paywall.
    func loadProducts() async {
        guard !loadingProducts else { return }
        loadingProducts = true
        defer { loadingProducts = false }
        do {
            let fetched = try await Product.products(for: SlotProduct.all)
            products = SlotProduct.all.compactMap { id in fetched.first { $0.id == id } }
            if products.isEmpty {
                lastError = String(localized: "Aucun produit disponible — vérifie ta connexion.")
            } else {
                lastError = nil
            }
        } catch {
            products = []
            lastError = String(localized: "Boutique injoignable — réessaie dans un instant.")
        }
    }

    /// Offre présentable, sans dépendance à StoreKit côté vue : le prix est
    /// toujours celui rendu par l'App Store (devise et format du compte).
    struct Offer: Identifiable, Equatable {
        let id: String
        let name: String
        let price: String
        /// Places débloquées — 0 pour le déverrouillage illimité.
        let slots: Int

        var isUnlimited: Bool { slots == 0 }
    }

    var offers: [Offer] {
        products.map {
            Offer(id: $0.id, name: $0.displayName, price: $0.displayPrice,
                  slots: SlotProduct.slots($0.id))
        }
    }

    // MARK: Achat

    @discardableResult
    func purchase(offerID: String) async -> Bool {
        guard let product = products.first(where: { $0.id == offerID }) else { return false }
        return await purchase(product)
    }

    /// `true` si l'achat a été conclu et crédité.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        guard purchasing == nil else { return false }
        purchasing = product.id
        defer { purchasing = nil }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard let transaction = try? verification.payloadValue else {
                    lastError = String(localized: "Achat non vérifié par l'App Store.")
                    return false
                }
                credit(transaction)
                // Un consommable non terminé est resservi à chaque lancement :
                // on le clôt une fois la place créditée, pas avant.
                await transaction.finish()
                lastError = nil
                await refresh()
                return true
            case .userCancelled:
                return false
            case .pending:
                // « Demander à acheter » : la transaction arrivera par
                // `Transaction.updates` une fois l'achat approuvé.
                lastError = String(localized: "Achat en attente d'approbation — la place s'ajoutera dès l'accord.")
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = String(localized: "Achat impossible — \(error.localizedDescription)")
            return false
        }
    }

    /// Restauration explicite. Les consommables ne se « restaurent » pas au sens
    /// classique : c'est `Transaction.all` qui porte leur historique, relu par
    /// `refresh()`. `sync()` sert surtout au déverrouillage illimité et à forcer
    /// une réauthentification quand l'historique local est vide.
    func restore() async {
        do {
            try await StoreKit.AppStore.sync()
            lastError = nil
        } catch {
            lastError = String(localized: "Restauration impossible — \(error.localizedDescription)")
        }
        await refresh()
    }

    // MARK: Droits

    /// Recalcule les droits depuis l'historique App Store.
    ///
    /// Le décompte local ne redescend jamais : Apple ne garantit pas de
    /// conserver indéfiniment l'historique des consommables, et perdre des
    /// places payées est une faute bien plus grave que d'en laisser une de trop
    /// après un remboursement.
    func refresh() async {
        var tally = 0
        var unlimitedFound = false
        for await result in StoreKit.Transaction.all {
            guard let transaction = try? result.payloadValue,
                  transaction.revocationDate == nil else { continue }
            if transaction.productID == SlotProduct.unlimited {
                unlimitedFound = true
            } else {
                tally += SlotProduct.slots(transaction.productID) * transaction.purchasedQuantity
            }
        }
        apply(slots: max(purchasedSlots, tally), unlimited: unlimited || unlimitedFound)
    }

    /// Crédite immédiatement l'achat qui vient d'aboutir, sans attendre que
    /// l'historique le reflète — l'utilisateur doit voir sa place tout de suite.
    private func credit(_ transaction: StoreKit.Transaction) {
        if transaction.productID == SlotProduct.unlimited {
            apply(slots: purchasedSlots, unlimited: true)
        } else {
            let added = SlotProduct.slots(transaction.productID) * transaction.purchasedQuantity
            apply(slots: purchasedSlots + added, unlimited: unlimited)
        }
    }

    private func apply(slots: Int, unlimited: Bool) {
        guard slots != purchasedSlots || unlimited != self.unlimited else { return }
        purchasedSlots = slots
        self.unlimited = unlimited
        onChange?(slots, unlimited)
    }
}
