import SwiftUI
import Observation
#if canImport(WidgetKit)
import WidgetKit
#endif
#if os(iOS)
import UIKit
import ActivityKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - Store central
// Deux sources de données :
// - `.demo` : le simulateur du prototype (random-walk, panne Komga scénarisée).
// - `.live` : un scheduler qui interroge chaque service (ping chaque tick,
//   métriques 1 tick sur 8 via l'API propre à chaque intégration).

@MainActor
@Observable
final class AppStore {

    // MARK: Système (bandeau)
    var t = 0
    var cpu = 9.0
    var temp = 45.3
    var ram = 12.7
    var rx = 0.4
    var tx = 0.1
    var lights = 1
    /// En mode live : vraies valeurs disponibles (source Glances).
    var systemLive = false

    // MARK: Pannes
    /// Panne scénarisée du mode démo (Komga).
    var down = false
    /// Pannes réelles du mode live (3 échecs consécutifs → hors ligne).
    var downIDs: Set<String> = []
    var downAt: Date?
    var tempAlerted = false
    /// Komga tombe en panne après ~5 ticks (mode démo).
    var panneAuto = true

    // MARK: Latences & historiques
    var pings: [String: Int] = [:]
    var latHistory: [String: [Double]] = [:]
    var cpuHistory: [String: [Double]] = [:]
    var netHistory: [String: [Double]] = [:]
    var logs: [String] = []

    // MARK: Notifications
    var notifs: [NotifItem] = Catalog.seedNotifs
    var unread = 0

    // MARK: Réglages
    var density: Density = .aere
    var layout: LayoutMode = .grille
    var iosLayout: LayoutMode = .liste
    var logosOn = true
    var net: NetMode = .local
    var tsAuto = true
    var gOrder = [0, 1, 2, 3]
    var gHidden: Set<Int> = []
    var pins: [String] = Catalog.defaultPins
    var refreshMs = 1600
    var rules: [String: Bool] = ["temp": true, "disk": true, "down": true]
    var guestOn = false
    var guestPreview = false
    var guestIds: Set<String> = ["jellyfin", "immich"]
    var syncOn = true

    /// Langue de l'app : "system", "fr", "en" ou "es".
    /// L'environnement SwiftUI bascule immédiatement ; les chaînes construites
    /// (statuts, toasts) suivent au relancement via AppleLanguages.
    var appLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "system" {
        didSet {
            UserDefaults.standard.set(appLanguage, forKey: "appLanguage")
            if appLanguage == "system" {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([appLanguage], forKey: "AppleLanguages")
            }
        }
    }

    var localeOverride: Locale? {
        appLanguage == "system" ? nil : Locale(identifier: appLanguage)
    }

    /// macOS : relance l'app pour appliquer la langue partout.
    func relaunch() {
        #if os(macOS)
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config) { _, _ in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { NSApp.terminate(nil) }
        #endif
    }

    // MARK: Source de données
    var dataMode: DataMode {
        didSet {
            guard dataMode != oldValue else { return }
            // Les listes changent : on remet à zéro les états qui en dépendent.
            serverID = "main"
            gOrder = Array(mainGroups.indices)
            gHidden = []
            downIDs = []
            failCounts = [:]
            measured = []
            systemLive = false
            // Le scénario de démo redémarre proprement.
            t = 0
            down = false
            downAt = nil
            tempAlerted = false
            if dataMode == .live { zeroHistories() }
            persist()
        }
    }
    /// Import services.yaml (mode Homelab).
    private var importedList: [Service]?
    /// Ajouts manuels (mode Homelab).
    private var customList: [Service] = []
    /// Services du serveur principal : catalogue du prototype en démo ;
    /// en Homelab, uniquement TES services (importés + ajoutés).
    var mainServices: [Service] {
        dataMode == .demo ? Catalog.services : (importedList ?? []) + customList
    }
    var mainGroups: [String] {
        dataMode == .demo ? Catalog.mainServer.groups
            : (config.importedGroups ?? Catalog.mainServer.groups)
    }
    /// Type d'intégration par service (catalogue + détectés).
    private(set) var serviceTypes: [String: IntegrationType]

    private var config: AppConfig
    private var liveMetricsCache: [String: [[String]]] = [:]
    /// Lectures en cours par service (Jellyfin), rafraîchies à chaque tick.
    var nowPlaying: [String: [LiveFetcher.NowPlayingSession]] = [:]
    private var failCounts: [String: Int] = [:]
    /// Services dont la latence a été réellement mesurée (mode live) —
    /// tant qu'ils n'y sont pas, on affiche « … », pas les valeurs d'amorçage.
    private var measured: Set<String> = []
    private var polling = false

