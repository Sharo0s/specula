import Foundation

// MARK: - Intégrations réelles (README : « API REST propre à chaque service »)
// Le type IntegrationType vit dans Models.swift (partagé avec les widgets).

enum LiveFetcher {

    // MARK: Ping — toute réponse HTTP = en ligne, la latence est l'aller-retour
    // Repli https:// si le http:// ne répond pas (serveurs HTTPS-only).

    static func ping(_ url: String) async -> (ok: Bool, latencyMs: Int) {
        for candidate in candidates(url) {
            guard let u = URL(string: candidate) else { continue }
            if let resp = try? await HTTPClient.shared.request(u) {
                return (true, resp.latencyMs)
            }
        }
        return (false, 0)
    }

    /// L'URL telle quelle, puis sa variante https si elle était en http implicite.
    static func candidates(_ url: String) -> [String] {
        guard url.hasPrefix("http://") else { return [url] }
        return [url, "https://" + url.dropFirst("http://".count)]
    }

    // MARK: Détection automatique du type (« 200+ intégrations reconnues »)

    static func detect(_ base: String) async -> (type: IntegrationType?, latencyMs: Int) {
        for candidate in candidates(base) {
            let result = await detectOne(candidate)
            if result.type != nil { return result }
        }
        return (nil, 0)
    }

    private static func detectOne(_ base: String) async -> (type: IntegrationType?, latencyMs: Int) {
        guard let baseURL = URL(string: base) else { return (nil, 0) }

        // Endpoints signature, sans clé API. Checks stricts (contenu) d'abord,
        // signaux ambigus (401 nu) en dernier — un serveur qui répond 200 à
        // tout ne doit matcher aucun check de contenu.
        let probes: [(String, IntegrationType, (HTTPClient.Response) -> Bool)] = [
            ("/System/Info/Public", .jellyfin, { r in
                r.status == 200 && String(data: r.data, encoding: .utf8)?.contains("Jellyfin") == true
            }),
            ("/api/server/ping", .immich, { r in
                r.status == 200 && String(data: r.data, encoding: .utf8)?.contains("pong") == true
            }),
            ("/status.php", .nextcloud, { r in
                r.status == 200 && String(data: r.data, encoding: .utf8)?.contains("Nextcloud") == true
            }),
            ("/control/status", .adguard, { r in
                (r.status == 200 && String(data: r.data, encoding: .utf8)?.contains("protection_enabled") == true)
                    || r.status == 403
            }),
            ("/api/4/cpu", .glances, { r in
                r.status == 200 && String(data: r.data, encoding: .utf8)?.contains("\"total\"") == true
            }),
            ("/transmission/rpc", .transmission, { r in r.headers["x-transmission-session-id"] != nil }),
            ("/api2/json/version", .proxmox, { r in r.status == 401 }),
            ("/api/v3/system/status", .radarr, { r in r.status == 401 }),
        ]
        for (path, type, check) in probes {
            if let u = URL(string: base + path),
               let resp = try? await HTTPClient.shared.request(u), check(resp) {
                // Radarr et Sonarr partagent l'API v3 — départage par port conventionnel
                if type == .radarr, baseURL.port == 8989 { return (.sonarr, resp.latencyMs) }
                return (type, resp.latencyMs)
            }
        }
        // Sniff du HTML de la page d'accueil
        if let resp = try? await HTTPClient.shared.request(baseURL),
           let html = String(data: resp.data, encoding: .utf8)?.lowercased() {
            let sniffs: [(String, IntegrationType)] = [
                ("uptime kuma", .uptimekuma), ("komga", .komga), ("home assistant", .homeassistant),
                ("file browser", .filebrowser), ("openmediavault", .omv), ("paperless", .paperless),
                ("unifi", .unifi), ("plex", .plex), ("qbittorrent", .qbittorrent), ("traefik", .traefik),
            ]
            if let hit = sniffs.first(where: { html.contains($0.0) }) {
                return (hit.1, resp.latencyMs)
            }
            return (.generic, resp.latencyMs)
        }
        return (nil, 0)
    }

