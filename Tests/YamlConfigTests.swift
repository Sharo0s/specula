import Testing
@testable import Specula

// MARK: - services.yaml (format gethomepage.dev)
// L'import et l'export sont la seule porte d'entrée et de sortie de la
// configuration : un service perdu à l'import, une clé oubliée à l'export, et
// l'utilisateur reconstruit tout à la main sans savoir pourquoi.

@Suite("Import services.yaml")
struct YamlImportTests {

    /// Fichier représentatif : deux groupes, une clé en clair, une clé par
    /// en-tête, un couple utilisateur/mot de passe, une variable non résolue.
    static let sample = """
    - Média & Streaming:
        - Jellyfin:
            href: http://jellyfin.local:8096
            description: Serveur multimédia
            icon: jellyfin.png
            widget:
              type: jellyfin
              url: http://jellyfin.local:8096
              key: abc123
        - Radarr:
            href: http://radarr.local:7878
            icon: radarr.png
            widget:
              type: radarr
              url: http://radarr.local:7878
              headers:
                x-api-key: header-key-456
    - Serveurs:
        - Proxmox:
            href: https://pve.local:8006
            widget:
              type: proxmox
              url: https://pve.local:8006
              username: root@pam
              password: secret
        - Immich:
            href: http://immich.local:2283
            widget:
              type: immich
              url: http://immich.local:2283
              key: {{HOMEPAGE_VAR_IMMICH_KEY}}
    """

    @Test("Les groupes gardent leur ordre et leur libellé")
    func groups() throws {
        let result = try YamlConfig.parse(Self.sample)
        #expect(result.groups == ["Média & Streaming", "Serveurs"])
    }

    @Test("Chaque service est rattaché à son groupe")
    func servicesAndGroupIndex() throws {
        let result = try YamlConfig.parse(Self.sample)
        #expect(result.services.count == 4)
        #expect(result.services.map(\.name) == ["Jellyfin", "Radarr", "Proxmox", "Immich"])
        #expect(result.services.map(\.group) == [0, 0, 1, 1])
    }

    @Test("L'URL vient de href, l'icône perd son extension")
    func urlAndIcon() throws {
        let result = try YamlConfig.parse(Self.sample)
        let jellyfin = try #require(result.services.first { $0.name == "Jellyfin" })
        #expect(jellyfin.url == "http://jellyfin.local:8096")
        #expect(jellyfin.iconSlug == "jellyfin")
        #expect(jellyfin.type == IntegrationType.jellyfin.rawValue)
    }

    @Test("La clé se lit dans widget.key, dans les en-têtes, ou dans le couple utilisateur/mot de passe")
    func keyExtraction() throws {
        let result = try YamlConfig.parse(Self.sample)
        let byName = Dictionary(uniqueKeysWithValues: result.services.map { ($0.name, $0.id) })

        #expect(result.keys[try #require(byName["Jellyfin"])] == "abc123")
        #expect(result.keys[try #require(byName["Radarr"])] == "header-key-456")
        #expect(result.keys[try #require(byName["Proxmox"])] == "root@pam:secret")
    }

    @Test("Une variable Homepage non substituée est signalée, jamais prise pour une clé")
    func unresolvedVariable() throws {
        let result = try YamlConfig.parse(Self.sample)
        let immich = try #require(result.services.first { $0.name == "Immich" })

        // Homepage résout {{HOMEPAGE_VAR_X}} depuis son .env, que l'on n'a pas.
        // Retenir la variable au lieu de la clé permet de le dire à
        // l'utilisateur ; l'enregistrer comme clé enverrait du texte au service.
        #expect(result.unresolved[immich.id] == ["HOMEPAGE_VAR_IMMICH_KEY"])
        #expect(result.keys[immich.id] == nil)
    }

    @Test("Un alias de widget retombe sur l'intégration connue")
    func aliases() throws {
        let yaml = """
        - Média:
            - Emby:
                href: http://emby.local:8096
                widget:
                  type: emby
                  url: http://emby.local:8096
            - Jellyseerr:
                href: http://seer.local:5055
                widget:
                  type: jellyseerr
                  url: http://seer.local:5055
        """
        let result = try YamlConfig.parse(yaml)
        #expect(result.services.map(\.type) == [IntegrationType.jellyfin.rawValue,
                                                IntegrationType.overseerr.rawValue])
    }

    @Test("Sans widget, le slug d'icône sert à deviner le type")
    func typeFromIconSlug() throws {
        let yaml = """
        - Média:
            - Mon serveur:
                href: http://media.local:8096
                icon: jellyfin.png
        """
        let result = try YamlConfig.parse(yaml)
        #expect(result.services[0].type == IntegrationType.jellyfin.rawValue)
    }

    @Test("Une icône donnée par URL n'est pas prise pour un slug")
    func iconURLIsNotASlug() throws {
        let yaml = """
        - Média:
            - Truc:
                href: http://truc.local
                icon: https://exemple.net/logo.png
        """
        let result = try YamlConfig.parse(yaml)
        #expect(result.services[0].iconSlug == nil)
    }

    @Test("Deux services homonymes reçoivent des identifiants distincts")
    func duplicateNames() throws {
        let yaml = """
        - A:
            - FileBrowser:
                href: http://fb1.local
        - B:
            - FileBrowser:
                href: http://fb2.local
        """
        let result = try YamlConfig.parse(yaml)
        #expect(result.services.count == 2)
        #expect(result.services[0].id != result.services[1].id)
    }

    @Test("Un fichier sans service est une erreur, pas une configuration vide")
    func emptyIsAnError() {
        // Remplacer silencieusement la configuration par rien effacerait le
        // homelab de l'utilisateur sur une faute de frappe.
        #expect(throws: (any Error).self) { try YamlConfig.parse("- Groupe vide:\n") }
        #expect(throws: (any Error).self) { try YamlConfig.parse("pas du tout du yaml: [") }
    }
}