    let network = NetworkMonitor()
    let scanner = BonjourScanner()

    // MARK: Navigation partagée
    var serverID = "main"
    var toast: String?

    private var timer: Timer?
    private var toastTask: Task<Void, Never>?
    /// Live Activity de panne en cours (iOS uniquement).
    private var outageActivity: Any?

    var server: Server { serverID == "seed" ? Catalog.seedServer : Catalog.mainServer }
    var services: [Service] { serverID == "seed" ? Catalog.seedServices : mainServices }

    /// Serveurs affichés dans la sidebar : la seedbox n'existe qu'en démo.
    var serverList: [Server] {
        dataMode == .demo ? [Catalog.mainServer, Catalog.seedServer] : [Catalog.mainServer]
    }

    func groups(of server: Server) -> [String] {
        server.id == "seed" ? server.groups : mainGroups
    }

    init() {
        let config = ConfigStore.load()
        self.config = config
        dataMode = config.dataMode
        var types = Catalog.typeByID
        importedList = config.importedServices?.map(\.service)
        customList = config.custom.map(\.service)
        for stored in (config.importedServices ?? []) + config.custom {
            types[stored.id] = IntegrationType(rawValue: stored.type) ?? .generic
        }
        serviceTypes = types
        pins = config.pins ?? Catalog.defaultPins
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        self.config.outages = (config.outages ?? []).filter { ($0.end ?? Date()) > cutoff }

        for s in Catalog.all + (importedList ?? []) + customList { seedHistory(s.id) }
        gOrder = Array(mainGroups.indices)
        if dataMode == .live { zeroHistories() }
        logs = Array(Catalog.logPool.shuffled().prefix(6))

        network.onChange = { [weak self] in self?.applyNetwork() }
        applyNetwork()
        SystemNotifier.shared.requestAuthorization()
        startTimer()
    }

    private func seedHistory(_ id: String) {
        guard pings[id] == nil else { return }
        pings[id] = 8 + Int.random(in: 0...25)
        latHistory[id] = (0..<24).map { _ in 8 + Double.random(in: 0...30) }
        var c = 10 + Double.random(in: 0...40)
        var n = Double.random(in: 0...1.5)
        cpuHistory[id] = (0..<24).map { _ in c = min(85, max(4, c + Double.random(in: -11...11))); return c }
        netHistory[id] = (0..<24).map { _ in n = min(3.1, max(0.05, n + Double.random(in: -0.55...0.55))); return n }
    }

    /// Mode live : pas de valeurs d'amorçage — graphes à plat tant que rien n'est mesuré.
    private func zeroHistories() {
        for s in mainServices {
            pings[s.id] = 0
            latHistory[s.id] = Array(repeating: 0, count: 24)
        }
    }

    private func persist() {
        config.dataMode = dataMode
        ConfigStore.save(config)
    }

    /// Bascule locale/Tailscale selon le réseau (README : NWPathMonitor + daemon TS).
    private func applyNetwork() {
        guard tsAuto else { return }
        if network.onLocalNetwork {
            net = .local
        } else if network.tailscaleActive {
            net = .tailscale
        }
    }

    // MARK: - Horloge

