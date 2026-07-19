import Foundation
import Network

// MARK: - Découverte Bonjour (_http._tcp) — le « Scanner mon réseau » réel

@MainActor
@Observable
final class BonjourScanner {

    struct Found: Identifiable, Equatable {
        let id: String
        let name: String
        var host: String
        var port: Int
        var type: IntegrationType?

        var url: String { "http://\(host):\(port)" }
    }

    private(set) var found: [Found] = []
    private(set) var scanning = false

    private var browser: NWBrowser?
    private var connections: [NWConnection] = []

    func start() {
        stop()
        found = []
        scanning = true
        let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: .tcp)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor [weak self] in
                self?.handle(results)
            }
        }
        browser.start(queue: .main)
        self.browser = browser
        // Fenêtre de scan bornée
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            self?.stopBrowsing()
        }
    }

    func stop() {
        stopBrowsing()
        found = []
    }

    private func stopBrowsing() {
        browser?.cancel()
        browser = nil
        connections.forEach { $0.cancel() }
        connections = []
        scanning = false
    }

    private func handle(_ results: Set<NWBrowser.Result>) {
        for result in results {
            guard case let .service(name, _, _, _) = result.endpoint else { continue }
            guard !found.contains(where: { $0.id == name }) else { continue }
            resolve(result.endpoint, name: name)
        }
    }

    /// Résout hôte + port en ouvrant une connexion éphémère vers l'endpoint Bonjour.
    private func resolve(_ endpoint: NWEndpoint, name: String) {
        let conn = NWConnection(to: endpoint, using: .tcp)
        connections.append(conn)
        conn.stateUpdateHandler = { [weak self, weak conn] state in
            guard case .ready = state,
                  let path = conn?.currentPath,
                  case let .hostPort(host, port)? = path.remoteEndpoint else { return }
            let hostText = switch host {
            case .name(let n, _): n
            case .ipv4(let ip): "\(ip)"
            case .ipv6(let ip): "[\(ip)]"
            @unknown default: "\(host)"
            }
            conn?.cancel()
            Task { @MainActor [weak self] in
                guard let self, !found.contains(where: { $0.id == name }) else { return }
                var item = Found(id: name, name: name,
                                 host: hostText.replacingOccurrences(of: "%en0", with: ""),
                                 port: Int(port.rawValue), type: nil)
                found.append(item)
                // Détection du type en arrière-plan
                let detected = await LiveFetcher.detect(item.url)
                if let idx = found.firstIndex(where: { $0.id == name }) {
                    item.type = detected.type
                    found[idx] = item
                }
            }
        }
        conn.start(queue: .main)
    }
}
