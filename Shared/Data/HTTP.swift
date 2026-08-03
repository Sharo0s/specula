import Foundation

// MARK: - Client HTTP homelab
// Latence mesurée sur l'aller-retour, timeout 5 s (« Délai dépassé (timeout
// après 5 000 ms) »), certificats auto-signés acceptés (UniFi :8443,
// Proxmox :8006… — la norme sur un LAN selfhosted).

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

    // Auto-signé : on fait confiance au trust présenté (homelab).
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
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
