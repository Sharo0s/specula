import Foundation

// MARK: - Modèle (README « State Management »)

/// Une instance de serveur (multi-instances : NAS principal / VPS — Hetzner).
struct Server: Identifiable, Hashable {
    let id: String
    let name: String
    let groups: [String]
}

/// Un service selfhosted du dashboard.
struct Service: Identifiable, Hashable {
    let id: String
    /// Monogramme 2 lettres, secours quand le pictogramme est absent ou désactivé.
    let mono: String
    let name: String
    let desc: String
    /// Index du groupe dans `Server.groups`.
    let group: Int
    let url: String
    /// Slug dashboard-icons (`jellyfin.png`…) ; nil = monogramme seul (Kan).
    let iconSlug: String?
    /// Métriques statiques [valeur, libellé] ; nil = calculées en direct.
    let metrics: [[String]]?
    /// URL de l'API si différente du href (gethomepage : `widget.url`).
    var apiURL: String? = nil
}

struct NotifItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let sub: String
    let date: Date
    let alert: Bool
    var unread: Bool

    /// « à l'instant », « 14:38 », ou « 18 juil. · 21:40 » selon l'ancienneté.
    var timeLabel: String {
        if Date().timeIntervalSince(date) < 60 { return String(localized: "à l'instant") }
        if Calendar.current.isDateInToday(date) {
            return date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
        }
        return date.formatted(.dateTime
            .day().month(.abbreviated).hour(.twoDigits(amPM: .omitted)).minute())
    }
}

/// Incident du mur de disponibilité 30 j.
struct Incident: Hashable {
    let serviceID: String
    /// Index du jour (0 = J-29 … 29 = aujourd'hui).
    let day: Int
    let duration: String
    let cause: String
    /// Durée en minutes — le texte est formaté pour l'affichage (séparateur de
    /// milliers compris) et ne doit jamais servir à recalculer quoi que ce soit.
    var minutes: Double = 0

    init(serviceID: String, day: Int, duration: String, cause: String, minutes: Double = 0) {
        self.serviceID = serviceID
        self.day = day
        self.duration = duration
        self.cause = cause
        self.minutes = minutes
    }
}

struct IncidentSelection: Equatable {
    let service: String
    let when: String
    let duration: String
    let cause: String
}

/// Quota de services — les quatre premiers sont offerts, les suivants se
/// débloquent à l'unité (achats intégrés, cf. `Billing`).
///
/// Structure sans dépendance à StoreKit : c'est elle qui porte l'arithmétique
/// du modèle, et elle se teste sans boutique.
struct ServiceQuota: Equatable {
    /// Services configurables sans rien payer.
    static let free = 4

    var purchasedSlots: Int = 0
    var unlimited: Bool = false

    /// Nombre total de services configurables — `nil` si illimité.
    var capacity: Int? {
        unlimited ? nil : Self.free + max(0, purchasedSlots)
    }

    /// Reste-t-il une place quand `current` services sont déjà configurés ?
    func allowsAdding(current: Int) -> Bool {
        guard let capacity else { return true }
        return current < capacity
    }

    /// Places libres — `nil` si illimité.
    func remaining(current: Int) -> Int? {
        guard let capacity else { return nil }
        return max(0, capacity - current)
    }

    /// Combien d'une fournée de `count` services tiennent dans le quota, sachant
    /// que `current` sont déjà là. Sert à l'import services.yaml, qui tronque
    /// plutôt que d'échouer en bloc.
    func acceptableCount(_ count: Int, current: Int = 0) -> Int {
        guard let remaining = remaining(current: current) else { return count }
        return min(count, remaining)
    }
}

enum Density: String, CaseIterable { case aere, compact }
enum LayoutMode: String, CaseIterable { case grille, liste }

/// Type d'intégration (API propre à chaque service selfhosted).
enum IntegrationType: String, Codable, CaseIterable {
    case jellyfin, radarr, sonarr, adguard, transmission, proxmox, immich, glances
    case homeassistant, uptimekuma, nextcloud, vaultwarden, paperless, komga
    case filebrowser, unifi, omv, plex, qbittorrent, traefik, generic
    case pihole, portainer, sabnzbd, prowlarr, lidarr, readarr, bazarr
    case overseerr, tautulli, gitea, grafana, syncthing, audiobookshelf
    case navidrome, frigate, kavita, mealie, miniflux, linkding, speedtest
    case scrutiny, netdata, gotify, authentik, truenas, octoprint, esphome
    case ollama, npm, wgeasy, jackett, deluge, photoprism, gitlab, peertube
    case bookstack, fireflyiii, grocy, healthchecks, changedetection
    case wordpress, ghost, matomo, n8n
}
enum DetailMetric: String, CaseIterable {
    case lat, cpu, net
    var label: String {
        switch self {
        case .lat: "Latence"
        case .cpu: "CPU"
        case .net: "Réseau"
        }
    }
}

// MARK: - Données (reprises du prototype)

enum Catalog {

