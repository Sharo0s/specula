import Foundation
import Testing
@testable import Specula

// MARK: - Quota de services (achats intégrés)
// L'arithmétique du modèle « quatre offerts, les suivants à l'unité » vit dans
// `ServiceQuota`, sans StoreKit : c'est ce qui la rend vérifiable ici. La
// couche `Billing` (achat, historique App Store) réclame une vraie boutique et
// n'est pas testable hors simulateur.

@Suite("Quota de services")
struct QuotaTests {

    @Test("Quatre services offerts")
    func fourFreeServices() {
        // La valeur est reprise mot pour mot dans les Réglages des deux
        // plateformes (« Les 4 premiers services sont offerts »), où
        // l'interpolation casserait l'extraction du catalogue de traduction.
        // La changer ici sans reprendre ces libellés serait un mensonge.
        #expect(ServiceQuota.free == 4)
        #expect(ServiceQuota().capacity == 4)
    }

    @Test("Chaque place achetée agrandit le quota d'une unité")
    func purchasedSlotsAddUp() {
        #expect(ServiceQuota(purchasedSlots: 1).capacity == 5)
        #expect(ServiceQuota(purchasedSlots: 3).capacity == 7)
        #expect(ServiceQuota(purchasedSlots: 16).capacity == 20)
    }

    @Test("Un décompte négatif ne rogne pas les services offerts")
    func negativeSlotsClamped() {
        // Une configuration corrompue ne doit pas retirer ce qui est gratuit.
        #expect(ServiceQuota(purchasedSlots: -3).capacity == 4)
    }

    @Test("Le déverrouillage illimité lève la limite")
    func unlimitedHasNoCapacity() {
        let quota = ServiceQuota(purchasedSlots: 0, unlimited: true)
        #expect(quota.capacity == nil)
        #expect(quota.remaining(current: 250) == nil)
        #expect(quota.allowsAdding(current: 250))
    }

    @Test("La cinquième place est refusée sans achat")
    func fifthServiceBlocked() {
        let quota = ServiceQuota()
        #expect(quota.allowsAdding(current: 3))
        #expect(quota.allowsAdding(current: 4) == false)
    }

    @Test("Une place achetée débloque exactement un service de plus")
    func oneSlotUnlocksOne() {
        let quota = ServiceQuota(purchasedSlots: 1)
        #expect(quota.allowsAdding(current: 4))
        #expect(quota.allowsAdding(current: 5) == false)
    }

    @Test("Les places restantes ne passent jamais sous zéro")
    func remainingNeverNegative() {
        // Cas réel : l'utilisateur avait vingt services, puis a été remboursé.
        // La liste existante n'est pas amputée, mais plus rien ne s'ajoute.
        let quota = ServiceQuota()
        #expect(quota.remaining(current: 0) == 4)
        #expect(quota.remaining(current: 4) == 0)
        #expect(quota.remaining(current: 20) == 0)
        #expect(quota.allowsAdding(current: 20) == false)
    }
}

@Suite("Troncature de l'import services.yaml")
struct ImportQuotaTests {

    // Un services.yaml plus gros que le quota est importé jusqu'à la limite
    // plutôt que rejeté en bloc : le fichier reste la source de vérité, et
    // l'utilisateur voit tout de suite ce qui manque.

    @Test("Un fichier plus petit que le quota passe entier")
    func smallFileUntouched() {
        #expect(ServiceQuota().acceptableCount(3) == 3)
        #expect(ServiceQuota().acceptableCount(4) == 4)
    }

    @Test("Un fichier plus gros est tronqué au quota")
    func largeFileTruncated() {
        #expect(ServiceQuota().acceptableCount(17) == 4)
        #expect(ServiceQuota(purchasedSlots: 5).acceptableCount(17) == 9)
    }

    @Test("Le déverrouillage illimité importe tout")
    func unlimitedTakesEverything() {
        #expect(ServiceQuota(unlimited: true).acceptableCount(17) == 17)
    }

    @Test("Les services déjà configurés comptent dans le calcul")
    func currentServicesCountAgainstTheFile() {
        let quota = ServiceQuota(purchasedSlots: 2)   // 6 places
        #expect(quota.acceptableCount(10, current: 4) == 2)
        #expect(quota.acceptableCount(10, current: 6) == 0)
        #expect(quota.acceptableCount(1, current: 9) == 0)
    }
}