@Suite("Export services.yaml")
struct YamlExportTests {

    static let services = [
        Service(id: "s1", mono: "Je", name: "Jellyfin", desc: "Serveur multimédia",
                group: 0, url: "jellyfin.local:8096", iconSlug: "jellyfin", metrics: nil),
        Service(id: "s2", mono: "Pv", name: "Proxmox", desc: "", group: 1,
                url: "https://pve.local:8006", iconSlug: nil, metrics: nil),
    ]
    static let types: [String: IntegrationType] = ["s1": .jellyfin, "s2": .proxmox]

    @Test("Une adresse sans schéma est complétée en http://")
    func schemeIsAdded() throws {
        let yaml = try YamlConfig.export(groups: ["Média", "Serveurs"], services: Self.services,
                                         types: Self.types, keys: [:])
        #expect(yaml.contains("http://jellyfin.local:8096"))
        // Un schéma déjà présent n'est pas doublé.
        #expect(yaml.contains("https://pve.local:8006"))
        #expect(!yaml.contains("http://https://"))
    }

    @Test("L'aller-retour conserve groupes, noms, adresses et clés")
    func roundTrip() throws {
        let yaml = try YamlConfig.export(groups: ["Média", "Serveurs"], services: Self.services,
                                         types: Self.types, keys: ["s1": "abc123"])
        let back = try YamlConfig.parse(yaml)

        #expect(back.groups == ["Média", "Serveurs"])
        #expect(back.services.map(\.name) == ["Jellyfin", "Proxmox"])
        #expect(back.services.map(\.url) == ["http://jellyfin.local:8096", "https://pve.local:8006"])
        #expect(back.services.map(\.type) == [IntegrationType.jellyfin.rawValue,
                                              IntegrationType.proxmox.rawValue])

        let jellyfin = try #require(back.services.first)
        #expect(back.keys[jellyfin.id] == "abc123")
    }

    @Test("Les accents survivent à l'export")
    func unicodeIsNotEscaped() throws {
        // Sans `allowUnicode`, Yams écrit « M\xE9dia » : lisible par un parseur,
        // plus par un humain qui relit son fichier.
        let yaml = try YamlConfig.export(groups: ["Média & Séries"], services: [],
                                         types: [:], keys: [:])
        #expect(yaml.contains("Média & Séries"))
    }

    @Test("Un export sans clés produit des variables Homepage, signalées au retour")
    func placeholderKeysRoundTrip() throws {
        // C'est le mode « exporter sans les clés » : le fichier reste
        // transportable, et un réimport signale les services en attente plutôt
        // que d'envoyer un jeton bidon au serveur.
        let yaml = try YamlConfig.export(groups: ["Média"], services: [Self.services[0]],
                                         types: Self.types,
                                         keys: ["s1": "{{HOMEPAGE_VAR_S1_KEY}}"])
        let back = try YamlConfig.parse(yaml)
        let service = try #require(back.services.first)

        #expect(back.keys.isEmpty)
        #expect(back.unresolved[service.id] == ["HOMEPAGE_VAR_S1_KEY"])
    }
}

@Suite("Aides YAML")
struct YamlHelperTests {

    @Test("fullURL ne complète que ce qui n'a pas de schéma", arguments: [
        ("nas.local:9091", "http://nas.local:9091"),
        ("http://nas.local", "http://nas.local"),
        ("https://nas.local", "https://nas.local"),
    ])
    func fullURL(input: String, expected: String) {
        #expect(YamlConfig.fullURL(input) == expected)
    }

    @Test("Le monogramme prend deux lettres, capitale puis minuscule", arguments: [
        ("Jellyfin", "Je"), ("proxmox", "Pr"), ("UniFi", "Un"), ("N", "N"),
    ])
    func mono(input: String, expected: String) {
        #expect(YamlConfig.mono(input) == expected)
    }
}