    func setRefresh(_ ms: Int) {
        refreshMs = ms
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        let interval = Double(refreshMs) / 1000
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func walk(_ v: Double, _ lo: Double, _ hi: Double, _ amp: Double) -> Double {
        min(hi, max(lo, v + Double.random(in: -amp / 2 ... amp / 2)))
    }

    func tick() {
        t += 1
        if dataMode == .live {
            liveTick()
        } else {
            demoTick()
            publishSharedState()
        }
    }

    // MARK: - État partagé (widgets / complications)

    private var lastWidgetSignature = ""
    private var lastWidgetReload = Date.distantPast

    private func publishSharedState() {
        let downMain = mainServices.filter { isDown($0) }
        let pins = pinnedServices.isEmpty ? Array(mainServices.prefix(4)) : pinnedServices
        var rows = pins.prefix(3).map {
            SharedPinned(mono: $0.mono, name: shortName($0.name),
                         ping: pingShort($0), down: isDown($0))
        }
        if let d = downMain.first(where: { s in !rows.contains { $0.name == shortName(s.name) } }) {
            rows.append(SharedPinned(mono: d.mono, name: shortName(d.name), ping: "PANNE", down: true))
        } else if let last = pins.dropFirst(3).first {
            rows.append(SharedPinned(mono: last.mono, name: shortName(last.name),
                                     ping: pingShort(last), down: isDown(last)))
        }
        let hasSystem = dataMode == .demo || systemLive
        SharedState(updatedAt: Date(),
                    live: dataMode == .live,
                    online: mainServices.count - downMain.count,
                    total: mainServices.count,
                    downNames: downMain.map(\.name),
                    cpu: hasSystem ? cpu : nil,
                    temp: hasSystem ? temp : nil,
                    pinned: Array(rows)).save()

        // Reload des widgets : au changement d'état, sinon toutes les 5 min
        let signature = "\(mainServices.count)|\(downMain.map(\.id).joined())|\(dataMode.rawValue)"
        if signature != lastWidgetSignature || Date().timeIntervalSince(lastWidgetReload) > 300 {
            lastWidgetSignature = signature
            lastWidgetReload = Date()
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }

    private func shortName(_ name: String) -> String {
        switch name {
        case "Home Assistant": "Home A."
        case "UniFi Controller": "UniFi"
        default: name
        }
    }

    // MARK: - Mode démo (le simulateur du prototype)

    private func demoTick() {
        for s in Catalog.all {
            if down && s.id == "komga" {
                latHistory[s.id]?.append(0)
            } else {
                let p = Int(walk(Double(pings[s.id] ?? 12), 4, 46, 12).rounded())
                pings[s.id] = p
                latHistory[s.id]?.append(Double(p))
            }
            trimHistories(s.id)
        }
        cpu = walk(cpu, 3, 34, 9).rounded()
        temp = (walk(temp, 41, 52, 2.4) * 10).rounded() / 10
        ram = (walk(ram, 10.8, 13.9, 0.7) * 10).rounded() / 10
        rx = (walk(rx, 0, 3.2, 1.4) * 10).rounded() / 10
        tx = (walk(tx, 0, 0.9, 0.4) * 10).rounded() / 10
        if Double.random(in: 0...1) < 0.12 { lights = max(0, min(10, lights + (Bool.random() ? 1 : -1))) }
        appendLog()
        checkTempAlert()

        // Panne simulée : Komga au 5e tick
        if panneAuto && !down && t == 5 {
            down = true
            downAt = Date()
            pushNotif(title: String(localized: "Komga ne répond plus"),
                      sub: String(localized: "Délai dépassé (timeout) — 3 tentatives échouées"))
            startOutageActivity(serviceName: "Komga")
            #if os(watchOS)
            WKInterfaceDevice.current().play(.failure)
            #endif
        }
    }

    private func trimHistories(_ id: String) {
        if (latHistory[id]?.count ?? 0) > 24 { latHistory[id]?.removeFirst() }
        if var c = cpuHistory[id] {
            c.append(min(85, max(4, (c.last ?? 20) + Double.random(in: -11...11))))
            if c.count > 24 { c.removeFirst() }
            cpuHistory[id] = c
        }
        if var n = netHistory[id] {
            n.append(min(3.1, max(0.05, (n.last ?? 0.5) + Double.random(in: -0.55...0.55))))
            if n.count > 24 { n.removeFirst() }
            netHistory[id] = n
        }
    }

    private func appendLog() {
        logs.append(Catalog.logPool[t % Catalog.logPool.count])
        if logs.count > 6 { logs.removeFirst() }
    }

    /// Alerte température (seuil 50 °C, hystérésis 48 °C) — commune aux deux modes.
    private func checkTempAlert() {
        if rules["temp"] == true && temp > 50 && !tempAlerted {
            tempAlerted = true
            pushNotif(title: String(localized: "Température élevée"),
                      sub: String(localized: "CPU à \(fr(temp)) °C — seuil de 50 °C dépassé"))
        } else if tempAlerted && temp < 48 {
            tempAlerted = false
        }
    }

    // MARK: - Mode live (vraies requêtes)

    private struct PollTarget: Sendable {
        let id: String
        let name: String
        let url: String
        /// Base de l'API (gethomepage `widget.url`) si différente du href.
        let apiBase: String
        let type: IntegrationType
        let key: String?
    }

    private func liveTick() {
        guard !polling else { return }
        polling = true
        appendLog()

        let targets = services.map {
            PollTarget(id: $0.id, name: $0.name, url: fullURL($0),
                       apiBase: $0.apiURL ?? fullURL($0),
                       type: type(of: $0), key: apiKey(for: $0.id))
        }
        let wantMetrics = t % 8 == 1 || liveMetricsCache.isEmpty
        let glances = targets.first { $0.type == .glances }

        Task { [weak self] in
            var pings: [String: (ok: Bool, ms: Int)] = [:]
            var metrics: [String: [[String]]] = [:]
            var sessions: [String: [LiveFetcher.NowPlayingSession]] = [:]

            await withTaskGroup(of: (String, (Bool, Int), [[String]]?, [LiveFetcher.NowPlayingSession]?).self) { group in
                for target in targets {
                    group.addTask {
                        let ping = await LiveFetcher.ping(target.url)
                        var m: [[String]]? = nil
                        var np: [LiveFetcher.NowPlayingSession]? = nil
                        if ping.ok && wantMetrics {
                            m = await LiveFetcher.metrics(type: target.type, base: target.apiBase, key: target.key)
                        }
                        // Lecture en cours : à chaque tick (la progression avance)
                        if ping.ok, target.type == .jellyfin, let key = target.key {
                            np = await LiveFetcher.jellyfinSessions(base: target.apiBase, key: key)
                        }
                        return (target.id, ping, m, np)
                    }
                }
                for await (id, ping, m, np) in group {
                    pings[id] = ping
                    if let m { metrics[id] = m }
                    sessions[id] = np ?? []
                }
            }
            let system = glances != nil ? await LiveFetcher.systemBand(base: glances!.apiBase) : nil
            self?.applyLive(targets: targets, pings: pings, metrics: metrics,
                            sessions: sessions, system: system)
        }
    }

    private func applyLive(targets: [PollTarget],
                           pings results: [String: (ok: Bool, ms: Int)],
                           metrics: [String: [[String]]],
                           sessions: [String: [LiveFetcher.NowPlayingSession]],
                           system: LiveFetcher.SystemBand?) {
        for target in targets {
            guard let result = results[target.id] else { continue }
            if result.ok {
                pings[target.id] = result.ms
                latHistory[target.id]?.append(Double(result.ms))
                failCounts[target.id] = 0
                measured.insert(target.id)
                if downIDs.remove(target.id) != nil {
                    closeOutageRecord(target.id)
                    if rules["down"] == true {
                        pushNotif(title: String(localized: "\(target.name) de nouveau en ligne"),
                                  sub: String(localized: "Le service répond à nouveau."),
                                  critical: false)
                    }
                    if downIDs.isEmpty {
                        downAt = nil
                        endOutageActivity()
                    }
                }
            } else {
                latHistory[target.id]?.append(0)
                failCounts[target.id, default: 0] += 1
                // « Après 3 tentatives échouées » → HORS LIGNE
                if failCounts[target.id] == 3 && !downIDs.contains(target.id) {
                    downIDs.insert(target.id)
                    config.outages = (config.outages ?? []) + [StoredOutage(serviceID: target.id, start: Date())]
                    persist()
                    if downAt == nil { downAt = Date() }
                    if rules["down"] == true {
                        pushNotif(title: String(localized: "\(target.name) ne répond plus"),
                                  sub: String(localized: "Délai dépassé (timeout) — 3 tentatives échouées"))
                    }
                    startOutageActivity(serviceName: target.name)
                    #if os(watchOS)
                    WKInterfaceDevice.current().play(.failure)
                    #endif
                }
            }
            trimHistories(target.id)
        }
        for (id, m) in metrics { liveMetricsCache[id] = m }
        for (id, np) in sessions where serviceTypes[id] == .jellyfin { nowPlaying[id] = np }
        if let system {
            systemLive = true
            cpu = system.cpu
            temp = system.temp
            ram = system.ramFreeGB
            checkTempAlert()
        }
        polling = false
        publishSharedState()
    }

    // MARK: - Vues dérivées

    func type(of s: Service) -> IntegrationType {
        serviceTypes[s.id] ?? .generic
    }

    func isDown(_ s: Service) -> Bool {
        dataMode == .live ? downIDs.contains(s.id) : (down && s.id == "komga")
    }

    /// Au moins une panne en cours (badge, bandeaux, île).
    var anyDown: Bool {
        dataMode == .live ? !downIDs.isEmpty : down
    }

    var downList: [Service] { services.filter { isDown($0) } }
    var downName: String { downList.first?.name ?? "Komga" }

    /// Latence affichée, +18 ms via Tailscale (mode démo uniquement — en live
    /// la latence mesurée inclut déjà le détour).
    func ping(_ s: Service) -> Int {
        (pings[s.id] ?? 0) + (dataMode == .demo && net == .tailscale ? 18 : 0)
    }

    /// Latence pas encore mesurée (mode live, avant la première réponse).
    private func pending(_ s: Service) -> Bool {
        dataMode == .live && !measured.contains(s.id)
    }

    func pingText(_ s: Service) -> String {
        isDown(s) ? String(localized: "HORS LIGNE") : (pending(s) ? "…" : "\(ping(s)) MS")
    }
    func pingShort(_ s: Service) -> String {
        isDown(s) ? String(localized: "PANNE") : (pending(s) ? "…" : "\(ping(s)) MS")
    }
    func statusText(_ s: Service) -> String {
        isDown(s) ? String(localized: "HORS LIGNE") : (pending(s) ? String(localized: "CONNEXION…") : String(localized: "EN LIGNE · \(ping(s)) MS"))
    }

    /// URL affichée (démo : bascule Tailscale simulée).
    func url(_ s: Service) -> String {
        dataMode == .demo && net == .tailscale ? "\(s.id).tail1a2b.ts.net" : s.url
    }

    /// URL requêtable (schéma inclus).
    func fullURL(_ s: Service) -> String {
        YamlConfig.fullURL(url(s))
    }

    func iconURL(_ s: Service) -> URL? {
        guard logosOn, let slug = s.iconSlug else { return nil }
        return URL(string: Catalog.cdn + slug + ".png")
    }

    /// Métriques : live = cache des fetchers, démo = simulateur du prototype.
    func metrics(_ s: Service) -> [[String]] {
        if dataMode == .live {
            return liveMetricsCache[s.id] ?? s.metrics ?? []
        }
        switch s.id {
        case "transmission":
            return [["\(fr(rx)) Mo/s", "Réception"], ["\(fr(tx)) Mo/s", "Envoi"], ["30", "En partage"]]
        case "seed-qbit":
            return [["\(fr(rx * 2.1)) Mo/s", "Réception"], ["\(fr(tx * 3.4)) Mo/s", "Envoi"], ["142", "En partage"]]
        case "homeassistant":
            return [["1 / 3", "Présents"], ["\(lights) / 10", "Lumières"], ["27 / 68", "Interrupteurs"]]
        case "uptimekuma":
            return [[down ? "16 / 17" : "17 / 17", "En ligne"], ["99,98 %", "Dispo. 30 j"], ["3", "Alertes conf."]]
        default:
            return s.metrics ?? []
        }
    }

    // MARK: Bandeau système — « — » en live sans source Glances

    private func bandValue(_ text: String) -> String {
        dataMode == .live && !systemLive ? "—" : text
    }

    var cpuText: String { bandValue("\(Int(cpu)) %") }
    var tempText: String { bandValue("\(fr(temp))°") }
    var tempLongText: String { bandValue("\(fr(temp)) °C") }
    var ramText: String { bandValue(fr(ram)) }
    var ramLongText: String { bandValue("\(fr(ram)) Go") }
    var rxText: String { dataMode == .live ? "—" : "\(fr(rx)) Mo/s" }
    var txText: String { dataMode == .live ? "—" : "\(fr(tx)) Mo/s" }

    /// Groupes visibles, dans l'ordre configuré (le seedbox n'est pas réordonnable).
    func visibleGroups(of server: Server? = nil) -> [(index: Int, name: String, services: [Service])] {
        let srv = server ?? self.server
        let list = srv.id == "seed" ? Catalog.seedServices : mainServices
        let names = groups(of: srv)
        let order = srv.id == "seed"
            ? Array(names.indices)
            : gOrder.filter { !gHidden.contains($0) && $0 < names.count }
        return order.map { gi in
            (gi, names[gi], list.filter { $0.group == gi })
        }
    }

    /// Services visibles côté iPhone (mode invité = seuls les services autorisés).
    func homeGroups() -> [(index: Int, name: String, services: [Service])] {
        let groups = visibleGroups(of: Catalog.mainServer)
        guard guestPreview else { return groups }
        return groups
            .map { ($0.index, $0.name, $0.services.filter { guestIds.contains($0.id) }) }
            .filter { !$0.2.isEmpty }
    }

    var pinnedServices: [Service] {
        let ids = pins.isEmpty ? Catalog.defaultPins : pins
        return ids.compactMap { id in mainServices.first { $0.id == id } }
    }

    var downCount: Int {
        dataMode == .live ? services.filter { downIDs.contains($0.id) }.count : (down ? 1 : 0)
    }
    var totalCount: Int { services.count }
    var onlineCount: Int { totalCount - downCount }

    var downDurationMin: Int {
        guard let downAt else { return 0 }
        return max(1, Int(Date().timeIntervalSince(downAt) / 60))
    }

    /// Graphe du détail : 24 points selon la métrique choisie.
    func bars(_ id: String, metric: DetailMetric) -> [Double] {
        switch metric {
        case .lat: latHistory[id]?.map { $0 / 46 } ?? []
        case .cpu: cpuHistory[id]?.map { $0 / 85 } ?? []
        case .net: netHistory[id]?.map { $0 / 3.2 } ?? []
        }
    }

    func bigValue(_ s: Service, metric: DetailMetric) -> String {
        switch metric {
        case .lat: isDown(s) || pending(s) ? "—" : "\(ping(s)) MS"
        case .cpu: "\(Int((cpuHistory[s.id]?.last ?? 0).rounded())) %"
        case .net: "\(fr(netHistory[s.id]?.last ?? 0)) Mo/s"
        }
    }

    // MARK: - Statut 30 j

    private func closeOutageRecord(_ id: String) {
        guard var outages = config.outages,
              let i = outages.lastIndex(where: { $0.serviceID == id && $0.end == nil }) else { return }
        outages[i].end = Date()
        config.outages = outages
        persist()
    }

    /// Mur 30 j : incidents de démo en mode démo, vraies pannes observées en Homelab.
    func incidents(for s: Service) -> [Incident] {
        if dataMode == .demo {
            return Catalog.incidents.filter { $0.serviceID == s.id }
        }
        var minutesByDay: [Int: Double] = [:]
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for outage in config.outages ?? [] where outage.serviceID == s.id {
            let daysAgo = cal.dateComponents([.day], from: cal.startOfDay(for: outage.start), to: today).day ?? 0
            guard daysAgo < 30 else { continue }
            // La panne en cours est déjà représentée par la barre du jour
            let end = outage.end ?? Date()
            minutesByDay[29 - daysAgo, default: 0] += max(1, end.timeIntervalSince(outage.start) / 60)
        }
        return minutesByDay.map { day, minutes in
            Incident(serviceID: s.id, day: day,
                     duration: String(localized: "\(Int(minutes)) min"),
                     cause: String(localized: "Délai dépassé (timeout) — 3 tentatives échouées"))
        }
    }

    func availability(_ s: Service) -> String {
        var minutes = 0.0
        for inc in incidents(for: s) {
            minutes += Double(inc.duration.split(separator: " ").first.flatMap { Int($0) } ?? 0)
        }
        if isDown(s) { minutes += Double(downDurationMin) }
        let pct = 100 - minutes / (30 * 24 * 60) * 100
        return minutes == 0 ? "100 %" : fr((pct * 100).rounded() / 100, 2) + " %"
    }

    // MARK: - Clés API (config-first — le trousseau redemande à chaque rebuild)

    func apiKey(for id: String) -> String? {
        if let keys = config.apiKeys { return keys[id] }
        // Migration : anciennes configs sans apiKeys → trousseau
        return KeychainStore.get(id)
    }

    private func setApiKey(_ key: String, for id: String) {
        var keys = config.apiKeys ?? [:]
        keys[id] = key
        config.apiKeys = keys
        KeychainStore.set(key, for: id)
        persist()
    }

    // MARK: - Configuration (ajout, YAML)

    /// Ajout manuel (« + ») ou depuis le scan — le type est détecté à la connexion.
    func addService(name: String, url: String, group: Int, apiKey: String,
                    knownType: IntegrationType? = nil) {
        let id = "custom-" + UUID().uuidString.prefix(8).lowercased()
        let service = Service(id: id, mono: YamlConfig.mono(name), name: name,
                              desc: String(localized: "Ajouté à la main"), group: group, url: url,
                              iconSlug: nil, metrics: nil)
        customList.append(service)
        serviceTypes[id] = knownType ?? .generic
        seedHistory(id)
        if !apiKey.isEmpty { setApiKey(apiKey, for: id) }
        config.custom.append(StoredService(service: service, type: knownType ?? .generic))
        persist()
        fireToast(String(localized: "Service « \(name) » ajouté au groupe \(mainGroups[group])"))

        // Détection asynchrone du type si inconnu
        guard knownType == nil else { return }
        Task { [weak self] in
            let detected = await LiveFetcher.detect(YamlConfig.fullURL(url))
            guard let self, let type = detected.type, type != .generic else { return }
            serviceTypes[id] = type
            if let i = config.custom.firstIndex(where: { $0.id == id }) {
                config.custom[i].type = type.rawValue
                persist()
            }
            fireToast(String(localized: "« \(name) » reconnu : \(type.rawValue)"))
        }
    }

    /// Ajout depuis le scan Bonjour.
    func addScanned(_ found: BonjourScanner.Found) {
        addService(name: found.name, url: found.url, group: 0, apiKey: "",
                   knownType: found.type)
    }

    /// Modification (mode Homelab). Clé API vide = inchangée.
    func updateService(_ id: String, name: String, url: String, group: Int, apiKey: String) {
        guard dataMode == .live else { return }
        func rebuild(_ s: Service) -> Service {
            Service(id: s.id, mono: YamlConfig.mono(name), name: name, desc: s.desc,
                    group: group, url: url, iconSlug: s.iconSlug, metrics: nil,
                    apiURL: url == s.url ? s.apiURL : nil)
        }
        let urlChanged: Bool
        if let i = importedList?.firstIndex(where: { $0.id == id }) {
            urlChanged = importedList![i].url != url
            importedList![i] = rebuild(importedList![i])
        } else if let i = customList.firstIndex(where: { $0.id == id }) {
            urlChanged = customList[i].url != url
            customList[i] = rebuild(customList[i])
        } else {
            return
        }
        let type = serviceTypes[id] ?? .generic
        let updated = mainServices.first { $0.id == id }!
        if let i = config.importedServices?.firstIndex(where: { $0.id == id }) {
            config.importedServices![i] = StoredService(service: updated, type: type)
        }
        if let i = config.custom.firstIndex(where: { $0.id == id }) {
            config.custom[i] = StoredService(service: updated, type: type)
        }
        if !apiKey.isEmpty { setApiKey(apiKey, for: id) }
        liveMetricsCache[id] = nil
        measured.remove(id)
        failCounts[id] = 0
        persist()
        publishSharedState()
        fireToast(String(localized: "« \(name) » modifié"))

        // L'URL a changé : on redétecte le type
        if urlChanged {
            Task { [weak self] in
                let detected = await LiveFetcher.detect(YamlConfig.fullURL(url))
                guard let self, let newType = detected.type, newType != .generic else { return }
                serviceTypes[id] = newType
                if let i = config.importedServices?.firstIndex(where: { $0.id == id }) {
                    config.importedServices![i].type = newType.rawValue
                }
                if let i = config.custom.firstIndex(where: { $0.id == id }) {
                    config.custom[i].type = newType.rawValue
                }
                persist()
            }
        }
    }

    /// Suppression (mode Homelab — le catalogue de démo est figé).
    func removeService(_ s: Service) {
        guard dataMode == .live else { return }
        importedList?.removeAll { $0.id == s.id }
        customList.removeAll { $0.id == s.id }
        config.importedServices?.removeAll { $0.id == s.id }
        config.custom.removeAll { $0.id == s.id }
        config.apiKeys?[s.id] = nil
        // Pas de SecItemDelete : toucher un élément de trousseau créé par un
        // autre build redéclencherait la boîte de dialogue d'autorisation.
        serviceTypes[s.id] = nil
        downIDs.remove(s.id)
        failCounts[s.id] = nil
        measured.remove(s.id)
        liveMetricsCache[s.id] = nil
        pins.removeAll { $0 == s.id }
        config.pins = pins
        persist()
        publishSharedState()
        fireToast(String(localized: "« \(s.name) » supprimé"))
    }

    /// Test de connexion réel (AddService) — latence + type détecté.
    func testConnection(url: String) {
        fireToast(String(localized: "Test de \(YamlConfig.fullURL(url))…"))
        Task { [weak self] in
            let (type, ms) = await LiveFetcher.detect(YamlConfig.fullURL(url))
            if let type {
                self?.fireToast(String(localized: "Connexion réussie — \(ms) ms · \(type == .generic ? String(localized: "service web") : type.rawValue)"))
            } else {
                self?.fireToast(String(localized: "Aucune réponse — vérifie l'URL et le réseau"))
            }
        }
    }

    /// Import services.yaml : remplace la config Homelab (source de vérité)
    /// et bascule en mode Homelab.
    func importYAML(_ text: String) {
        do {
            let result = try YamlConfig.parse(text)
            importedList = result.services.map(\.service)
            customList = []
            config.importedGroups = result.groups
            config.importedServices = result.services
            config.custom = []
            for stored in result.services {
                serviceTypes[stored.id] = IntegrationType(rawValue: stored.type) ?? .generic
                seedHistory(stored.id)
            }
            var keys = config.apiKeys ?? [:]
            for (id, key) in result.keys {
                keys[id] = key
                KeychainStore.set(key, for: id)
            }
            config.apiKeys = keys
            dataMode = .live
            gOrder = Array(result.groups.indices)
            gHidden = []
            downIDs = []
            failCounts = [:]
            liveMetricsCache = [:]
            persist()
            fireToast(String(localized: "Import de services.yaml — \(result.services.count) services et \(result.groups.count) groupes reconnus"))
        } catch {
            fireToast(String(localized: "Import impossible — services.yaml illisible"))
        }
    }

    /// Export services.yaml (copié dans le presse-papiers).
    func exportYAML() {
        do {
            let yaml = try YamlConfig.export(groups: mainGroups, services: mainServices,
                                             types: serviceTypes, keys: config.apiKeys ?? [:])
            #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(yaml, forType: .string)
            #elseif os(iOS)
            UIPasteboard.general.string = yaml
            #endif
            fireToast(String(localized: "services.yaml copié — compatible gethomepage.dev"))
        } catch {
            fireToast(String(localized: "Export impossible"))
        }
    }

    // MARK: - Live Activity (île dynamique + écran verrouillé)

    private func startOutageActivity(serviceName: String) {
        #if os(iOS)
        guard outageActivity == nil,
              ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = OutageActivityAttributes(serviceName: serviceName)
        let state = OutageActivityAttributes.ContentState(
            online: onlineCount, total: totalCount, downSince: downAt ?? Date())
        outageActivity = try? Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil))
        #endif
    }

