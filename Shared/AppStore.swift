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

// MARK: - Langues proposées
// Chaque libellé reste dans sa propre langue (endonyme) : une liste de langues
// ne se traduit pas, sinon l'utilisateur ne reconnaît plus la sienne.
enum AppLanguage {
    @MainActor
    static var segments: [(String, String)] {
        [("system", String(localized: "Système")),
         ("fr", "Français"), ("en", "English"), ("es", "Español"),
         ("zh-Hans", "简体中文"), ("ar", "العربية")]
    }
}

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
    /// Volumes déjà signalés comme presque pleins — une seule alerte tant que
    /// le volume n'est pas redescendu sous l'hystérésis.
    var diskAlerted: Set<String> = []
    /// Remplissage détaillé par service (OMV), pour l'alerte et sa liste d'exclusions.
    var volumeFills: [String: [LiveFetcher.VolumeFill]] = [:]
    /// Volumes exclus de l'alerte disque (clé `volumeKey(_:_:)`).
    private(set) var mutedVolumes: Set<String> = []
    /// Komga tombe en panne après ~5 ticks (mode démo).
    var panneAuto = true

    // MARK: Latences & historiques
    var pings: [String: Int] = [:]
    var latHistory: [String: [Double]] = [:]
    var cpuHistory: [String: [Double]] = [:]
    var netHistory: [String: [Double]] = [:]
    var logs: [String] = []

    // MARK: Notifications
    /// Peuplé dans `init` : historique persisté, ou seed de démo, ou rien.
    var notifs: [NotifItem] = []
    var unread = 0
    /// Nombre de notifications conservées d'un lancement à l'autre.
    private let notifLimit = 60

    // MARK: Réglages
    var density: Density = .aere
    var layout: LayoutMode = .grille
    var iosLayout: LayoutMode = .liste
    var logosOn = true
    var gOrder = [0, 1, 2, 3]
    var gHidden: Set<Int> = []
    var pins: [String] = Catalog.defaultPins
    var refreshMs = 1600
    private(set) var rules: [String: Bool] = ["temp": true, "disk": true, "down": true]
    var guestOn = false
    var guestPreview = false
    var guestIds: Set<String> = ["jellyfin", "immich"]
    var syncOn = true

    /// Langue de l'app : "system" ou un code de `AppLanguage.segments`.
    /// L'environnement SwiftUI bascule immédiatement ; les chaînes construites
    /// (statuts, toasts) suivent au relancement via AppleLanguages.
    var appLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "system" {
        didSet {
            guard appLanguage != oldValue else { return }
            UserDefaults.standard.set(appLanguage, forKey: "appLanguage")
            fireToast(String(localized: "Relance l'app pour appliquer partout."))
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

    /// L'environnement `locale` ne retourne pas la mise en page à lui seul :
    /// l'arabe choisi à la main resterait en LTR jusqu'au relancement.
    var layoutDirectionOverride: LayoutDirection? {
        guard let locale = localeOverride else { return nil }
        return locale.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
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
            downNotified = []
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

    /// Services dont la panne a déjà été notifiée — l'alerte ne part qu'une fois.
    private var downNotified: Set<String> = []
    /// Seuil de la règle « Hors ligne > 5 min ». Trois échecs suffisent à
    /// afficher le service hors ligne ; l'alerte, elle, attend que la panne
    /// dure, sinon un redémarrage de conteneur réveille tout le monde.
    private static let downAlertDelay: TimeInterval = 5 * 60

    /// Depuis quand plus rien ne répond — `nil` dès qu'un service redonne signe.
    /// Voir la garde en tête d'`applyLive`.
    private(set) var unreachableSince: Date?
    private var unreachableCycles = 0

    /// Plus aucune route vers le homelab. Un état distinct d'une panne : l'app
    /// ne sait pas ce qui est tombé, elle sait qu'elle ne joint rien.
    var homelabUnreachable: Bool { dataMode == .live && unreachableSince != nil }

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
        // Une panne encore ouverte au lancement date d'une session précédente :
        // on l'arrête à la dernière activité connue plutôt que de la faire courir
        // pendant tout le temps où l'app était fermée. Si le service est toujours
        // à terre, le prochain relevé rouvrira un enregistrement.
        self.config.outages = (config.outages ?? []).map { outage in
            guard outage.end == nil else { return outage }
            var sealed = outage
            sealed.end = max(config.lastTick ?? outage.start, outage.start)
            return sealed
        }.filter { ($0.end ?? Date()) > cutoff }

        rules = config.alertRules ?? rules
        mutedVolumes = Set(config.mutedVolumes ?? [])
        // Les trois notifications de `seedNotifs` illustrent la démo : en mode
        // Homelab elles feraient croire à des événements réels du serveur.
        if let stored = config.notifs {
            notifs = stored.map(\.item)
        } else if config.dataMode == .demo {
            notifs = Catalog.seedNotifs
        }
        unread = notifs.filter(\.unread).count

        for s in Catalog.all + (importedList ?? []) + customList { seedHistory(s.id) }
        gOrder = Array(mainGroups.indices)
        if dataMode == .live { zeroHistories() }
        logs = Array(Catalog.logPool.shuffled().prefix(6))

        // Tant que le tutoriel n'est pas fini, ni horloge ni demande
        // d'autorisation : la panne scénarisée de la démo posterait une
        // notification système et une Live Activity par-dessus l'écran
        // « Bienvenue » (cf. `onboardingDone`).
        if onboardingDone {
            SystemNotifier.shared.requestAuthorization()
            startTimer()
        }
    }

    /// Le tutoriel de premier lancement gèle le simulateur.
    /// watchOS n'a pas d'onboarding : l'horloge y démarre tout de suite.
    private var onboardingDone: Bool {
        #if os(watchOS)
        true
        #else
        UserDefaults.standard.bool(forKey: "hasOnboarded")
        #endif
    }

    /// Sortie du tutoriel : autorisation notifications puis démarrage de l'horloge.
    func finishOnboarding() {
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

    // MARK: - Horloge

    func setRefresh(_ ms: Int) {
        refreshMs = ms
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = nil
        guard onboardingDone else { return }
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

    /// Alerte disque (seuil 90 %, hystérésis 85 %). Lit les métriques déjà
    /// remontées plutôt qu'une requête dédiée : « Occupation » et « Plus rempli »
    /// sont des pourcentages entiers, et le libellé stocké est toujours la clé
    /// source française quelle que soit la langue affichée.
    /// Règle « Hors ligne > 5 min » : on alerte quand la panne dure, pas quand
    /// elle est détectée. La date de référence est celle de l'enregistrement
    /// ouvert, donc une panne reprise au lancement garde son ancienneté.
    private func checkDownAlerts() {
        guard rules["down"] == true else { return }
        let now = Date()
        for id in downIDs where !downNotified.contains(id) {
            guard let start = (config.outages ?? [])
                    .last(where: { $0.serviceID == id && $0.end == nil })?.start,
                  now.timeIntervalSince(start) >= Self.downAlertDelay,
                  let s = services.first(where: { $0.id == id }) else { continue }
            downNotified.insert(id)
            pushNotif(title: String(localized: "\(s.name) ne répond plus"),
                      sub: String(localized: "Hors ligne depuis plus de 5 minutes."))
        }
    }

    private func checkDiskAlerts() {
        for s in services {
            // OMV détaille ses volumes : on alerte celui qui déborde, et les
            // montages pleins par nature peuvent être exclus un par un.
            if let fills = volumeFills[s.id], !fills.isEmpty {
                for v in fills {
                    let key = volumeKey(s.id, v.id)
                    if v.percent > 90 && !diskAlerted.contains(key) {
                        guard rules["disk"] == true, !mutedVolumes.contains(key) else { continue }
                        diskAlerted.insert(key)
                        pushNotif(title: String(localized: "Disque presque plein"),
                                  sub: String(localized: "\(s.name) — \(v.label) rempli à \(v.percent) %"))
                    } else if v.percent < 85 {
                        diskAlerted.remove(key)
                    }
                }
                continue
            }
            guard let peak = fillPercent(liveMetricsCache[s.id]) else { continue }
            if peak > 90 && !diskAlerted.contains(s.id) {
                guard rules["disk"] == true, !mutedVolumes.contains(volumeKey(s.id, "*")) else { continue }
                diskAlerted.insert(s.id)
                pushNotif(title: String(localized: "Disque presque plein"),
                          sub: String(localized: "\(s.name) — volume rempli à \(peak) %"))
            } else if peak < 85 {
                diskAlerted.remove(s.id)
            }
        }
    }

    func volumeKey(_ serviceID: String, _ volumeID: String) -> String { "\(serviceID)|\(volumeID)" }

    /// Surveillance d'un volume (décoché = exclu de l'alerte disque).
    func setVolumeMonitored(_ serviceID: String, _ volumeID: String, _ on: Bool) {
        let key = volumeKey(serviceID, volumeID)
        if on {
            mutedVolumes.remove(key)
        } else {
            mutedVolumes.insert(key)
            diskAlerted.remove(key)
        }
        config.mutedVolumes = Array(mutedVolumes).sorted()
        persist()
    }

    /// Volumes connus, groupés par service, pour la liste des Réglages.
    var monitoredVolumes: [(service: Service, fills: [LiveFetcher.VolumeFill])] {
        services.compactMap { s in
            guard let fills = volumeFills[s.id], !fills.isEmpty else { return nil }
            return (s, fills.sorted { $0.percent > $1.percent })
        }
    }

    private func fillPercent(_ cells: [[String]]?) -> Int? {
        cells?.compactMap { cell -> Int? in
            guard cell.count > 1, cell[1] == "Occupation" || cell[1] == "Plus rempli" else { return nil }
            return Int(cell[0].prefix { $0.isNumber })
        }.max()
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
            var volumes: [String: [LiveFetcher.VolumeFill]] = [:]

            await withTaskGroup(of: (String, (Bool, Int), [[String]]?, [LiveFetcher.NowPlayingSession]?,
                                     [LiveFetcher.VolumeFill]?).self) { group in
                for target in targets {
                    group.addTask {
                        let ping = await LiveFetcher.ping(target.url)
                        var m: [[String]]? = nil
                        var np: [LiveFetcher.NowPlayingSession]? = nil
                        var vol: [LiveFetcher.VolumeFill]? = nil
                        if ping.ok && wantMetrics {
                            (m, vol) = await LiveFetcher.metricsAndVolumes(
                                type: target.type, base: target.apiBase, key: target.key)
                        }
                        // Lecture en cours : à chaque tick (la progression avance)
                        if ping.ok, target.type == .jellyfin, let key = target.key {
                            np = await LiveFetcher.jellyfinSessions(base: target.apiBase, key: key)
                        }
                        return (target.id, ping, m, np, vol)
                    }
                }
                for await (id, ping, m, np, vol) in group {
                    pings[id] = ping
                    if let m { metrics[id] = m }
                    if let vol { volumes[id] = vol }
                    sessions[id] = np ?? []
                }
            }
            let system = glances != nil ? await LiveFetcher.systemBand(base: glances!.apiBase) : nil
            self?.applyLive(targets: targets, pings: pings, metrics: metrics,
                            sessions: sessions, volumes: volumes, system: system)
        }
    }

    private func applyLive(targets: [PollTarget],
                           pings results: [String: (ok: Bool, ms: Int)],
                           metrics: [String: [[String]]],
                           sessions: [String: [LiveFetcher.NowPlayingSession]],
                           volumes: [String: [LiveFetcher.VolumeFill]],
                           system: LiveFetcher.SystemBand?) {
        // Porte : dix-sept services qui tombent à la même seconde, ce ne sont pas
        // dix-sept pannes — c'est une absence de route (sortie du Wi-Fi, VPN
        // coupé, box à terre). Impossible de la distinguer d'un homelab
        // entièrement éteint, donc on ne tranche pas : ni compteur d'échec, ni
        // panne persistée, ni notification par service. Un seul état, signalé
        // une fois. Avec un seul service configuré la question ne se pose pas,
        // c'est bien lui qui est tombé.
        let failed = results.values.filter { !$0.ok }.count
        if results.count > 1 && failed == results.count {
            unreachableCycles += 1
            // Même seuil que pour un service isolé, pour rester cohérent.
            if unreachableCycles == 3 {
                unreachableSince = Date()
                if rules["down"] == true {
                    pushNotif(title: String(localized: "Homelab injoignable"),
                              sub: String(localized: "Aucun service ne répond — vérifie le réseau ou le VPN."))
                }
            }
            polling = false
            // Pas de `lastTick` ici : rien n'a été observé, et c'est lui qui
            // bornera une panne réelle restée ouverte avant la coupure.
            publishSharedState()
            return
        }
        if unreachableSince != nil && rules["down"] == true {
            pushNotif(title: String(localized: "Homelab de nouveau joignable"),
                      sub: String(localized: "Tes services répondent à nouveau."),
                      critical: false)
        }
        unreachableCycles = 0
        unreachableSince = nil

        for target in targets {
            guard let result = results[target.id] else { continue }
            if result.ok {
                pings[target.id] = result.ms
                latHistory[target.id]?.append(Double(result.ms))
                failCounts[target.id] = 0
                measured.insert(target.id)
                if downIDs.remove(target.id) != nil {
                    closeOutageRecord(target.id)
                    // Retour à la ligne seulement si le départ a été signalé :
                    // sinon on annonce la fin d'une panne dont personne n'a
                    // entendu parler.
                    if downNotified.remove(target.id) != nil && rules["down"] == true {
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
                    // Un seul enregistrement ouvert par service, sinon les pannes
                    // s'empilent à chaque redescente sans que rien ne les referme.
                    if !(config.outages ?? []).contains(where: { $0.serviceID == target.id && $0.end == nil }) {
                        config.outages = (config.outages ?? []) + [StoredOutage(serviceID: target.id, start: Date())]
                    }
                    persist()
                    if downAt == nil { downAt = Date() }
                    // Pas de notification ici : la règle promet « > 5 min », et
                    // trois échecs ne font qu'une quinzaine de secondes. L'alerte
                    // part plus bas, quand la panne a duré.
                    startOutageActivity(serviceName: target.name)
                    #if os(watchOS)
                    WKInterfaceDevice.current().play(.failure)
                    #endif
                }
            }
            trimHistories(target.id)
        }
        checkDownAlerts()
        for (id, m) in metrics { liveMetricsCache[id] = m }
        for (id, v) in volumes { volumeFills[id] = v }
        if !metrics.isEmpty { checkDiskAlerts() }
        for (id, np) in sessions where serviceTypes[id] == .jellyfin { nowPlaying[id] = np }
        if let system {
            systemLive = true
            cpu = system.cpu
            temp = system.temp
            ram = system.ramFreeGB
            checkTempAlert()
        }
        polling = false
        // Trace de la dernière observation, écrite une fois par minute : c'est
        // elle qui bornera les pannes ouvertes si l'app est quittée.
        config.lastTick = Date()
        if t % max(1, 60_000 / refreshMs) == 0 { persist() }
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

    func ping(_ s: Service) -> Int { pings[s.id] ?? 0 }

    /// Latence pas encore mesurée (mode live, avant la première réponse).
    func isPending(_ s: Service) -> Bool {
        dataMode == .live && !measured.contains(s.id)
    }
    private func pending(_ s: Service) -> Bool { isPending(s) }

    /// Latence élevée (≥ 100 ms) — accent-2.
    func isSlow(_ s: Service) -> Bool {
        !isDown(s) && (isPending(s) || ping(s) >= 100)
    }

    /// Température en préavis (≥ 48 °C, avant l'alerte à 50).
    var tempWarning: Bool {
        (dataMode == .demo || systemLive) && temp >= 48
    }

    /// Réglage : afficher le bandeau système.
    var showSystemBand: Bool = UserDefaults.standard.object(forKey: "showSystemBand") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showSystemBand, forKey: "showSystemBand") }
    }

    #if os(macOS)
    /// Démarrage à l'ouverture de session. Pas de persistance locale : l'état
    /// vient de SMAppService, que l'utilisateur peut aussi changer côté système.
    var startsAtLogin: Bool = LoginItem.isEnabled

    func setStartsAtLogin(_ on: Bool) {
        startsAtLogin = LoginItem.set(on)
        if !startsAtLogin && on {
            fireToast(String(localized: "Ouverture automatique refusée — autorise Specula dans Réglages Système > Général > Ouverture."))
        }
    }

    /// Vivre dans la seule barre de menus : pas d'icône au Dock, la fermeture
    /// de la fenêtre ne coupe pas le relevé.
    var menuBarOnly: Bool = UserDefaults.standard.bool(forKey: "menuBarOnly") {
        didSet {
            UserDefaults.standard.set(menuBarOnly, forKey: "menuBarOnly")
            LoginItem.applyDockVisibility(hidden: menuBarOnly)
        }
    }
    #endif

    /// Le bandeau n'apparaît que s'il a quelque chose à dire :
    /// démo toujours, Homelab seulement avec une source Glances.
    var systemBandVisible: Bool {
        guard showSystemBand else { return false }
        if dataMode == .demo { return true }
        return systemLive || mainServices.contains { type(of: $0) == .glances }
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

    /// URL affichée. Une seule adresse par service : ce qui rend un homelab
    /// joignable de l'extérieur (tailnet, reverse proxy, tunnel) se règle sous
    /// l'app, pas dedans.
    func url(_ s: Service) -> String { s.url }

    /// URL requêtable (schéma inclus).
    func fullURL(_ s: Service) -> String {
        YamlConfig.fullURL(url(s))
    }

    func iconURL(_ s: Service) -> URL? {
        guard logosOn, let slug = s.iconSlug else { return nil }
        return URL(string: Catalog.cdn + slug + ".png")
    }

    /// Carte muette faute d'identifiants : l'intégration en réclame (keyHint)
    /// et aucune clé n'est enregistrée — cas typique des `{{HOMEPAGE_VAR_…}}`
    /// d'un services.yaml importé, que l'app ne peut pas résoudre.
    func needsAPIKey(_ s: Service) -> Bool {
        dataMode == .live
            && LiveFetcher.keyHint(for: type(of: s)) != nil
            && apiKey(for: s.id) == nil
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
        let history: [Double]?
        let floor: Double
        switch metric {
        case .lat: (history, floor) = (latHistory[id], 46)
        case .cpu: (history, floor) = (cpuHistory[id], 85)
        case .net: (history, floor) = (netHistory[id], 3.2)
        }
        guard let history, !history.isEmpty else { return [] }
        // Échelle adaptative : un service à 100 ms saturait le graphe sur l'échelle
        // fixe du prototype. Le plancher évite l'inverse — amplifier le bruit d'un
        // service stable jusqu'à lui faire des montagnes.
        let scale = max(history.max() ?? floor, floor)
        return history.map { $0 / scale }
    }

    func bigValue(_ s: Service, metric: DetailMetric) -> String {
        switch metric {
        case .lat: isDown(s) || pending(s) ? "—" : "\(ping(s)) MS"
        case .cpu: "\(Int((cpuHistory[s.id]?.last ?? 0).rounded())) %"
        case .net: "\(fr(netHistory[s.id]?.last ?? 0)) Mo/s"
        }
    }

    /// Pause/reprise d'une lecture Jellyfin (bascule optimiste, POST ensuite).
    func togglePause(_ s: Service, session: LiveFetcher.NowPlayingSession) {
        guard let key = apiKey(for: s.id) else { return }
        let willPause = !session.paused
        if var list = nowPlaying[s.id],
           let i = list.firstIndex(where: { $0.id == session.id }) {
            let current = list[i]
            list[i] = LiveFetcher.NowPlayingSession(
                id: current.id, title: current.title, user: current.user,
                paused: willPause, position: current.position, duration: current.duration)
            nowPlaying[s.id] = list
        }
        let base = s.apiURL ?? fullURL(s)
        Task { await LiveFetcher.setPaused(willPause, base: base, key: key, sessionID: session.id) }
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
                     cause: String(localized: "Délai dépassé (timeout) — 3 tentatives échouées"),
                     minutes: minutes)
        }
    }

    func availability(_ s: Service) -> String {
        var minutes = 0.0
        for inc in incidents(for: s) {
            minutes += inc.minutes
        }
        if isDown(s) { minutes += Double(downDurationMin) }
        guard minutes > 0 else { return "100 %" }
        // Une minute de panne sur 43 200 s'arrondit à 100,00 % : un service dont
        // la rangée porte une barre rouge ne doit jamais s'afficher sans faute.
        let pct = min(99.99, 100 - minutes / (30 * 24 * 60) * 100)
        return fr((pct * 100).rounded() / 100, 2) + " %"
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

    /// Définit la clé API d'un service existant (onboarding, édition).
    func setKey(_ key: String, for id: String) {
        setApiKey(key, for: id)
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
        downNotified.remove(s.id)
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
            switchToLive()
            gOrder = Array(result.groups.indices)
            gHidden = []
            downIDs = []
            downNotified = []
            failCounts = [:]
            liveMetricsCache = [:]
            persist()
            // Clés restées en {{HOMEPAGE_VAR_…}} : Homepage les lit dans son
            // .env, pas nous. Sans ce message la carte reste muette sans raison.
            let pending = result.services
                .filter { result.unresolved[$0.id] != nil && keys[$0.id] == nil }
                .map(\.name)
            if pending.isEmpty {
                fireToast(String(localized: "Import de services.yaml — \(result.services.count) services et \(result.groups.count) groupes reconnus"))
            } else {
                fireToast(String(localized: "Import de services.yaml — \(result.services.count) services, \(pending.count) en attente de clé API : \(pending.joined(separator: ", "))"))
            }
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
            fireToast(String(localized: "services.yaml copié dans le presse-papiers"))
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
        persistNotifs()
    }

    /// Passage en mode Homelab. L'historique accumulé en démo décrit un serveur
    /// qui n'existe pas (panne Komga scénarisée, température du random-walk) :
    /// on repart à zéro plutôt que de le mêler aux vrais événements.
    func switchToLive() {
        guard dataMode != .live else { return }
        dataMode = .live
        notifs = []
        unread = 0
        diskAlerted = []
        persistNotifs()
    }

    /// Interrupteur de la section Alertes (les règles survivent au relancement).
    func setRule(_ id: String, _ on: Bool) {
        rules[id] = on
        config.alertRules = rules
        persist()
    }

    private func pushNotif(title: String, sub: String, critical: Bool = true) {
        notifs.insert(NotifItem(title: title, sub: sub, date: Date(), alert: critical, unread: true), at: 0)
        if notifs.count > notifLimit { notifs.removeLast(notifs.count - notifLimit) }
        unread += 1
        persistNotifs()
        SystemNotifier.shared.post(title: title, body: sub, critical: critical)
    }

    private func persistNotifs() {
        config.notifs = notifs.map(StoredNotif.init)
        persist()
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