    static let mainServer = Server(id: "main", name: String(localized: "NAS principal"),
                                   groups: [String(localized: "Média & Streaming"), String(localized: "Réseau & Domotique"), String(localized: "Serveurs & Stockage"), String(localized: "Outils")])
    static let seedServer = Server(id: "seed", name: String(localized: "VPS — Hetzner"),
                                   groups: [String(localized: "Web & Applis"), String(localized: "Données"), String(localized: "Système")])

    static let cdn = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/"

    static let services: [Service] = [
        Service(id: "komga", mono: "Ko", name: "Komga", desc: "Comics, livres & mangas", group: 0, url: "komga.local:25600", iconSlug: "komga", metrics: [["3", "Bibliothèques"], ["75", "Séries"], ["852", "Livres"]]),
        Service(id: "immich", mono: "Im", name: "Immich", desc: "Photothèque", group: 0, url: "immich.local:2283", iconSlug: "immich", metrics: [["10 967", "Photos"], ["314", "Vidéos"], ["112 Go", "Stockage"]]),
        Service(id: "unifi", mono: "Un", name: "UniFi Controller", desc: "Réseau UniFi", group: 1, url: "unifi.local:8443", iconSlug: "unifi", metrics: [["6", "LAN"], ["35", "WLAN"], ["15,2 j", "Uptime"]]),
        Service(id: "adguard", mono: "Ad", name: "AdGuard Home", desc: "DNS filtrant — nouveau", group: 1, url: "192.168.1.2:3000", iconSlug: "adguard-home", metrics: [["42 310", "Requêtes / j"], ["18 %", "Bloquées"], ["2", "Clients DNS"]]),
        Service(id: "homeassistant", mono: "Ha", name: "Home Assistant", desc: "Domotique", group: 1, url: "ha.local:8123", iconSlug: "home-assistant", metrics: nil),
        Service(id: "uptimekuma", mono: "Uk", name: "Uptime Kuma", desc: "Surveillance — nouveau", group: 1, url: "kuma.local:3001", iconSlug: "uptime-kuma", metrics: nil),
        Service(id: "proxmox", mono: "Px", name: "Proxmox VE", desc: "Hyperviseur — nouveau", group: 2, url: "pve.local:8006", iconSlug: "proxmox", metrics: [["3", "VM"], ["5", "Conteneurs"], ["64 Go", "RAM"]]),
        Service(id: "omv", mono: "Om", name: "OpenMediaVault", desc: "NAS principal", group: 2, url: "nas.local", iconSlug: "openmediavault", metrics: [["284 Go", "Libres"], ["501 Go", "Total"], ["4", "Partages"]]),
        Service(id: "nextcloud", mono: "Nc", name: "Nextcloud", desc: "Cloud personnel", group: 2, url: "cloud.example.net", iconSlug: "nextcloud", metrics: [["264 Gio", "Libres"], ["992", "Fichiers"], ["1", "Utilisateur"]]),
        Service(id: "filebrowser", mono: "Fb", name: "FileBrowser", desc: "Fichiers NAS + Mini-NAS", group: 2, url: "files.local:8080", iconSlug: "filebrowser", metrics: [["12 340", "Fichiers"], ["2", "Sources"], ["1", "Utilisateur"]]),
        Service(id: "vaultwarden", mono: "Vw", name: "Vaultwarden", desc: "Mots de passe — nouveau", group: 3, url: "vault.local:8222", iconSlug: "vaultwarden", metrics: [["128", "Éléments"], ["6", "Collections"], ["2", "Utilisateurs"]]),
        Service(id: "paperless", mono: "Pp", name: "Paperless-ngx", desc: "Documents — nouveau", group: 3, url: "docs.local:8010", iconSlug: "paperless-ngx", metrics: [["1 240", "Documents"], ["36", "Étiquettes"], ["12", "À trier"]]),
        Service(id: "kan", mono: "Ka", name: "Kan", desc: "Kanban & projets", group: 3, url: "kan.local:3000", iconSlug: nil, metrics: [["4", "Tableaux"], ["23", "Cartes"], ["6", "En cours"]]),
    ]

    static let seedServices: [Service] = [
        Service(id: "seed-gitea", mono: "Gt", name: "Gitea", desc: "Forge Git", group: 0, url: "vps.example.net:3000", iconSlug: "gitea", metrics: [["24", "Dépôts"], ["3", "Organisations"], ["1,4 Go", "Stockage"]]),
        Service(id: "seed-matomo", mono: "Mt", name: "Matomo", desc: "Statistiques web", group: 0, url: "vps.example.net:8082", iconSlug: "matomo", metrics: [["8 420", "Visites / 30 j"], ["4", "Sites"], ["0", "Mouchard"]]),
        Service(id: "seed-syncthing", mono: "Sy", name: "Syncthing", desc: "Synchronisation de fichiers", group: 1, url: "vps.example.net:8384", iconSlug: "syncthing", metrics: [["6", "Dossiers"], ["3", "Appareils"], ["2,1 Go", "Synchronisés"]]),
        Service(id: "seed-traefik", mono: "Tk", name: "Traefik", desc: "Reverse proxy", group: 2, url: "vps.example.net:8081", iconSlug: "traefik", metrics: [["12", "Routes"], ["9", "Certificats"], ["0", "Erreurs"]]),
        Service(id: "seed-glances", mono: "Gl", name: "Glances", desc: "Monitoring VPS", group: 2, url: "vps.example.net:61208", iconSlug: "glances", metrics: [["4", "vCPU"], ["8 Go", "RAM"], ["1,2 To", "Disque"]]),
    ]

