import Foundation
import Testing
@testable import Specula

// MARK: - Intégrations et couche réseau
// Les fonctions qui interrogent réellement un service ne sont pas testables
// sans homelab : elles appellent `HTTPClient` directement. Ce qui suit couvre
// la partie déterministe — celle où une régression passerait inaperçue.

@Suite("Adresses candidates")
struct CandidatesTests {

    @Test("Une adresse en http est aussi tentée en https")
    func httpGetsHTTPSFallback() {
        // Beaucoup de services répondent sur les deux ; se limiter à ce que
        // l'utilisateur a tapé afficherait « hors ligne » à tort.
        #expect(LiveFetcher.candidates("http://nas.local:8080")
                == ["http://nas.local:8080", "https://nas.local:8080"])
    }

    @Test("Une adresse déjà en https n'est pas dégradée en http")
    func httpsStaysAlone() {
        #expect(LiveFetcher.candidates("https://pve.local:8006") == ["https://pve.local:8006"])
    }

    @Test("Une adresse sans schéma est laissée telle quelle")
    func noSchemeUntouched() {
        #expect(LiveFetcher.candidates("nas.local:9091") == ["nas.local:9091"])
    }
}

@Suite("Types d'intégration")
struct IntegrationTypeTests {

    @Test("Le catalogue de démo ne référence que des types connus")
    func demoCatalogTypesExist() {
        for (id, type) in Catalog.typeByID {
            #expect(IntegrationType(rawValue: type.rawValue) != nil,
                    "type inconnu pour \(id)")
        }
    }

    @Test("Chaque type se reconstruit depuis sa valeur brute")
    func rawValuesRoundTrip() {
        for type in IntegrationType.allCases {
            #expect(IntegrationType(rawValue: type.rawValue) == type)
        }
    }
}

@Suite("Classification des hôtes")
struct LocalHostTests {

    // La dérogation TLS ne vaut que pour ces hôtes : une plage classée locale à
    // tort rouvrirait l'interception sur un réseau public, avec la clé API
    // envoyée derrière.

    @Test("Réseaux privés, boucle locale et lien-local sont locaux", arguments: [
        "192.168.1.10", "10.0.0.5", "172.16.0.1", "172.31.255.254",
        "127.0.0.1", "169.254.1.1", "localhost",
    ])
    func privateRangesAreLocal(host: String) {
        #expect(HTTPClient.isLocalHost(host))
    }

    @Test("Les bornes de 172.16/12 sont respectées", arguments: [
        "172.15.0.1", "172.32.0.1",
    ])
    func aroundTheTwentyBitBlock(host: String) {
        #expect(!HTTPClient.isLocalHost(host))
    }

    @Test("La plage CGNAT des tailnets est locale, ses bornes exclues")
    func cgnat() {
        #expect(HTTPClient.isLocalHost("100.64.0.1"))
        #expect(HTTPClient.isLocalHost("100.127.255.254"))
        #expect(!HTTPClient.isLocalHost("100.63.0.1"))
        #expect(!HTTPClient.isLocalHost("100.128.0.1"))
    }

    @Test("Une adresse publique ne l'est jamais", arguments: [
        "8.8.8.8", "93.184.216.34", "2606:4700::1111",
        "cloud.example.net", "mon-homelab.fr",
    ])
    func publicHostsAreNotLocal(host: String) {
        #expect(!HTTPClient.isLocalHost(host))
    }

    @Test("Les noms qu'aucune autorité ne peut certifier sont locaux", arguments: [
        "nas", "nas.local", "NAS.LOCAL", "pve.home.arpa", "jellyfin.lan",
        "docs.internal", "kuma.home",
    ])
    func unsignableNamesAreLocal(host: String) {
        #expect(HTTPClient.isLocalHost(host))
    }

    @Test("IPv6 : boucle locale, lien-local et ULA seulement", arguments: [
        "::1", "fe80::1", "fd00::1", "[fd12::34]",
    ])
    func localIPv6(host: String) {
        #expect(HTTPClient.isLocalHost(host))
    }
}

@Suite("Query string")
struct QueryValueTests {

    @Test("Les caractères qui changent le sens d'une requête sont encodés", arguments: [
        ("a&b", "a%26b"), ("a=b", "a%3Db"), ("a+b", "a%2Bb"),
        ("a#b", "a%23b"), ("a b", "a%20b"), ("a?b", "a%3Fb"),
    ])
    func specialCharactersAreEncoded(input: String, expected: String) {
        // Une clé API contient ce que le service a bien voulu générer : un « + »
        // non encodé devient une espace côté serveur, un « & » coupe la requête.
        #expect(urlQueryValue(input) == expected)
    }

    @Test("Une clé alphanumérique passe intacte")
    func plainKeyUntouched() {
        #expect(urlQueryValue("abc123DEF") == "abc123DEF")
    }

    @Test("Une clé encodée forme toujours une URL valide")
    func encodedKeyBuildsAValidURL() {
        let url = URL(string: "http://nas.local:8080/api?apikey=\(urlQueryValue("a b&c+d"))")
        #expect(url != nil)
    }
}

@Suite("Lecture JSON")
struct JSONHelperTests {

    @Test("Un entier se lit qu'il arrive en Int, Double ou String")
    func intCoercion() {
        let json: [String: Any] = ["a": 42, "b": 42.0, "c": "42", "d": "quarante-deux"]
        #expect(json.int("a") == 42)
        #expect(json.int("b") == 42)
        #expect(json.int("c") == 42)
        #expect(json.int("d") == nil)
        #expect(json.int("absent") == nil)
    }

    @Test("Un flottant accepte un entier")
    func doubleCoercion() {
        let json: [String: Any] = ["a": 1.5, "b": 2]
        #expect(json.double("a") == 1.5)
        #expect(json.double("b") == 2.0)
    }

    @Test("Dictionnaires et tableaux imbriqués")
    func nested() {
        let json: [String: Any] = ["obj": ["n": 1], "arr": [1, 2, 3]]
        #expect(json.dict("obj")?.int("n") == 1)
        #expect(json.array("arr")?.count == 3)
        #expect(json.dict("arr") == nil)
    }
}