    private func endOutageActivity() {
        #if os(iOS)
        if let activity = outageActivity as? Activity<OutageActivityAttributes> {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
            outageActivity = nil
        }
        #endif
    }

    // MARK: - Actions

    func fireToast(_ msg: String) {
        toast = msg
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            if !Task.isCancelled { toast = nil }
        }
    }

    func markAllRead() {
        unread = 0
        notifs = notifs.map { var n = $0; n.unread = false; return n }
    }

    private func pushNotif(title: String, sub: String, critical: Bool = true) {
        notifs.insert(NotifItem(title: title, sub: sub, date: Date(), alert: critical, unread: true), at: 0)
        unread += 1
        SystemNotifier.shared.post(title: title, body: sub, critical: critical)
    }

    func openWeb(_ s: Service) {
        let target = fullURL(s)
        #if os(macOS)
        if let u = URL(string: target) { NSWorkspace.shared.open(u) }
        #elseif os(iOS)
        if let u = URL(string: target) { UIApplication.shared.open(u) }
        #endif
        fireToast(String(localized: "Ouverture de \(target) dans le navigateur…"))
    }

    func copyURL(_ s: Service) {
        let target = fullURL(s)
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(target, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = target
        #endif
        fireToast(String(localized: "URL copiée — \(target)"))
    }

    func restart(_ s: Service) {
        if dataMode == .demo && down && s.id == "komga" {
            down = false
            downAt = nil
            endOutageActivity()
        }
        fireToast(String(localized: "Redémarrage du conteneur « \(s.id) » demandé…"))
    }

    func moveGroup(_ idx: Int, _ delta: Int) {
        let j = idx + delta
        guard j >= 0, j < gOrder.count else { return }
        gOrder.swapAt(idx, j)
    }

    func togglePin(_ id: String) {
        if let i = pins.firstIndex(of: id) {
            pins.remove(at: i)
        } else if pins.count < 4 {
            pins.append(id)
        } else {
            fireToast(String(localized: "4 épinglés maximum"))
            return
        }
        config.pins = pins
        persist()
        publishSharedState()
    }
}
