import Foundation

// MARK: - Modèle (README « State Management »)

/// Une instance de serveur (multi-instances : NAS principal / Seedbox — OVH).
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
}

struct IncidentSelection: Equatable {
    let service: String
    let when: String
    let duration: String
    let cause: String
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
enum NetMode: String, CaseIterable { case local, tailscale }
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
    static let seedServer = Server(id: "seed", name: String(localized: "Seedbox — OVH"),
                                   groups: [String(localized: "Téléchargement"), String(localized: "Média"), String(localized: "Système")])

    static let cdn = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/"

    static let services: [Service] = [
        Service(id: "jellyfin", mono: "Jf", name: "Jellyfin", desc: "Serveur multimédia", group: 0, url: "jellyfin.local:8096", iconSlug: "jellyfin", metrics: [["516", "Films"], ["202", "Séries"], ["8 335", "Épisodes"]]),
        Service(id: "radarr", mono: "Ra", name: "Radarr", desc: "Gestion films", group: 0, url: "radarr.local:7878", iconSlug: "radarr", metrics: [["15", "Manquants"], ["2", "En attente"], ["516", "Films"]]),
        Service(id: "sonarr", mono: "So", name: "Sonarr", desc: "Gestion séries", group: 0, url: "sonarr.local:8989", iconSlug: "sonarr", metrics: [["202", "Séries"], ["2", "En attente"], ["0", "Recherché"]]),
        Service(id: "transmission", mono: "Tr", name: "Transmission", desc: "Client BitTorrent", group: 0, url: "nas.local:9091", iconSlug: "transmission", metrics: nil),
        Service(id: "komga", mono: "Ko", name: "Komga", desc: "Comics, livres & mangas", group: 0, url: "komga.local:25600", iconSlug: "komga", metrics: [["3", "Bibliothèques"], ["75", "Séries"], ["852", "Livres"]]),
        Service(id: "immich", mono: "Im", name: "Immich", desc: "Photothèque", group: 0, url: "immich.local:2283", iconSlug: "immich", metrics: [["10 967", "Photos"], ["314", "Vidéos"], ["112 Go", "Stockage"]]),
        Service(id: "unifi", mono: "Un", name: "UniFi Controller", desc: "Réseau UniFi", group: 1, url: "unifi.local:8443", iconSlug: "unifi", metrics: [["6", "LAN"], ["35", "WLAN"], ["15,2 j", "Uptime"]]),
        Service(id: "adguard", mono: "Ad", name: "AdGuard Home", desc: "DNS filtrant — nouveau", group: 1, url: "192.168.1.2:3000", iconSlug: "adguard-home", metrics: [["42 310", "Requêtes / j"], ["18 %", "Bloquées"], ["2", "Clients DNS"]]),
        Service(id: "homeassistant", mono: "Ha", name: "Home Assistant", desc: "Domotique", group: 1, url: "ha.local:8123", iconSlug: "home-assistant", metrics: nil),
        Service(id: "uptimekuma", mono: "Uk", name: "Uptime Kuma", desc: "Surveillance — nouveau", group: 1, url: "kuma.local:3001", iconSlug: "uptime-kuma", metrics: nil),
        Service(id: "proxmox", mono: "Px", name: "Proxmox VE", desc: "Hyperviseur — nouveau", group: 2, url: "pve.local:8006", iconSlug: "proxmox", metrics: [["3", "VM"], ["5", "Conteneurs"], ["64 Go", "RAM"]]),
        Service(id: "omv", mono: "Om", name: "OpenMediaVault", desc: "NAS principal", group: 2, url: "nas.local", iconSlug: "openmediavault", metrics: [["284 Go", "Libres"], ["501 Go", "Total"], ["4", "Partages"]]),
        Service(id: "nextcloud", mono: "Nc", name: "Nextcloud", desc: "Cloud personnel", group: 2, url: "cloud.smalard.ovh", iconSlug: "nextcloud", metrics: [["264 Gio", "Libres"], ["992", "Fichiers"], ["1", "Utilisateur"]]),
        Service(id: "filebrowser", mono: "Fb", name: "FileBrowser", desc: "Fichiers NAS + Mini-NAS", group: 2, url: "files.local:8080", iconSlug: "filebrowser", metrics: [["12 340", "Fichiers"], ["2", "Sources"], ["1", "Utilisateur"]]),
        Service(id: "vaultwarden", mono: "Vw", name: "Vaultwarden", desc: "Mots de passe — nouveau", group: 3, url: "vault.local:8222", iconSlug: "vaultwarden", metrics: [["128", "Éléments"], ["6", "Collections"], ["2", "Utilisateurs"]]),
        Service(id: "paperless", mono: "Pp", name: "Paperless-ngx", desc: "Documents — nouveau", group: 3, url: "docs.local:8010", iconSlug: "paperless-ngx", metrics: [["1 240", "Documents"], ["36", "Étiquettes"], ["12", "À trier"]]),
        Service(id: "kan", mono: "Ka", name: "Kan", desc: "Kanban & projets", group: 3, url: "kan.local:3000", iconSlug: nil, metrics: [["4", "Tableaux"], ["23", "Cartes"], ["6", "En cours"]]),
    ]

