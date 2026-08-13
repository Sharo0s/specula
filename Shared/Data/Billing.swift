import Foundation
import Observation
import StoreKit

// MARK: - Achats intégrés (StoreKit 2)
//
// Modèle : les quatre premiers services sont offerts, les suivants s'achètent.
// Deux produits, à déclarer dans App Store Connect avec ces identifiants :
//
//   <bundle>.slot.one    consommable      une place de service
//   <bundle>.unlimited   non consommable  places illimitées
//
// Pas de pack : StoreKit vend plusieurs exemplaires d'un consommable en une
// seule transaction (`PurchaseOption.quantity`). Un pack n'apporterait qu'une
// remise à justifier et une fiche de plus à tenir, là où un sélecteur de
// quantité donne le même confort avec un prix strictement linéaire.
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
    static var unlimited: String { prefix + ".unlimited" }

    /// Ordre d'affichage de la boutique : les places d'abord, l'illimité ensuite.
    static var all: [String] { [one, unlimited] }

    /// Exemplaires achetables en une transaction. L'App Store borne la quantité
    /// d'un consommable ; au-delà, StoreKit refuse l'achat. Mieux vaut arrêter
    /// le sélecteur avant que l'utilisateur ne bute dessus.
    ///
    /// À confirmer au simulateur : la valeur n'est pas lisible depuis le code,
    /// et 10 est la limite historique de l'App Store.
    static let maxQuantity = 10

    /// Places débloquées par un exemplaire du produit (0 pour l'illimité, qui
    /// ne se compte pas en places).
    static func slots(_ id: String) -> Int {
        id == one ? 1 : 0
    }
}

/// Décompte des places dans le stockage clé-valeur iCloud.
///
/// Apple documente les consommables comme non restaurables et renvoie le
/// développeur vers son propre serveur : `Transaction.all` remonte bien leur
/// historique en pratique, mais rien ne l'y engage. Or la boutique promet
/// qu'une place reste acquise — la promesse ne peut pas reposer sur ce qu'un
/// fournisseur refuse de garantir.
///
/// Quelques octets suffisent donc à couvrir la réinstallation et le changement
/// d'appareil, sans serveur à tenir ni compte à créer : l'utilisateur est déjà
/// connecté à iCloud. Le même conteneur sert à l'iPhone et au Mac, qui
/// partagent l'identifiant d'app — une place achetée d'un côté vaut de l'autre.
private enum CloudSlots {
    private static let slotsKey = "purchasedSlots"
    private static let unlimitedKey = "unlimitedUnlocked"
    private static var store: NSUbiquitousKeyValueStore { .default }

    static var slots: Int { Int(store.longLong(forKey: slotsKey)) }
    static var unlimited: Bool { store.bool(forKey: unlimitedKey) }

    static func save(slots: Int, unlimited: Bool) {
        store.set(Int64(slots), forKey: slotsKey)
        store.set(unlimited, forKey: unlimitedKey)
        store.synchronize()
    }

    /// Réclame la dernière version connue du serveur au lancement.
    static func start() {
        store.synchronize()
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
    /// Écoute du stockage iCloud — un achat fait sur l'iPhone doit apparaître
    /// sur le Mac sans attendre un relancement.
    private var cloudTask: Task<Void, Never>?

    init(purchasedSlots: Int = 0, unlimited: Bool = false) {
        CloudSlots.start()
        // Trois sources, jamais l'une contre l'autre : le cache local pour
        // l'affichage immédiat et le hors-ligne, iCloud pour l'appareil neuf,
        // l'historique App Store pour le reste. On retient toujours la plus
        // généreuse — voir `refresh()`.
        self.purchasedSlots = max(0, max(purchasedSlots, CloudSlots.slots))
        self.unlimited = unlimited || CloudSlots.unlimited
        updatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else { return }
                guard let transaction = try? update.payloadValue else { continue }
                await transaction.finish()
                await self.refresh()
            }
        }
        cloudTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: NSUbiquitousKeyValueStore.didChangeExternallyNotification) {
                guard let self else { return }
                self.mergeCloud()
            }
        }
    }

    /// Reprend ce qu'un autre appareil a acheté.
    private func mergeCloud() {
        apply(slots: max(purchasedSlots, CloudSlots.slots),
              unlimited: unlimited || CloudSlots.unlimited)
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

    /// Prix de `quantity` exemplaires, formaté par l'App Store. Le calcul passe
    /// par `Product.price` et son format de devise plutôt que par la chaîne
    /// `displayPrice` : multiplier un texte déjà mis en forme donnerait des
    /// séparateurs faux dès qu'on dépasse le millier.
    func displayTotal(_ offerID: String, quantity: Int) -> String {
        guard let product = products.first(where: { $0.id == offerID }) else { return "" }
        guard quantity > 1 else { return product.displayPrice }
        return (product.price * Decimal(quantity)).formatted(product.priceFormatStyle)
    }

    // MARK: Achat

    @discardableResult
    func purchase(offerID: String, quantity: Int = 1) async -> Bool {
        guard let product = products.first(where: { $0.id == offerID }) else { return false }
        return await purchase(product, quantity: quantity)
    }

    /// `true` si l'achat a été conclu et crédité.
    @discardableResult
    func purchase(_ product: Product, quantity: Int = 1) async -> Bool {
        guard purchasing == nil else { return false }
        purchasing = product.id
        defer { purchasing = nil }
        do {
            // `quantity` ne vaut que pour un consommable : StoreKit rejette
            // l'option sur un non consommable, qui ne s'achète qu'une fois.
            var options: Set<Product.PurchaseOption> = []
            if product.type == .consumable, quantity > 1 {
                options.insert(.quantity(min(quantity, SlotProduct.maxQuantity)))
            }
            switch try await product.purchase(options: options) {
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

    /// Recalcule les droits en confrontant les trois sources.
    ///
    /// Le décompte ne redescend jamais, et c'est délibéré : chaque source peut
    /// manquer à l'appel — le cache local disparaît à la réinstallation, iCloud
    /// est muet si l'utilisateur en est déconnecté, et Apple ne garantit pas de
    /// conserver indéfiniment l'historique des consommables. Il faudrait donc
    /// que les trois défaillent en même temps pour qu'une place payée se perde.
    ///
    /// Le prix de cette prudence est qu'un remboursement ne retire pas la place
    /// localement. C'est le bon côté où se tromper.
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
        apply(slots: max(purchasedSlots, max(tally, CloudSlots.slots)),
              unlimited: unlimited || unlimitedFound || CloudSlots.unlimited)
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
        // La garde ci-dessus suffit à couper toute boucle : iCloud ne notifie
        // que les écritures venues d'un autre appareil, et une valeur déjà à
        // jour ne repasse pas par ici.
        CloudSlots.save(slots: slots, unlimited: unlimited)
        onChange?(slots, unlimited)
    }
}
