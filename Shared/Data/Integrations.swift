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
            ("/api/system/status", .portainer, { r in
                r.status == 200 && String(data: r.data, encoding: .utf8)?.contains("\"Version\"") == true
            }),
            ("/api/health", .grafana, { r in
                r.status == 200 && String(data: r.data, encoding: .utf8)?.contains("\"database\"") == true
            }),
            ("/ping", .audiobookshelf, { r in
                r.status == 200 && String(data: r.data, encoding: .utf8)?.contains("success") == true
            }),
            ("/admin/api.php", .pihole, { r in
                r.status == 200 && String(data: r.data, encoding: .utf8).map { $0 == "[]" || $0.contains("dns_queries") } == true
            }),
            ("/api2/json/version", .proxmox, { r in r.status == 401 }),
            ("/api/v3/system/status", .radarr, { r in r.status == 401 }),
        ]
        for (path, type, check) in probes {
            if let u = URL(string: base + path),
               let resp = try? await HTTPClient.shared.request(u), check(resp) {
                // La famille *arr partage son API — départage par port conventionnel
                if type == .radarr {
                    switch baseURL.port {
                    case 8989: return (.sonarr, resp.latencyMs)
                    case 9696: return (.prowlarr, resp.latencyMs)
                    case 8686: return (.lidarr, resp.latencyMs)
                    case 8787: return (.readarr, resp.latencyMs)
                    default: return (.radarr, resp.latencyMs)
                    }
                }
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
                ("syncthing", .syncthing), ("sabnzbd", .sabnzbd), ("tautulli", .tautulli),
                ("overseerr", .overseerr), ("jellyseerr", .overseerr), ("gitea", .gitea),
                ("forgejo", .gitea), ("grafana", .grafana), ("pi-hole", .pihole),
                ("portainer", .portainer), ("audiobookshelf", .audiobookshelf),
                ("navidrome", .navidrome), ("frigate", .frigate), ("kavita", .kavita),
                ("mealie", .mealie), ("miniflux", .miniflux), ("linkding", .linkding),
                ("speedtest", .speedtest), ("scrutiny", .scrutiny), ("netdata", .netdata),
                ("gotify", .gotify), ("authentik", .authentik), ("truenas", .truenas),
                ("octoprint", .octoprint), ("esphome", .esphome),
                ("ollama", .ollama), ("nginx proxy manager", .npm), ("wg-easy", .wgeasy),
                ("jackett", .jackett), ("deluge", .deluge), ("photoprism", .photoprism),
                ("gitlab", .gitlab), ("peertube", .peertube), ("bookstack", .bookstack),
                ("firefly", .fireflyiii), ("grocy", .grocy), ("healthchecks", .healthchecks),
                ("changedetection", .changedetection), ("wordpress", .wordpress),
                ("ghost", .ghost), ("matomo", .matomo), ("n8n", .n8n),
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
                // Le widget customapi de gethomepage donne parfois l'URL complète
                var immichBase = base
                if let r = immichBase.range(of: "/api/") { immichBase = String(immichBase[..<r.lowerBound]) }
                let (json, _) = try await HTTPClient.shared.json(
                    URL(string: "\(immichBase)/api/server/statistics")!, headers: ["x-api-key": key])
                guard let d = json as? [String: Any] else { return nil }
                return [[frInt(d.int("photos") ?? 0), "Photos"],
                        [frInt(d.int("videos") ?? 0), "Vidéos"],
                        [frBytes(d.double("usage") ?? 0), "Stockage"]]

            case .glances:
                guard let sys = await systemBand(base: base) else { return nil }
                return [["\(Int(sys.cpu)) %", "CPU"], [fr(sys.temp) + " °C", "Temp."], [fr(sys.ramFreeGB) + " Go", "RAM libre"]]

            case .komga:
                // clé « utilisateur:motdepasse » → Basic
                guard let key, key.contains(":") else { return nil }
                let h = ["Authorization": "Basic " + Data(key.utf8).base64EncodedString()]
                async let libs = HTTPClient.shared.json(URL(string: "\(base)/api/v1/libraries")!, headers: h)
                async let series = HTTPClient.shared.json(URL(string: "\(base)/api/v1/series?size=1")!, headers: h)
                async let books = HTTPClient.shared.json(URL(string: "\(base)/api/v1/books?size=1")!, headers: h)
                let l = (try await libs.0 as? [Any])?.count ?? 0
                let s = (try await series.0 as? [String: Any])?.int("totalElements") ?? 0
                let b = (try await books.0 as? [String: Any])?.int("totalElements") ?? 0
                return [[frInt(l), "Bibliothèques"], [frInt(s), "Séries"], [frInt(b), "Livres"]]

            case .homeassistant:
                // clé = jeton longue durée (Bearer)
                guard let key else { return nil }
                let (json, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/api/states")!, headers: ["Authorization": "Bearer \(key)"])
                guard let states = json as? [[String: Any]] else { return nil }
                func tally(_ prefix: String, on: Set<String>) -> (Int, Int) {
                    let items = states.filter { ($0["entity_id"] as? String)?.hasPrefix(prefix) == true }
                    let active = items.filter { on.contains(($0["state"] as? String) ?? "") }.count
                    return (active, items.count)
                }
                let p = tally("person.", on: ["home"])
                let li = tally("light.", on: ["on"])
                let sw = tally("switch.", on: ["on"])
                return [["\(p.0) / \(p.1)", "Présents"], ["\(li.0) / \(li.1)", "Lumières"],
                        ["\(sw.0) / \(sw.1)", "Interrupteurs"]]

            case .unifi:
                // clé = API key UniFi (X-API-KEY, console UniFi OS)
                guard let key else { return nil }
                let h = ["X-API-KEY": key, "Accept": "application/json"]
                let (healthJ, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/proxy/network/api/s/default/stat/health")!, headers: h)
                guard let subsystems = (healthJ as? [String: Any])?.array("data")?
                    .compactMap({ $0 as? [String: Any] }) else { return nil }
                var lan = 0, wlan = 0, wanUp = false
                for sub in subsystems {
                    switch sub["subsystem"] as? String {
                    case "lan": lan = sub.int("num_user") ?? 0
                    case "wlan": wlan = sub.int("num_user") ?? 0
                    case "wan": wanUp = (sub["status"] as? String) == "ok"
                    default: break
                    }
                }
                var out = [[frInt(lan), "LAN"], [frInt(wlan), "WLAN"]]
                if let (sysJ, _) = try? await HTTPClient.shared.json(
                    URL(string: "\(base)/proxy/network/api/s/default/stat/sysinfo")!, headers: h),
                   let uptime = ((sysJ as? [String: Any])?.array("data")?.first as? [String: Any])?.double("uptime"),
                   uptime > 0 {
                    out.append([fr(uptime / 86_400) + " j", "Uptime"])
                }
                out.append([wanUp ? String(localized: "ACTIF") : String(localized: "HORS LIGNE"), "WAN"])
                return out

            case .nextcloud:
                // clé « utilisateur:motdepasse » (ou mot de passe d'application)
                guard let key, key.contains(":") else { return nil }
                let h = ["Authorization": "Basic " + Data(key.utf8).base64EncodedString(),
                         "OCS-APIRequest": "true"]
                let (json, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/ocs/v2.php/apps/serverinfo/api/v1/info?format=json")!, headers: h)
                guard let data = ((json as? [String: Any])?.dict("ocs"))?.dict("data") else { return nil }
                let nc = data.dict("nextcloud")
                let free = nc?.dict("system")?.double("freespace") ?? 0
                let files = nc?.dict("storage")?.int("num_files") ?? 0
                let shares = nc?.dict("shares")?.int("num_shares") ?? 0
                let active = data.dict("activeUsers")?.int("last5minutes") ?? 0
                return [[frBytes(free), "Libres"], [frInt(files), "Fichiers"],
                        [frInt(active), "Utilisateurs"], [frInt(shares), "Partages"]]

            case .paperless:
                // clé = jeton API (Authorization: Token)
                guard let key else { return nil }
                let (json, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/api/statistics/")!, headers: ["Authorization": "Token \(key)"])
                guard let d = json as? [String: Any] else { return nil }
                return [[frInt(d.int("documents_total") ?? 0), "Documents"],
                        [frInt(d.int("tag_count") ?? 0), "Étiquettes"],
                        [frInt(d.int("documents_inbox") ?? 0), "À trier"]]

            case .plex:
                // clé = X-Plex-Token
                guard let key else { return nil }
                let h = ["X-Plex-Token": key, "Accept": "application/json"]
                let (sessJ, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/status/sessions")!, headers: h)
                let playing = ((sessJ as? [String: Any])?.dict("MediaContainer"))?.int("size") ?? 0
                var out = [[frInt(playing), "Lectures"]]
                if let (libJ, _) = try? await HTTPClient.shared.json(
                    URL(string: "\(base)/library/sections")!, headers: h),
                   let sections = ((libJ as? [String: Any])?.dict("MediaContainer"))?.array("Directory") {
                    out.append([frInt(sections.count), "Bibliothèques"])
                }
                return out

            case .qbittorrent:
                // clé « utilisateur:motdepasse » → login cookie SID
                guard let key, let sep = key.firstIndex(of: ":") else { return nil }
                let user = String(key[..<sep])
                let pass = String(key[key.index(after: sep)...])
                var allowed = CharacterSet.alphanumerics
                allowed.insert(charactersIn: "-._~")
                let body = "username=\(user.addingPercentEncoding(withAllowedCharacters: allowed) ?? user)&password=\(pass.addingPercentEncoding(withAllowedCharacters: allowed) ?? pass)"
                let login = try await HTTPClient.shared.request(
                    URL(string: "\(base)/api/v2/auth/login")!, method: "POST",
                    headers: ["Content-Type": "application/x-www-form-urlencoded", "Referer": base],
                    body: Data(body.utf8))
                guard let setCookie = login.headers["set-cookie"],
                      let sid = setCookie.split(separator: ";").first, sid.contains("SID=") else { return nil }
                let h = ["Cookie": String(sid)]
                let (transferJ, _) = try await HTTPClient.shared.json(
                    URL(string: "\(base)/api/v2/transfer/info")!, headers: h)
                guard let tr = transferJ as? [String: Any] else { return nil }
                let torrents = try? await HTTPClient.shared.json(
                    URL(string: "\(base)/api/v2/torrents/info")!, headers: h)
                let count = (torrents?.0 as? [Any])?.count ?? 0
                return [[frSpeed(tr.double("dl_info_speed") ?? 0), "Réception"],
                        [frSpeed(tr.double("up_info_speed") ?? 0), "Envoi"],
                        [frInt(count), "En partage"]]

            case .traefik:
                // API interne (:8080 par défaut), sans authentification
                let (json, _) = try await HTTPClient.shared.json(URL(string: "\(base)/api/overview")!)
                guard let http = (json as? [String: Any])?.dict("http") else { return nil }
                let routers = http.dict("routers")
                return [[frInt(routers?.int("total") ?? 0), "Routes"],
                        [frInt(http.dict("services")?.int("total") ?? 0), "Sources"],
                        [frInt(routers?.int("errors") ?? 0), "Erreurs"]]

            default:
                return try await metricsMore(type: type, base: base, key: key)
            }
        } catch {
            return nil
        }
    }

    // MARK: Intégrations supplémentaires

    private static func metricsMore(type: IntegrationType, base: String, key: String?) async throws -> [[String]]? {
        switch type {
        case .pihole:
            // v5 — clé = jeton API (paramètre auth)
            let auth = key.map { "&auth=\($0)" } ?? ""
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/admin/api.php?summaryRaw\(auth)")!)
            guard let d = json as? [String: Any], d["dns_queries_today"] != nil else { return nil }
            let q = d.int("dns_queries_today") ?? 0
            let b = d.int("ads_blocked_today") ?? 0
            let pct = q > 0 ? Int((Double(b) / Double(q) * 100).rounded()) : 0
            return [[frInt(q), "Requêtes / j"], ["\(pct) %", "Bloquées"],
                    [frInt(d.int("unique_clients") ?? 0), "Clients DNS"]]

        case .prowlarr:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/indexer")!, headers: ["X-Api-Key": key])
            guard let list = json as? [[String: Any]] else { return nil }
            let enabled = list.filter { ($0["enable"] as? Bool) == true }.count
            return [[frInt(list.count), "Sources"], [frInt(enabled), "Actives"]]

        case .lidarr, .readarr:
            guard let key else { return nil }
            let h = ["X-Api-Key": key]
            let kind = type == .lidarr ? "artist" : "author"
            async let items = HTTPClient.shared.json(URL(string: "\(base)/api/v1/\(kind)")!, headers: h)
            async let queue = HTTPClient.shared.json(URL(string: "\(base)/api/v1/queue?pageSize=1")!, headers: h)
            async let missing = HTTPClient.shared.json(URL(string: "\(base)/api/v1/wanted/missing?pageSize=1")!, headers: h)
            let n = (try await items.0 as? [Any])?.count ?? 0
            let q = (try await queue.0 as? [String: Any])?.int("totalRecords") ?? 0
            let m = (try await missing.0 as? [String: Any])?.int("totalRecords") ?? 0
            return [[frInt(n), type == .lidarr ? "Artistes" : "Auteurs"],
                    [frInt(q), "En attente"], [frInt(m), "Manquants"]]

        case .bazarr:
            guard let key else { return nil }
            let h = ["X-API-KEY": key]
            async let eps = HTTPClient.shared.json(URL(string: "\(base)/api/episodes/wanted?length=1")!, headers: h)
            async let movies = HTTPClient.shared.json(URL(string: "\(base)/api/movies/wanted?length=1")!, headers: h)
            let e = (try await eps.0 as? [String: Any])?.int("total") ?? 0
            let m = (try await movies.0 as? [String: Any])?.int("total") ?? 0
            return [[frInt(e), "Épisodes"], [frInt(m), "Films"]]

        case .overseerr:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/request/count")!, headers: ["X-Api-Key": key])
            guard let d = json as? [String: Any] else { return nil }
            return [[frInt(d.int("pending") ?? 0), "En attente"],
                    [frInt(d.int("total") ?? 0), "Demandes"]]

        case .tautulli:
            guard let key else { return nil }
            let (actJ, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v2?apikey=\(key)&cmd=get_activity")!)
            let data = ((actJ as? [String: Any])?.dict("response"))?.dict("data")
            let streams = data?.int("stream_count") ?? 0
            var out = [[frInt(streams), "Lectures"]]
            if let (libJ, _) = try? await HTTPClient.shared.json(
                URL(string: "\(base)/api/v2?apikey=\(key)&cmd=get_libraries")!),
               let libs = (((libJ as? [String: Any])?.dict("response"))?["data"]) as? [Any] {
                out.append([frInt(libs.count), "Bibliothèques"])
            }
            return out

        case .portainer:
            guard let key else { return nil }
            let h = ["X-API-Key": key]
            let (endJ, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/endpoints")!, headers: h)
            guard let endpoints = endJ as? [[String: Any]] else { return nil }
            var out: [[String]] = []
            if let first = endpoints.first?.int("Id"),
               let (contJ, _) = try? await HTTPClient.shared.json(
                URL(string: "\(base)/api/endpoints/\(first)/docker/containers/json?all=true")!, headers: h),
               let containers = contJ as? [[String: Any]] {
                let running = containers.filter { ($0["State"] as? String) == "running" }.count
                out.append([frInt(running), "En cours"])
                out.append([frInt(containers.count), "Conteneurs"])
            }
            out.append([frInt(endpoints.count), "Environnements"])
            return out

        case .sabnzbd:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api?mode=queue&output=json&apikey=\(key)")!)
            guard let q = (json as? [String: Any])?.dict("queue") else { return nil }
            let kbps = Double(q["kbpersec"] as? String ?? "0") ?? 0
            return [[frSpeed(kbps * 1024), "Réception"],
                    [frInt(q.int("noofslots") ?? 0), "En attente"]]

        case .gitea:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/repos/search?limit=1")!,
                headers: ["Authorization": "token \(key)"])
            guard let total = (json as? [String: Any])?.int("total_count") else { return nil }
            return [[frInt(total), "Dépôts"]]

        case .grafana:
            // clé = jeton de compte de service (Bearer)
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/search?limit=5000&type=dash-db")!,
                headers: ["Authorization": "Bearer \(key)"])
            guard let list = json as? [Any] else { return nil }
            return [[frInt(list.count), "Tableaux"]]

        case .syncthing:
            guard let key else { return nil }
            let h = ["X-API-Key": key]
            let (connJ, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/rest/system/connections")!, headers: h)
            guard let conns = ((connJ as? [String: Any])?.dict("connections")) else { return nil }
            let connected = conns.values.compactMap { $0 as? [String: Any] }
                .filter { ($0["connected"] as? Bool) == true }.count
            var out = [["\(connected) / \(conns.count)", "Appareils"]]
            if let (foldJ, _) = try? await HTTPClient.shared.json(
                URL(string: "\(base)/rest/config/folders")!, headers: h),
               let folders = foldJ as? [Any] {
                out.append([frInt(folders.count), "Dossiers"])
            }
            return out

        case .audiobookshelf:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/libraries")!, headers: ["Authorization": "Bearer \(key)"])
            guard let libs = (json as? [String: Any])?.array("libraries") else { return nil }
            return [[frInt(libs.count), "Bibliothèques"]]

        case .uptimekuma:
            // clé = API key (Basic, utilisateur vide) → métriques Prometheus
            guard let key else { return nil }
            let h = ["Authorization": "Basic " + Data(":\(key)".utf8).base64EncodedString()]
            let resp = try await HTTPClient.shared.request(URL(string: "\(base)/metrics")!, headers: h)
            guard resp.status == 200, let text = String(data: resp.data, encoding: .utf8) else { return nil }
            let monitors = text.split(separator: "\n").filter { $0.hasPrefix("monitor_status{") }
            guard !monitors.isEmpty else { return nil }
            let up = monitors.filter { $0.hasSuffix(" 1") }.count
            return [["\(up) / \(monitors.count)", "En ligne"]]

        case .navidrome:
            // API Subsonic — clé « utilisateur:motdepasse »
            guard let key, let sep = key.firstIndex(of: ":") else { return nil }
            var allowed = CharacterSet.alphanumerics
            allowed.insert(charactersIn: "-._~")
            let u = String(key[..<sep]).addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
            let p = String(key[key.index(after: sep)...]).addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/rest/getScanStatus.view?u=\(u)&p=\(p)&v=1.16.1&c=specula&f=json")!)
            guard let count = (((json as? [String: Any])?.dict("subsonic-response"))?
                .dict("scanStatus"))?.int("count") else { return nil }
            return [[frInt(count), "Chansons"]]

        case .frigate:
            let (json, _) = try await HTTPClient.shared.json(URL(string: "\(base)/api/stats")!)
            guard let d = json as? [String: Any] else { return nil }
            let cams = (d.dict("cameras"))?.count ?? 0
            guard cams > 0 else { return nil }
            return [[frInt(cams), "Caméras"]]

        case .kavita:
            guard let key else { return nil }
            let auth = try await HTTPClient.shared.request(
                URL(string: "\(base)/api/Plugin/authenticate?apiKey=\(key)&pluginName=Specula")!,
                method: "POST")
            guard auth.status == 200,
                  let token = (try? JSONSerialization.jsonObject(with: auth.data) as? [String: Any])?["token"] as? String else { return nil }
            let h = ["Authorization": "Bearer \(token)"]
            for path in ["/api/Library/libraries", "/api/Library"] {
                if let (json, _) = try? await HTTPClient.shared.json(URL(string: base + path)!, headers: h),
                   let libs = json as? [Any] {
                    return [[frInt(libs.count), "Bibliothèques"]]
                }
            }
            return nil

        case .mealie:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/recipes?perPage=1")!,
                headers: ["Authorization": "Bearer \(key)"])
            guard let total = (json as? [String: Any])?.int("total") else { return nil }
            return [[frInt(total), "Recettes"]]

        case .miniflux:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/v1/entries?status=unread&limit=1")!,
                headers: ["X-Auth-Token": key])
            guard let total = (json as? [String: Any])?.int("total") else { return nil }
            return [[frInt(total), "Non lus"]]

        case .linkding:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/bookmarks/?limit=1")!,
                headers: ["Authorization": "Token \(key)"])
            guard let count = (json as? [String: Any])?.int("count") else { return nil }
            return [[frInt(count), "Liens"]]

        case .speedtest:
            // Speedtest Tracker — jeton Bearer
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/speedtest/latest")!,
                headers: ["Authorization": "Bearer \(key)", "Accept": "application/json"])
            guard let d = (json as? [String: Any])?.dict("data") else { return nil }
            let down = d.double("download") ?? 0
            let up = d.double("upload") ?? 0
            let ping = d.double("ping") ?? 0
            return [[fr(down, 0) + " Mb/s", "Réception"], [fr(up, 0) + " Mb/s", "Envoi"],
                    ["\(Int(ping.rounded())) MS", "Latence"]]

        case .scrutiny:
            let (json, _) = try await HTTPClient.shared.json(URL(string: "\(base)/api/summary")!)
            guard let summary = ((json as? [String: Any])?.dict("data"))?.dict("summary") else { return nil }
            return [[frInt(summary.count), "Disques"]]

        case .netdata:
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/alarms?active=true")!)
            guard let alarms = (json as? [String: Any])?.dict("alarms") else { return nil }
            return [[frInt(alarms.count), "Alertes"]]

        case .gotify:
            // clé = jeton client
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/application")!, headers: ["X-Gotify-Key": key])
            guard let apps = json as? [Any] else { return nil }
            return [[frInt(apps.count), "Applications"]]

        case .authentik:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v3/core/users/?page_size=1")!,
                headers: ["Authorization": "Bearer \(key)"])
            guard let count = ((json as? [String: Any])?.dict("pagination"))?.int("count") else { return nil }
            return [[frInt(count), "Utilisateurs"]]

        case .truenas:
            guard let key else { return nil }
            let h = ["Authorization": "Bearer \(key)"]
            let (poolJ, _) = try await HTTPClient.shared.json(URL(string: "\(base)/api/v2.0/pool")!, headers: h)
            guard let pools = poolJ as? [Any] else { return nil }
            var out = [[frInt(pools.count), "Volumes"]]
            if let (alertJ, _) = try? await HTTPClient.shared.json(
                URL(string: "\(base)/api/v2.0/alert/list")!, headers: h),
               let alerts = alertJ as? [[String: Any]] {
                let active = alerts.filter { ($0["dismissed"] as? Bool) != true }.count
                out.append([frInt(active), "Alertes"])
            }
            return out

        case .octoprint:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/job")!, headers: ["X-Api-Key": key])
            guard let d = json as? [String: Any] else { return nil }
            let completion = (d.dict("progress"))?.double("completion") ?? 0
            var out = [[fr(completion, 0) + " %", "Progression"]]
            if let state = d["state"] as? String { out.append([state, "Statut"]) }
            return out

        case .esphome:
            let (json, _) = try await HTTPClient.shared.json(URL(string: "\(base)/devices")!)
            guard let d = json as? [String: Any] else { return nil }
            let devices = (d.array("configured_devices") ?? d.array("devices") ?? d.array("configured"))?.count ?? 0
            guard devices > 0 else { return nil }
            return [[frInt(devices), "Appareils"]]

        case .ollama:
            let (json, _) = try await HTTPClient.shared.json(URL(string: "\(base)/api/tags")!)
            guard let models = (json as? [String: Any])?.array("models") else { return nil }
            return [[frInt(models.count), "Modèles"]]

        case .npm:
            // clé « utilisateur:motdepasse » → jeton
            guard let key, let sep = key.firstIndex(of: ":") else { return nil }
            let body = try JSONSerialization.data(withJSONObject: [
                "identity": String(key[..<sep]), "secret": String(key[key.index(after: sep)...])])
            let login = try await HTTPClient.shared.request(
                URL(string: "\(base)/api/tokens")!, method: "POST",
                headers: ["Content-Type": "application/json"], body: body)
            guard let token = (try? JSONSerialization.jsonObject(with: login.data) as? [String: Any])?["token"] as? String else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/nginx/proxy-hosts")!,
                headers: ["Authorization": "Bearer \(token)"])
            guard let hosts = json as? [Any] else { return nil }
            return [[frInt(hosts.count), "Routes"]]

        case .wgeasy:
            // clé = mot de passe de l'interface
            guard let key else { return nil }
            let body = try JSONSerialization.data(withJSONObject: ["password": key])
            let login = try await HTTPClient.shared.request(
                URL(string: "\(base)/api/session")!, method: "POST",
                headers: ["Content-Type": "application/json"], body: body)
            guard let cookie = login.headers["set-cookie"]?.split(separator: ";").first else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/wireguard/client")!, headers: ["Cookie": String(cookie)])
            guard let clients = json as? [[String: Any]] else { return nil }
            let enabled = clients.filter { ($0["enabled"] as? Bool) == true }.count
            return [["\(enabled) / \(clients.count)", "Appareils"]]

        case .jackett:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v2.0/indexers?apikey=\(key)&configured=true")!)
            guard let list = json as? [Any] else { return nil }
            return [[frInt(list.count), "Sources"]]

        case .deluge:
            // clé = mot de passe de l'interface (JSON-RPC)
            guard let key else { return nil }
            let loginBody = try JSONSerialization.data(withJSONObject:
                ["method": "auth.login", "params": [key], "id": 1])
            let login = try await HTTPClient.shared.request(
                URL(string: "\(base)/json")!, method: "POST",
                headers: ["Content-Type": "application/json"], body: loginBody)
            guard let cookie = login.headers["set-cookie"]?.split(separator: ";").first else { return nil }
            let statusBody = try JSONSerialization.data(withJSONObject:
                ["method": "core.get_session_status", "params": [["download_rate", "upload_rate"]], "id": 2])
            let resp = try await HTTPClient.shared.request(
                URL(string: "\(base)/json")!, method: "POST",
                headers: ["Content-Type": "application/json", "Cookie": String(cookie)], body: statusBody)
            guard let result = (try? JSONSerialization.jsonObject(with: resp.data) as? [String: Any])?["result"] as? [String: Any] else { return nil }
            return [[frSpeed(result.double("download_rate") ?? 0), "Réception"],
                    [frSpeed(result.double("upload_rate") ?? 0), "Envoi"]]

        case .filebrowser:
            // clé « utilisateur:motdepasse » → JWT
            guard let key, let sep = key.firstIndex(of: ":") else { return nil }
            let body = try JSONSerialization.data(withJSONObject: [
                "username": String(key[..<sep]), "password": String(key[key.index(after: sep)...])])
            let login = try await HTTPClient.shared.request(
                URL(string: "\(base)/api/login")!, method: "POST",
                headers: ["Content-Type": "application/json"], body: body)
            guard login.status == 200, let jwt = String(data: login.data, encoding: .utf8),
                  !jwt.isEmpty else { return nil }
            for path in ["/api/usage/", "/api/usage"] {
                if let (json, _) = try? await HTTPClient.shared.json(
                    URL(string: base + path)!, headers: ["X-Auth": jwt]),
                   let d = json as? [String: Any], let used = d.double("used") {
                    var out = [[frBytes(used), "Stockage"]]
                    if let total = d.double("total") { out.append([frBytes(total), "Total"]) }
                    return out
                }
            }
            return nil

        case .photoprism:
            // clé « utilisateur:motdepasse » → session
            guard let key, let sep = key.firstIndex(of: ":") else { return nil }
            let body = try JSONSerialization.data(withJSONObject: [
                "username": String(key[..<sep]), "password": String(key[key.index(after: sep)...])])
            let login = try await HTTPClient.shared.request(
                URL(string: "\(base)/api/v1/session")!, method: "POST",
                headers: ["Content-Type": "application/json"], body: body)
            guard let json = try? JSONSerialization.jsonObject(with: login.data) as? [String: Any],
                  let count = (json.dict("config"))?.dict("count") else { return nil }
            return [[frInt(count.int("photos") ?? 0), "Photos"],
                    [frInt(count.int("videos") ?? 0), "Vidéos"],
                    [frInt(count.int("albums") ?? 0), "Albums"]]

        case .gitlab:
            guard let key else { return nil }
            let resp = try await HTTPClient.shared.request(
                URL(string: "\(base)/api/v4/projects?per_page=1&membership=true")!,
                headers: ["PRIVATE-TOKEN": key])
            guard resp.status == 200, let total = resp.headers["x-total"].flatMap(Int.init) else { return nil }
            return [[frInt(total), "Dépôts"]]

        case .peertube:
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/videos?count=1")!)
            guard let total = (json as? [String: Any])?.int("total") else { return nil }
            return [[frInt(total), "Vidéos"]]

        case .bookstack:
            // clé « id:secret » du jeton API
            guard let key, key.contains(":") else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/books?count=1")!,
                headers: ["Authorization": "Token \(key)"])
            guard let total = (json as? [String: Any])?.int("total") else { return nil }
            return [[frInt(total), "Livres"]]

        case .fireflyiii:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/accounts?limit=1")!,
                headers: ["Authorization": "Bearer \(key)", "Accept": "application/json"])
            guard let total = (((json as? [String: Any])?.dict("meta"))?.dict("pagination"))?.int("total") else { return nil }
            return [[frInt(total), "Comptes"]]

        case .grocy:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/stock")!, headers: ["GROCY-API-KEY": key])
            guard let stock = json as? [Any] else { return nil }
            return [[frInt(stock.count), "Produits"]]

        case .healthchecks:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v3/checks/")!, headers: ["X-Api-Key": key])
            guard let checks = (json as? [String: Any])?.array("checks")?
                .compactMap({ $0 as? [String: Any] }) else { return nil }
            let up = checks.filter { ($0["status"] as? String) == "up" }.count
            return [["\(up) / \(checks.count)", "En ligne"]]

        case .changedetection:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/watch")!, headers: ["x-api-key": key])
            guard let watches = json as? [String: Any] else { return nil }
            return [[frInt(watches.count), "Suivis"]]

        case .wordpress:
            let resp = try await HTTPClient.shared.request(
                URL(string: "\(base)/wp-json/wp/v2/posts?per_page=1")!)
            guard resp.status == 200, let total = resp.headers["x-wp-total"].flatMap(Int.init) else { return nil }
            return [[frInt(total), "Articles"]]

        case .ghost:
            // clé = Content API key
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/ghost/api/content/posts/?key=\(key)&limit=1")!)
            guard let total = (((json as? [String: Any])?.dict("meta"))?.dict("pagination"))?.int("total") else { return nil }
            return [[frInt(total), "Articles"]]

        case .matomo:
            // clé = token_auth
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/index.php?module=API&method=VisitsSummary.getVisits&idSite=1&period=day&date=today&format=json&token_auth=\(key)")!)
            guard let visits = (json as? [String: Any])?.int("value") else { return nil }
            return [[frInt(visits), "Visites"]]

        case .n8n:
            guard let key else { return nil }
            let (json, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/workflows?limit=1")!, headers: ["X-N8N-API-KEY": key])
            guard (json as? [String: Any])?["data"] != nil else { return nil }
            // le total n'est pas exposé : on compte la première page complète
            let (fullJ, _) = try await HTTPClient.shared.json(
                URL(string: "\(base)/api/v1/workflows?limit=250")!, headers: ["X-N8N-API-KEY": key])
            let count = ((fullJ as? [String: Any])?.array("data"))?.count ?? 0
            return [[frInt(count), "Workflows"]]

        default:
            return nil
        }
    }

    /// Format de clé attendu par intégration — affiché dans la feuille d'édition.
    static func keyHint(for type: IntegrationType) -> String? {
        switch type {
        case .komga, .nextcloud, .transmission, .qbittorrent, .npm, .filebrowser, .photoprism:
            String(localized: "Format : utilisateur:motdepasse")
        case .wgeasy, .deluge:
            String(localized: "Mot de passe de l'interface")
        case .bookstack:
            String(localized: "Format : id:secret (jeton API)")
        case .homeassistant:
            String(localized: "Jeton d'accès longue durée (profil → Sécurité)")
        case .plex:
            String(localized: "Jeton X-Plex-Token")
        case .navidrome:
            String(localized: "Format : utilisateur:motdepasse")
        case .generic, .omv, .vaultwarden, .traefik,
             .frigate, .scrutiny, .netdata, .esphome,
             .ollama, .peertube, .wordpress:
            nil
        default:
            String(localized: "Clé API du service")
        }
    }

    // MARK: Lecture en cours (Jellyfin /Sessions)

    struct NowPlayingSession: Sendable, Hashable {
        let id: String
        let title: String
        let user: String
        let paused: Bool
        /// Position et durée en secondes.
        let position: Int
        let duration: Int
    }

    static func jellyfinSessions(base: String, key: String) async -> [NowPlayingSession]? {
        for candidate in candidates(base) {
            guard let url = URL(string: "\(candidate)/Sessions?ActiveWithinSeconds=300") else { continue }
            guard let (json, _) = try? await HTTPClient.shared.json(url, headers: ["X-Emby-Token": key]),
                  let list = json as? [Any] else { continue }
            return list.compactMap { raw -> NowPlayingSession? in
                guard let session = raw as? [String: Any],
                      let item = session.dict("NowPlayingItem"),
                      let name = item["Name"] as? String else { return nil }
                let series = item["SeriesName"] as? String
                let play = session.dict("PlayState")
                return NowPlayingSession(
                    id: session["Id"] as? String ?? "",
                    title: series.map { "\($0) — \(name)" } ?? name,
                    user: session["UserName"] as? String ?? "",
                    paused: play?["IsPaused"] as? Bool ?? false,
                    position: Int((play?.double("PositionTicks") ?? 0) / 10_000_000),
                    duration: Int((item.double("RunTimeTicks") ?? 0) / 10_000_000))
            }
        }
        return nil
    }

    /// Pause/reprise d'une session Jellyfin (commandes PlaystateCommand).
    static func setPaused(_ paused: Bool, base: String, key: String, sessionID: String) async {
        guard !sessionID.isEmpty else { return }
        let command = paused ? "Pause" : "Unpause"
        for candidate in candidates(base) {
            guard let url = URL(string: "\(candidate)/Sessions/\(sessionID)/Playing/\(command)") else { continue }
            if let resp = try? await HTTPClient.shared.request(url, method: "POST",
                                                              headers: ["X-Emby-Token": key]),
               (200..<300).contains(resp.status) {
                return
            }
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