    static let all: [Service] = services + seedServices

    static let defaultPins = ["immich", "homeassistant", "nextcloud", "unifi"]

    /// Chips proposées au partage famille.
    static let guestChoices = ["immich", "komga", "nextcloud", "filebrowser"]

    static let seedNotifs: [NotifItem] = [
        NotifItem(title: String(localized: "Sauvegarde terminée"), sub: String(localized: "OpenMediaVault — 284 Go vérifiés"),
                  date: Date().addingTimeInterval(-45 * 60), alert: false, unread: false),
        NotifItem(title: String(localized: "Mise à jour disponible"), sub: "Immich 1.119.0 → 1.120.0",
                  date: Date().addingTimeInterval(-3 * 3600), alert: false, unread: false),
        NotifItem(title: String(localized: "Import terminé"), sub: String(localized: "Paperless-ngx — 12 documents à trier"),
                  date: Date().addingTimeInterval(-4 * 3600), alert: false, unread: false),
    ]

    static let logPool = [
        "INFO  GET /api/health → 200 (3 ms)",
        "INFO  Bibliothèque analysée — 0 changement",
        "DEBUG WebSocket ping/pong ok",
        "INFO  GET /api/sessions → 200 (11 ms)",
        "WARN  Cache 87 % plein — purge programmée",
        "INFO  Tâche « scan » terminée en 4,2 s",
        "DEBUG GC : 42 Mo libérés",
        "INFO  GET /api/stats → 200 (6 ms)",
        "INFO  Sauvegarde incrémentale ok",
        "DEBUG Bail DNS renouvelé (ttl 300)",
    ]

    /// Incidents historiques du mur de statut 30 j (jour 0 = J-29).
    static let incidents: [Incident] = [
        Incident(serviceID: "komga", day: 7, duration: "38 min", cause: String(localized: "Conteneur arrêté — OOM killer"), minutes: 38),
        Incident(serviceID: "komga", day: 21, duration: "12 min", cause: String(localized: "Mise à jour de l'image Docker"), minutes: 12),
        Incident(serviceID: "nextcloud", day: 12, duration: "26 min", cause: String(localized: "Certificat TLS expiré"), minutes: 26),
        Incident(serviceID: "uptimekuma", day: 3, duration: "8 min", cause: String(localized: "Redémarrage du NAS"), minutes: 8),
    ]

    /// Jours de lenteur soutenue, par service, dans le repère de `Incident.day`
    /// (0 = J-29, 29 = aujourd'hui). En mode Homelab ces jours sont observés ;
    /// ici ils sont posés à la main pour que le mur de démonstration montre les
    /// trois états et pas seulement deux.
    static let degradedDays: [String: Set<Int>] = [
        "komga": [6, 20, 22],
        "nextcloud": [11, 13],
        "proxmox": [17, 18, 19],
        "immich": [26],
        "omv": [2, 28],
    ]

    /// Type d'intégration des services du catalogue.
    static let typeByID: [String: IntegrationType] = [
        "komga": .komga, "immich": .immich,
        "unifi": .unifi, "adguard": .adguard, "homeassistant": .homeassistant,
        "uptimekuma": .uptimekuma, "proxmox": .proxmox, "omv": .omv,
        "nextcloud": .nextcloud, "filebrowser": .filebrowser,
        "vaultwarden": .vaultwarden, "paperless": .paperless, "kan": .generic,
        "seed-gitea": .gitea, "seed-matomo": .matomo, "seed-syncthing": .syncthing,
        "seed-traefik": .traefik, "seed-glances": .glances,
    ]

    struct AlertRule: Identifiable {
        let id: String
        let label: String
        let desc: String
    }

    static let alertRules: [AlertRule] = [
        AlertRule(id: "temp", label: String(localized: "Température > 50 °C"), desc: String(localized: "Alerte quand le CPU dépasse le seuil.")),
        AlertRule(id: "disk", label: String(localized: "Disque > 90 %"), desc: String(localized: "Sur chaque volume surveillé.")),
        AlertRule(id: "down", label: String(localized: "Hors ligne > 5 min"), desc: String(localized: "Après 3 tentatives échouées.")),
    ]
}

/// Nombre formaté selon la locale (virgule en français, point en anglais).
func fr(_ value: Double, _ digits: Int = 1) -> String {
    value.formatted(.number.precision(.fractionLength(digits)).grouping(.never))
}
