import Foundation
import Security

// MARK: - Clés API → trousseau
//
// Deux trousseaux coexistent sur macOS. Le trousseau historique attache à
// chaque élément la liste des applications autorisées, identifiées par leur
// signature de code : une recompilation produit une signature différente, et le
// système redemande alors l'autorisation à l'utilisateur. Le trousseau protégé,
// celui d'iOS, s'appuie sur les entitlements de signature — pas de liste par
// binaire, donc pas de fenêtre.
//
// Tout passe donc par le trousseau protégé. L'ancien n'est lu qu'une fois, au
// premier lancement après la bascule, pour y récupérer les clés d'une version
// antérieure : cette lecture-là coûte une autorisation, et c'est la dernière.

enum KeychainStore {

    /// Même préfixe que l'App Group, dont il dérive : sans ça un fork écrirait
    /// ses clés sous l'identifiant de l'app d'origine.
    private static let service: String = {
        let group = SharedState.groupID
        return group.hasPrefix("group.")
            ? String(group.dropFirst("group.".count))
            : group
    }()

    private static let migrationFlag = "keychainMigratedToDataProtection"

    private static func query(_ account: String, modern: Bool = true) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: modern,
        ]
    }

    static func set(_ value: String, for account: String) {
        delete(account)
        guard !value.isEmpty else { return }
        var item = query(account)
        item[kSecValueData as String] = Data(value.utf8)
        // AfterFirstUnlock : le rafraîchissement de fond interroge les services
        // appareil verrouillé, `WhenUnlocked` le ferait échouer.
        // ThisDeviceOnly : jamais dans une sauvegarde ni sur iCloud.
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    static func get(_ account: String) -> String? {
        read(account)
    }

    static func delete(_ account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }

    // MARK: Reprise des clés de l'ancien trousseau

    /// Déplace une fois pour toutes les clés écrites par une version
    /// antérieure. L'ancien trousseau est énuméré plutôt que sondé identifiant
    /// par identifiant : une liste reconstruite depuis la configuration laisse
    /// derrière elle les services supprimés, renommés ou importés autrement.
    ///
    /// L'indicateur est posé quoi qu'il arrive : chaque lecture de l'ancien
    /// trousseau réclame une autorisation à l'utilisateur, et réessayer au
    /// lancement suivant transformerait cette gêne unique en boucle.
    static func migrateFromLegacyIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationFlag) else { return }
        defaults.set(true, forKey: migrationFlag)

        // L'ancien trousseau refuse `kSecReturnData` dès que la requête porte
        // sur plusieurs éléments : on énumère donc les attributs, puis on lit
        // chaque clé séparément.
        let search: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: false,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(search as CFDictionary, &out) == errSecSuccess,
              let items = out as? [[String: Any]] else { return }

        for item in items {
            guard let account = item[kSecAttrAccount as String] as? String else { continue }
            if let value = read(account, modern: false) {
                set(value, for: account)
            }
            // Effacé même si la lecture a échoué : sans ça l'élément resterait
            // à demander une autorisation que plus rien ne viendra accorder.
            SecItemDelete(query(account, modern: false) as CFDictionary)
        }
    }

    private static func read(_ account: String, modern: Bool = true) -> String? {
        var item = query(account, modern: modern)
        item[kSecReturnData as String] = true
        item[kSecMatchLimit as String] = kSecMatchLimitOne

        var out: AnyObject?
        guard SecItemCopyMatching(item as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
