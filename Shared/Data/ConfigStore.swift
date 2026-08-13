import Foundation

// MARK: - Persistance de la configuration (mode, services ajoutés/importés)
// services.yaml reste la source de vérité côté échange ; ici on persiste
// l'état courant en JSON dans Application Support.

enum DataMode: String, Codable {
    /// Simulateur du prototype (random-walk, panne Komga scénarisée).
    case demo
    /// Vraies requêtes vers le homelab.
    case live
}

struct StoredService: Codable {
    var id: String
    var mono: String
    var name: String
    var desc: String
    var group: Int
    var url: String
    var iconSlug: String?
    var type: String
    var apiURL: String?

    init(service: Service, type: IntegrationType) {
        id = service.id
        mono = service.mono
        name = service.name
        desc = service.desc
        group = service.group
        url = service.url
        iconSlug = service.iconSlug
        self.type = type.rawValue
        apiURL = service.apiURL
    }

    var service: Service {
        Service(id: id, mono: mono, name: name, desc: desc, group: group,
                url: url, iconSlug: iconSlug, metrics: nil, apiURL: apiURL)
    }
}

/// Notification archivée. `NotifItem` porte un `id` non décodable (UUID
/// généré) : on persiste le contenu, l'identité est recréée au chargement.
struct StoredNotif: Codable {
    var title: String
    var sub: String
    var date: Date
    var alert: Bool
    var unread: Bool

    init(_ item: NotifItem) {
        title = item.title
        sub = item.sub
        date = item.date
        alert = item.alert
        unread = item.unread
    }

    var item: NotifItem {
        NotifItem(title: title, sub: sub, date: date, alert: alert, unread: unread)
    }
}

/// Panne observée (mode Homelab) — alimente le mur de statut 30 j.
struct StoredOutage: Codable {
    var serviceID: String
    var start: Date
    var end: Date?
}

struct AppConfig: Codable {
    var dataMode: DataMode = .demo
    /// Services ajoutés à la main (bouton « + »).
    var custom: [StoredService] = []
    /// Import services.yaml : remplace le catalogue de démo.
    var importedGroups: [String]?
    var importedServices: [StoredService]?
    /// Services épinglés (widget, barre de menus).
    var pins: [String]?
    /// Pannes observées (30 jours glissants).
    var outages: [StoredOutage]?
    /// Historique des notifications, plus récente d'abord (borné à 60).
    var notifs: [StoredNotif]?
    /// Interrupteurs de la section Alertes.
    var alertRules: [String: Bool]?
    /// Volumes exclus de l'alerte disque, clés « idService|idVolume » — un
    /// montage plein par nature ne doit pas rejouer à chaque lancement.
    var mutedVolumes: [String]?
    /// Dernier relevé effectué par l'app. Sert à refermer une panne restée
    /// ouverte parce que l'app a été quittée avant le retour du service : le
    /// temps où personne ne regardait n'est imputé à aucun service.
    var lastTick: Date?
    /// Places de service achetées (achats intégrés). Cache local : la source de
    /// vérité reste l'App Store, relue au lancement par `Billing.refresh()`.
    /// Sert hors ligne et au premier affichage, avant la réponse de StoreKit.
    ///
    /// Optionnel comme tous les champs ajoutés après coup : le décodeur
    /// synthétisé n'applique pas les valeurs par défaut, un champ non optionnel
    /// ferait échouer la lecture de toutes les configurations existantes.
    var purchasedSlots: Int?
    /// Déverrouillage illimité (achat non consommable).
    var unlimitedUnlocked: Bool?
    /// Clés API par id de service. **Hérité** : les clés vivent dans le
    /// trousseau. Ce champ n'est plus écrit, il n'est lu qu'une fois au
    /// lancement, le temps de verser les configurations antérieures
    /// (`migrateKeysToKeychain`), puis effacé.
    var apiKeys: [String: String]?
}

enum ConfigStore {
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Specula", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }

    static func load() -> AppConfig {
        migrateFromBaieIfNeeded()
        guard let data = try? Data(contentsOf: fileURL),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return AppConfig()
        }
        return config
    }

    /// L'app s'est appelée « Baie » puis « Fanal » — on récupère la config
    /// existante la plus récente une fois.
    private static func migrateFromBaieIfNeeded() {
        guard !FileManager.default.fileExists(atPath: fileURL.path) else { return }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        for oldName in ["Fanal", "Baie"] {
            let old = appSupport
                .appendingPathComponent(oldName, isDirectory: true)
                .appendingPathComponent("config.json")
            if FileManager.default.fileExists(atPath: old.path) {
                try? FileManager.default.copyItem(at: old, to: fileURL)
                return
            }
        }
    }

    static func save(_ config: AppConfig) {
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