    // MARK: Métriques par intégration — [valeur, libellé] × 3

    static func metrics(type: IntegrationType, base: String, key: String?) async -> [[String]]? {
        for candidate in candidates(base) {
            if let m = await metricsOne(type: type, base: candidate, key: key) { return m }
        }
        return nil
    }

    private static func metricsOne(type: IntegrationType, base: String, key: String?) async -> [[String]]? {
        do {
            switch type {
            case .jellyfin:
                guard let key else { return nil }
                let (json, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/Items/Counts")!, headers: ["X-Emby-Token": key])
                guard let d = json as? [String: Any] else { return nil }
                return [[frInt(d.int("MovieCount") ?? 0), "Films"],
                        [frInt(d.int("SeriesCount") ?? 0), "Séries"],
                        [frInt(d.int("EpisodeCount") ?? 0), "Épisodes"]]

            case .radarr:
                guard let key else { return nil }
                let h = ["X-Api-Key": key]
                async let missing = HTTPClient.shared.json(URL(string: "\(base)/api/v3/wanted/missing?pageSize=1")!, headers: h)
                async let queue = HTTPClient.shared.json(URL(string: "\(base)/api/v3/queue?pageSize=1")!, headers: h)
                async let movies = HTTPClient.shared.json(URL(string: "\(base)/api/v3/movie")!, headers: h)
                let m = (try await missing.0 as? [String: Any])?.int("totalRecords") ?? 0
                let q = (try await queue.0 as? [String: Any])?.int("totalRecords") ?? 0
                let count = (try await movies.0 as? [Any])?.count ?? 0
                return [[frInt(m), "Manquants"], [frInt(q), "En attente"], [frInt(count), "Films"]]

            case .sonarr:
                guard let key else { return nil }
                let h = ["X-Api-Key": key]
                async let series = HTTPClient.shared.json(URL(string: "\(base)/api/v3/series")!, headers: h)
                async let queue = HTTPClient.shared.json(URL(string: "\(base)/api/v3/queue?pageSize=1")!, headers: h)
                async let missing = HTTPClient.shared.json(URL(string: "\(base)/api/v3/wanted/missing?pageSize=1")!, headers: h)
                let s = (try await series.0 as? [Any])?.count ?? 0
                let q = (try await queue.0 as? [String: Any])?.int("totalRecords") ?? 0
                let m = (try await missing.0 as? [String: Any])?.int("totalRecords") ?? 0
                return [[frInt(s), "Séries"], [frInt(q), "En attente"], [frInt(m), "Recherché"]]

            case .adguard:
                var headers: [String: String] = [:]
                if let key, key.contains(":") {
                    // clé « utilisateur:motdepasse » → Basic
                    headers["Authorization"] = "Basic " + Data(key.utf8).base64EncodedString()
                }
                let (json, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/control/stats")!, headers: headers)
                guard let d = json as? [String: Any] else { return nil }
                let queries = d.int("num_dns_queries") ?? 0
                let blocked = d.int("num_blocked_filtering") ?? 0
                let pct = queries > 0 ? Int((Double(blocked) / Double(queries) * 100).rounded()) : 0
                let clients = d.array("top_clients")?.count ?? 0
                return [[frInt(queries), "Requêtes / j"], ["\(pct) %", "Bloquées"], [frInt(clients), "Clients DNS"]]

            case .transmission:
                return try await transmissionStats(base: base, key: key)

            case .proxmox:
                guard let key else { return nil }
                // key = jeton complet « user@realm!nom=uuid »
                let h = ["Authorization": "PVEAPIToken=\(key)"]
                let (json, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/api2/json/cluster/resources")!, headers: h)
                guard let d = json as? [String: Any], let list = d.array("data") else { return nil }
                let rows = list.compactMap { $0 as? [String: Any] }
                let vms = rows.filter { $0["type"] as? String == "qemu" }.count
                let cts = rows.filter { $0["type"] as? String == "lxc" }.count
                let mem = rows.filter { $0["type"] as? String == "node" }
                    .reduce(0.0) { $0 + ($1.double("maxmem") ?? 0) }
                return [[frInt(vms), "VM"], [frInt(cts), "Conteneurs"], [frBytes(mem), "RAM"]]

            case .immich:
                guard let key else { return nil }
                let (json, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/api/server/statistics")!, headers: ["x-api-key": key])
                guard let d = json as? [String: Any] else { return nil }
                return [[frInt(d.int("photos") ?? 0), "Photos"],
                        [frInt(d.int("videos") ?? 0), "Vidéos"],
                        [frBytes(d.double("usage") ?? 0), "Stockage"]]

            case .glances:
                guard let sys = await systemBand(base: base) else { return nil }
                return [["\(Int(sys.cpu)) %", "CPU"], [fr(sys.temp) + " °C", "Temp."], [fr(sys.ramFreeGB) + " Go", "RAM libre"]]

            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    // MARK: Transmission RPC (danse du X-Transmission-Session-Id)

    private static func transmissionStats(base: String, key: String?) async throws -> [[String]]? {
        let cleanBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        let body = try JSONSerialization.data(withJSONObject: ["method": "session-stats"])
        // Instance racine (`/transmission/rpc`) ou derrière un chemin (`…/transmission` + `/rpc`)
        for rpcPath in ["/transmission/rpc", "/rpc"] {
            guard let url = URL(string: cleanBase + rpcPath) else { continue }
            var headers = ["Content-Type": "application/json"]
            if let key, key.contains(":") {
                headers["Authorization"] = "Basic " + Data(key.utf8).base64EncodedString()
            }
            guard var resp = try? await HTTPClient.shared.request(url, method: "POST", headers: headers, body: body) else { continue }
            if resp.status == 409, let sid = resp.headers["x-transmission-session-id"] {
                headers["X-Transmission-Session-Id"] = sid
                guard let retried = try? await HTTPClient.shared.request(url, method: "POST", headers: headers, body: body) else { continue }
                resp = retried
            }
            guard resp.status == 200,
                  let json = try? JSONSerialization.jsonObject(with: resp.data) as? [String: Any],
                  let args = json.dict("arguments") else { continue }
            return [[frSpeed(args.double("downloadSpeed") ?? 0), "Réception"],
                    [frSpeed(args.double("uploadSpeed") ?? 0), "Envoi"],
                    [frInt(args.int("activeTorrentCount") ?? 0), "En partage"]]
        }
        return nil
    }

    // MARK: Bandeau système via Glances (API v4 puis v3)

    struct SystemBand {
        let cpu: Double
        let temp: Double
        let ramFreeGB: Double
    }

    static func systemBand(base: String) async -> SystemBand? {
        for api in ["/api/4", "/api/3"] {
            do {
                async let cpuJ = HTTPClient.shared.json(URL(string: base + api + "/cpu")!)
                async let memJ = HTTPClient.shared.json(URL(string: base + api + "/mem")!)
                async let sensJ = HTTPClient.shared.json(URL(string: base + api + "/sensors")!)
                let cpu = (try await cpuJ.0 as? [String: Any])?.double("total") ?? 0
                let free = (try await memJ.0 as? [String: Any])?.double("available") ?? 0
                let temps = ((try? await sensJ.0) as? [Any])?
                    .compactMap { $0 as? [String: Any] }
                    .filter { ($0["unit"] as? String) == "C" }
                    .compactMap { $0.double("value") } ?? []
                return SystemBand(cpu: cpu,
                                  temp: temps.max() ?? 0,
                                  ramFreeGB: free / 1_073_741_824)
            } catch {
                continue
            }
        }
        return nil
    }
}
