import Foundation

// MARK: - Client HTTP homelab
// Latence mesurée sur l'aller-retour, timeout 5 s (« Délai dépassé (timeout
// après 5 000 ms) »), certificats auto-signés acceptés (UniFi :8443,
// Proxmox :8006… — la norme sur un LAN selfhosted).

enum HTTPError: Error {
    /// L'adresse saisie ne forme pas une URL — une espace collée dans un
    /// copier-coller suffit. Erreur, jamais un `!` : le service passe hors
    /// ligne, l'app continue.
    case badURL
}

final class HTTPClient: NSObject, URLSessionDelegate, @unchecked Sendable {
    static let shared = HTTPClient()

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 5
        cfg.timeoutIntervalForResource = 8
        cfg.waitsForConnectivity = false
        cfg.httpCookieAcceptPolicy = .never
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()

    struct Response {
        let status: Int
        let data: Data
        let headers: [String: String]
        let latencyMs: Int
    }

    func request(_ url: URL, method: String = "GET",
                 headers: [String: String] = [:], body: Data? = nil) async throws -> Response {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }

        let clock = ContinuousClock()
        let start = clock.now
        let (data, resp) = try await session.data(for: req)
        let ms = max(1, Int((clock.now - start) / .milliseconds(1)))

        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        var hdrs: [String: String] = [:]
        for (k, v) in http.allHeaderFields {
            if let k = k as? String, let v = v as? String { hdrs[k.lowercased()] = v }
        }
        return Response(status: http.statusCode, data: data, headers: hdrs, latencyMs: ms)
    }

    func json(_ url: URL, headers: [String: String] = [:]) async throws -> (Any, Int) {
        let resp = try await request(url, headers: headers)
        guard (200..<300).contains(resp.status) else { throw URLError(.userAuthenticationRequired) }
        return (try JSONSerialization.jsonObject(with: resp.data), resp.latencyMs)
    }

    // MARK: Adresses construites à partir d'une saisie

    // Les intégrations composent leur URL avec l'adresse du service, tapée par
    // l'utilisateur. Ces deux surcharges centralisent la conversion : une
    // adresse malformée lève `badURL` et rejoint le chemin d'échec habituel.

    func request(_ string: String, method: String = "GET",
                 headers: [String: String] = [:], body: Data? = nil) async throws -> Response {
        guard let url = URL(string: string) else { throw HTTPError.badURL }
        return try await request(url, method: method, headers: headers, body: body)
    }

    func json(_ string: String, headers: [String: String] = [:]) async throws -> (Any, Int) {
        guard let url = URL(string: string) else { throw HTTPError.badURL }
        return try await json(url, headers: headers)
    }

    // Certificats auto-signés : acceptés sur le réseau local, où ils sont la
    // norme (UniFi :8443, Proxmox :8006) et où personne ne délivre de certificat
    // reconnu pour un nom en .local. Hors du réseau local — homelab joint par un
    // reverse proxy ou un tunnel — la validation reste celle du système : sinon
    // n'importe qui en position d'interception présenterait son propre
    // certificat et récolterait la clé API envoyée derrière.
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              Self.isLocalHost(challenge.protectionSpace.host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }

    /// Hôte du réseau local : plages privées RFC 1918, lien-local, boucle
    /// locale, ULA IPv6, et les noms sans point ou en .local/.home/.lan/.internal
    /// — un nom qu'aucune autorité publique ne peut certifier.
    static func isLocalHost(_ host: String) -> Bool {
        let h = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if h == "localhost" || h == "::1" { return true }

        let parts = h.split(separator: ".")
        if parts.count == 4, parts.allSatisfy({ UInt8($0) != nil }) {
            let o = parts.map { UInt8($0)! }
            switch (o[0], o[1]) {
            case (10, _), (127, _), (192, 168): return true
            case (172, 16...31): return true
            case (169, 254): return true    // lien-local
            case (100, 64...127): return true // CGNAT — plage des tailnets
            default: return false
            }
        }
        // IPv6 : boucle locale, lien-local (fe80::/10), ULA (fc00::/7)
        if h.contains(":") {
            return h.hasPrefix("fe8") || h.hasPrefix("fe9") || h.hasPrefix("fea")
                || h.hasPrefix("feb") || h.hasPrefix("fc") || h.hasPrefix("fd")
        }
        if !h.contains(".") { return true }  // nom court, résolu par le LAN
        return [".local", ".home", ".lan", ".internal", ".home.arpa"]
            .contains { h.hasSuffix($0) }
    }
}

// MARK: - Query string

/// Valeur prête à être posée dans une query string. Une clé API contient ce que
/// le service a bien voulu générer : un « + », un « & » ou un « # » non encodé
/// tronque la requête ou en change le sens.
func urlQueryValue(_ value: String) -> String {
    let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+?#"))
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}

// MARK: - Aides JSON (accès dynamique sans Codable par intégration)

extension Dictionary where Key == String, Value == Any {
    func int(_ key: String) -> Int? {
        (self[key] as? Int) ?? (self[key] as? Double).map(Int.init) ?? (self[key] as? String).flatMap(Int.init)
    }
    func double(_ key: String) -> Double? {
        (self[key] as? Double) ?? (self[key] as? Int).map(Double.init)
    }
    func dict(_ key: String) -> [String: Any]? { self[key] as? [String: Any] }
    func array(_ key: String) -> [Any]? { self[key] as? [Any] }
}

// MARK: - Formats français

/// Entier groupé selon la locale : « 10 967 » / « 10,967 ».
func frInt(_ n: Int) -> String {
    n.formatted(.number)
}

/// Octets → « 112 Go » / « 112 GB ».
func frBytes(_ bytes: Double) -> String {
    let gb = bytes / 1_073_741_824
    if gb >= 1000 { return String(localized: "\(fr(gb / 1024)) To") }
    if gb >= 10 { return String(localized: "\(Int(gb.rounded())) Go") }
    return String(localized: "\(fr(gb)) Go")
}

/// Secondes d'activité → « 15,6 h » sous une journée, « 12,2 j » au-delà.
func frUptime(_ seconds: Double) -> String {
    seconds < 86_400
        ? String(localized: "\(fr(seconds / 3600)) h")
        : String(localized: "\(fr(seconds / 86_400)) j")
}

/// Octets/s → « 2,1 Mo/s » / « 2.1 MB/s ».
func frSpeed(_ bytesPerSec: Double) -> String {
    String(localized: "\(fr(bytesPerSec / 1_048_576)) Mo/s")
}