    static let seedServices: [Service] = [
        Service(id: "seed-qbit", mono: "Qb", name: "qBittorrent", desc: "Client BitTorrent", group: 0, url: "seed.ovh:8080", iconSlug: "qbittorrent", metrics: nil),
        Service(id: "seed-radarr", mono: "Ra", name: "Radarr", desc: "Gestion films — seedbox", group: 0, url: "seed.ovh:7878", iconSlug: "radarr", metrics: [["8", "Manquants"], ["1", "En attente"], ["214", "Films"]]),
        Service(id: "seed-plex", mono: "Pl", name: "Plex", desc: "Serveur multimédia", group: 1, url: "seed.ovh:32400", iconSlug: "plex", metrics: [["214", "Films"], ["48", "Séries"], ["2", "Lectures"]]),
        Service(id: "seed-traefik", mono: "Tk", name: "Traefik", desc: "Reverse proxy", group: 2, url: "seed.ovh:8081", iconSlug: "traefik", metrics: [["12", "Routes"], ["9", "Certificats"], ["0", "Erreurs"]]),
        Service(id: "seed-glances", mono: "Gl", name: "Glances", desc: "Monitoring VPS", group: 2, url: "seed.ovh:61208", iconSlug: "glances", metrics: [["4", "vCPU"], ["8 Go", "RAM"], ["1,2 To", "Disque"]]),
    ]

    static let all: [Service] = services + seedServices

    static let defaultPins = ["jellyfin", "homeassistant", "nextcloud", "unifi"]

    /// Chips proposées au partage famille.
    static let guestChoices = ["jellyfin", "immich", "komga", "nextcloud"]

    static let seedNotifs: [NotifItem] = [
        NotifItem(title: String(localized: "Sauvegarde terminée"), sub: String(localized: "OpenMediaVault — 284 Go vérifiés"),
                  date: Date().addingTimeInterval(-45 * 60), alert: false, unread: false),
        NotifItem(title: String(localized: "Mise à jour disponible"), sub: "Sonarr 4.0.3 → 4.0.4",
                  date: Date().addingTimeInterval(-3 * 3600), alert: false, unread: false),
        NotifItem(title: String(localized: "Nouvel épisode récupéré"), sub: String(localized: "Radarr — 2 films ajoutés à Jellyfin"),
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
        Incident(serviceID: "komga", day: 7, duration: "38 min", cause: String(localized: "Conteneur arrêté — OOM killer")),
        Incident(serviceID: "komga", day: 21, duration: "12 min", cause: String(localized: "Mise à jour de l'image Docker")),
        Incident(serviceID: "nextcloud", day: 12, duration: "26 min", cause: String(localized: "Certificat TLS expiré")),
        Incident(serviceID: "uptimekuma", day: 3, duration: "8 min", cause: String(localized: "Redémarrage du NAS")),
    ]

    /// Type d'intégration des services du catalogue.
    static let typeByID: [String: IntegrationType] = [
        "jellyfin": .jellyfin, "radarr": .radarr, "sonarr": .sonarr,
        "transmission": .transmission, "komga": .komga, "immich": .immich,
        "unifi": .unifi, "adguard": .adguard, "homeassistant": .homeassistant,
        "uptimekuma": .uptimekuma, "proxmox": .proxmox, "omv": .omv,
        "nextcloud": .nextcloud, "filebrowser": .filebrowser,
        "vaultwarden": .vaultwarden, "paperless": .paperless, "kan": .generic,
        "seed-qbit": .qbittorrent, "seed-radarr": .radarr, "seed-plex": .plex,
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
