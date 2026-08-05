import Foundation
import Security

// MARK: - Clés API → trousseau
//
// Deux trousseaux coexistent sur macOS. Le trousseau historique attache à
// chaque élément une liste des applications autorisées, identifiées par leur
// signature : une recompilation produit une signature différente, et le système
// redemande l'autorisation à l'utilisateur. Le trousseau protégé, celui d'iOS,
// s'appuie sur les entitlements de signature — pas de liste par binaire, donc
// pas de boîte de dialogue.
//
// On écrit donc dans le trousseau protégé, et on ne lit l'ancien que pour y
// récupérer ce qui s'y trouve encore, une fois, avant de l'y effacer.

enum KeychainStore {

    /// Même préfixe que l'App Group, dont il dérive : sans ça un fork écrirait
    /// ses clés sous l'identifiant de l'app d'origine.
    private static let service: String = {
        let group = SharedState.groupID
        return group.hasPrefix("group.")
            ? String(group.dropFirst("group.".count))
            : group
    }()

    private static func query(_ account: String, modern: Bool) -> [String: Any] {
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
        var item = query(account, modern: true)
        item[kSecValueData as String] = Data(value.utf8)
        // AfterFirstUnlock : le rafraîchissement de fond interroge les services
        // appareil verrouillé, `WhenUnlocked` le ferait échouer.
        // ThisDeviceOnly : jamais dans une sauvegarde ni sur iCloud.
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        guard SecItemAdd(item as CFDictionary, nil) != errSecSuccess else { return }
        // Le trousseau protégé réclame une signature avec entitlements : une
        // build ad-hoc n'y a pas droit. Perdre la clé serait pire que la
        // fenêtre d'autorisation, on retombe donc sur l'ancien trousseau.
        var legacy = query(account, modern: false)
        legacy[kSecValueData as String] = Data(value.utf8)
        legacy[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(legacy as CFDictionary, nil)
    }

    static func get(_ account: String) -> String? {
        if let value = read(account, modern: true) { return value }
        // Clé écrite par une version antérieure : on la déplace au passage,
        // pour que la fenêtre d'autorisation ne revienne pas au lancement
        // suivant.
        guard let legacy = read(account, modern: false) else { return nil }
        set(legacy, for: account)
        return legacy
    }

    static func delete(_ account: String) {
        SecItemDelete(query(account, modern: true) as CFDictionary)
        SecItemDelete(query(account, modern: false) as CFDictionary)
    }

    private static func read(_ account: String, modern: Bool) -> String? {
        var item = query(account, modern: modern)
        item[kSecReturnData as String] = true
        item[kSecMatchLimit as String] = kSecMatchLimitOne

        var out: AnyObject?
        guard SecItemCopyMatching(item as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
