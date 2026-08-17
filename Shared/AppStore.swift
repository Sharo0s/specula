import SwiftUI
import Observation
import UniformTypeIdentifiers
#if canImport(WidgetKit)
import WidgetKit
#endif
#if os(iOS)
import UIKit
import ActivityKit
#elseif os(macOS)
import AppKit
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

/// Apparence claire ou sombre, sur le modèle de `AppLanguage`.
///
/// Trois états et non deux : « Système » doit rester atteignable, sinon un
/// choix fait une fois fige l'app pour toujours, y compris quand le Mac ou
/// l'iPhone bascule tout seul à la tombée du jour.
enum AppAppearance {
    @MainActor
    static var segments: [(String, String)] {
        [("system", String(localized: "Système")),
         ("light", String(localized: "Clair")),
         ("dark", String(localized: "Sombre"))]
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
    var guestIds: Set<String> = ["immich", "komga"]
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

    /// Apparence : "system", "light" ou "dark". Persistée comme la langue —
    /// un thème choisi à la main n'a pas à être redemandé au lancement suivant.
    var appearance: String = UserDefaults.standard.string(forKey: "appearance") ?? "system" {
        didSet {
            guard appearance != oldValue else { return }
            UserDefaults.standard.set(appearance, forKey: "appearance")
        }
    }

    /// `nil` laisse SwiftUI suivre le système. Un choix explicite s'impose dans
    /// les deux sens — c'est là que l'ancien `forceDark` échouait : il ne
    /// savait que forcer le sombre, si bien que sur un Mac déjà sombre le
    /// bouton semblait mort.
    var colorSchemeOverride: ColorScheme? {
        switch appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    /// Ce que voit réellement l'utilisateur, pour que le bouton de bascule
    /// propose l'inverse de l'écran plutôt que l'inverse d'un réglage.
    func toggleAppearance(system: ColorScheme) {
        let effective = colorSchemeOverride ?? system
        appearance = effective == .dark ? "light" : "dark"
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
    /// Relevés lents consécutifs, pendant de `failCounts` pour la lenteur.
    private var slowCounts: [String: Int] = [:]
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

    // MARK: Achats intégrés
    /// Boutique StoreKit — places de service achetées, déverrouillage illimité.
    let billing: Billing
    /// Boutique ouverte (overlay plein cadre, cf. `speculaPaywall()`).
    var paywallOpen = false

    // MARK: Navigation partagée
    var serverID = "main"
    var toast: String?

    private var timer: Timer?
    private var toastTask: Task<Void, Never>?
    /// Live Activity de panne en cours (iOS uniquement).
    private var outageActivity: Any?

    var server: Server { serverID == "seed" ? Catalog.seedServer : Catalog.mainServer }
    var services: [Service] { serverID == "seed" ? Catalog.seedServices : mainServices }

    /// Serveurs affichés dans la sidebar : le second serveur n'existe qu'en démo.
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
        billing = Billing(purchasedSlots: config.purchasedSlots ?? 0,
                          unlimited: config.unlimitedUnlocked ?? false)
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

        // Même scellement pour les lenteurs, et même purge à 30 jours.
        self.config.degradations = (config.degradations ?? []).map { deg in
            guard deg.end == nil else { return deg }
            var sealed = deg
            sealed.end = max(config.lastTick ?? deg.start, deg.start)
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

        migrateKeysToKeychain()
        // Les clés d'une version antérieure dorment dans l'ancien trousseau de
        // macOS, dont chaque lecture réclame une autorisation. Une seule passe,
        // au premier lancement, puis plus jamais.
        KeychainStore.migrateFromLegacyIfNeeded()

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

        // Droits d'achat : le décompte persisté sert d'affichage immédiat, puis
        // l'historique App Store le confirme (ou le complète, sur un appareil
        // neuf). Pas de chargement du catalogue ici — c'est une requête réseau
        // que la plupart des sessions n'auront jamais à faire.
        billing.onChange = { [weak self] slots, unlimited in
            guard let self else { return }
            self.config.purchasedSlots = slots
            self.config.unlimitedUnlocked = unlimited
            self.persist()
        }
        Task { await self.billing.refresh() }
    }

    /// Le tutoriel de premier lancement gèle le simulateur.
    private var onboardingDone: Bool {
        UserDefaults.standard.bool(forKey: "hasOnboarded")
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

    // MARK: - État partagé (widgets)

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
                // Lenteur soutenue — même règle des trois relevés que la panne,
                // pour la même raison : un pic isolé n'est pas un incident.
                if result.ms >= Self.slowMs {
                    slowCounts[target.id, default: 0] += 1
                    if slowCounts[target.id] == 3,
                       !(config.degradations ?? []).contains(where: {
                           $0.serviceID == target.id && $0.end == nil }) {
                        config.degradations = (config.degradations ?? [])
                            + [StoredDegradation(serviceID: target.id, start: Date())]
                        persist()
                    }
                } else {
                    slowCounts[target.id] = 0
                    closeDegradationRecord(target.id)
                }
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
                // Une panne prime sur une lenteur : le service ne répond plus,
                // il n'est plus « lent ».
                slowCounts[target.id] = 0
                closeDegradationRecord(target.id)
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
        case "seed-traefik":
            return [["12", "Routes"], ["9", "Certificats"], ["\(fr(rx)) Mo/s", "Trafic"]]
        case "homeassistant":
            return [["1 / 3", "Présents"], ["\(lights) / 10", "Lumières"], ["27 / 68", "Interrupteurs"]]
        case "uptimekuma":
            return [["\(onlineCount) / \(totalCount)", "En ligne"], ["99,98 %", "Dispo. 30 j"], ["3", "Alertes conf."]]
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

    /// Groupes visibles, dans l'ordre configuré (ceux du second serveur ne le sont pas).
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

    /// Seuil de lenteur, partagé par l'affichage direct (`isSlow`) et par
    /// l'enregistrement historique — les deux doivent dire la même chose.
    static let slowMs = 100

    private func closeDegradationRecord(_ id: String) {
        guard var degs = config.degradations,
              let i = degs.lastIndex(where: { $0.serviceID == id && $0.end == nil }) else { return }
        degs[i].end = Date()
        config.degradations = degs
        persist()
    }

    /// Jours marqués par une lenteur soutenue, dans le même repère que
    /// `Incident.day` — 0 = J-29, 29 = aujourd'hui.
    func degradedDays(for s: Service) -> Set<Int> {
        if dataMode == .demo {
            return Catalog.degradedDays[s.id] ?? []
        }
        var days: Set<Int> = []
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for deg in config.degradations ?? [] where deg.serviceID == s.id {
            let from = cal.startOfDay(for: deg.start)
            let to = cal.startOfDay(for: deg.end ?? Date())
            // Une lenteur qui enjambe minuit marque les deux jours.
            var cursor = from
            while cursor <= to {
                let daysAgo = cal.dateComponents([.day], from: cursor, to: today).day ?? 0
                if daysAgo < 30 { days.insert(29 - daysAgo) }
                guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }
        }
        return days
    }

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

    /// Disponibilité sur les `days` derniers jours. La fenêtre est un paramètre
    /// parce que le mur ne montre pas toujours trente jours : afficher un
    /// pourcentage calculé sur une période plus large que les carrés visibles
    /// donne un chiffre que rien à l'écran ne justifie.
    func availability(_ s: Service, days: Int = 30) -> String {
        let first = 30 - days
        var minutes = 0.0
        for inc in incidents(for: s) where inc.day >= first {
            minutes += inc.minutes
        }
        if isDown(s) { minutes += Double(downDurationMin) }
        guard minutes > 0 else { return "100 %" }
        // Une minute de panne sur 43 200 s'arrondit à 100,00 % : un service dont
        // la rangée porte une barre rouge ne doit jamais s'afficher sans faute.
        let pct = min(99.99, 100 - minutes / (Double(days) * 24 * 60) * 100)
        return fr((pct * 100).rounded() / 100, 2) + " %"
    }

    // MARK: - Clés API (trousseau uniquement)

    // Les clés vivaient en clair dans `config.json`, contournement d'une gêne de
    // développement : une resignature ad hoc change l'identité de l'app, et le
    // trousseau redemande alors l'autorisation. Sous une signature stable il ne
    // redemande rien, alors qu'un fichier en clair, lui, part dans les
    // sauvegardes et se lit sous le compte de l'utilisateur sur macOS.

    func apiKey(for id: String) -> String? {
        if let key = KeychainStore.get(id) { return key }
        // Configuration antérieure à la migration, ou migration impossible.
        return config.apiKeys?[id]
    }

    private func setApiKey(_ key: String, for id: String) {
        KeychainStore.set(key, for: id)
        config.apiKeys?[id] = nil
        if config.apiKeys?.isEmpty == true { config.apiKeys = nil }
        persist()
    }

    /// Clés des services exportés, relues une à une dans le trousseau.
    private func exportableKeys() -> [String: String] {
        var keys: [String: String] = [:]
        for s in mainServices {
            if let key = apiKey(for: s.id) { keys[s.id] = key }
        }
        return keys
    }

    /// Mêmes services, clés remplacées par des variables au format Homepage.
    /// Le fichier reste valide et transportable ; réimporté ici, il signale les
    /// services en attente de clé plutôt que d'en inventer une.
    private func placeholderKeys() -> [String: String] {
        var keys: [String: String] = [:]
        for s in mainServices where apiKey(for: s.id) != nil {
            let slug = s.id.uppercased().map { $0.isLetter || $0.isNumber ? $0 : "_" }
            keys[s.id] = "{{HOMEPAGE_VAR_\(String(slug))_KEY}}"
        }
        return keys
    }

    /// Verse dans le trousseau les clés des configurations antérieures, puis les
    /// efface du fichier. Une clé qui n'a pas pu être écrite y reste : mieux
    /// vaut un service qui fonctionne qu'une clé perdue en silence.
    func migrateKeysToKeychain() {
        guard let keys = config.apiKeys, !keys.isEmpty else { return }
        var remaining: [String: String] = [:]
        for (id, key) in keys {
            KeychainStore.set(key, for: id)
            if KeychainStore.get(id) != key { remaining[id] = key }
        }
        config.apiKeys = remaining.isEmpty ? nil : remaining
        persist()
    }

    /// Définit la clé API d'un service existant (onboarding, édition).
    func setKey(_ key: String, for id: String) {
        setApiKey(key, for: id)
    }

    // MARK: - Quota de services (achats intégrés)

    /// Services réellement configurés par l'utilisateur — importés et ajoutés à
    /// la main. Le catalogue de démo n'en fait pas partie : ses dix-sept
    /// services fictifs ne consomment aucune place, sinon la démo deviendrait
    /// un paywall déguisé. Le décompte ignore `dataMode` à dessein : ce qui est
    /// ajouté en démo réapparaît en Homelab, ce serait un contournement.
    var configuredCount: Int {
        (importedList?.count ?? 0) + customList.count
    }

    var quota: ServiceQuota {
        ServiceQuota(purchasedSlots: billing.purchasedSlots, unlimited: billing.unlimited)
    }

    /// Reste-t-il une place ?
    var canAddService: Bool {
        quota.allowsAdding(current: configuredCount)
    }

    /// Places libres — `nil` si illimité.
    var remainingSlots: Int? {
        quota.remaining(current: configuredCount)
    }

    /// Services écartés du dernier import faute de place — l'écran de
    /// confirmation du tutoriel le dit, un toast passe trop vite pour ça.
    private(set) var lastImportDropped = 0

    /// Places à proposer d'emblée dans la boutique. Celui qui vient de perdre
    /// onze services à l'import doit trouver onze au compteur, pas un — sinon
    /// il repart pour onze achats. On retranche les places déjà libres : après
    /// un achat, la suggestion retombe d'elle-même.
    var suggestedSlotCount: Int {
        let missing = lastImportDropped - (remainingSlots ?? 0)
        return max(1, min(SlotProduct.maxQuantity, missing))
    }

    /// Ouvre la boutique et charge le catalogue au passage.
    func openPaywall() {
        paywallOpen = true
        Task { await self.billing.loadProducts() }
    }

    /// Refus d'ajout faute de place : un toast qui dit pourquoi, puis la
    /// boutique. Jamais d'échec silencieux.
    private func refuseForQuota() {
        fireToast(String(localized: "Limite atteinte — \(ServiceQuota.free) services offerts, débloque les suivants."))
        openPaywall()
    }

    // MARK: - Configuration (ajout, YAML)

    /// Ajout manuel (« + ») ou depuis le scan — le type est détecté à la connexion.
    /// `false` quand le quota est plein : l'appelant garde la main sur son état
    /// (feuille de scan, formulaire) plutôt que de croire l'ajout fait.
    @discardableResult
    func addService(name: String, url: String, group: Int, apiKey: String,
                    knownType: IntegrationType? = nil) -> Bool {
        guard canAddService else {
            refuseForQuota()
            return false
        }
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
        guard knownType == nil else { return true }
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
        return true
    }

    /// Ajout depuis le scan Bonjour.
    @discardableResult
    func addScanned(_ found: BonjourScanner.Found) -> Bool {
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
        // Le service part, sa clé aussi : la laisser dans le trousseau
        // maintiendrait un identifiant valide pour un service que
        // l'utilisateur croit avoir retiré.
        KeychainStore.delete(s.id)
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
            // L'import remplace la configuration : le quota se compte donc à
            // partir de zéro. Au-delà, on tronque plutôt que de refuser le
            // fichier en bloc — un services.yaml de vingt entrées reste
            // exploitable, et l'utilisateur voit exactement ce qui manque.
            // `keptServices` et pas `services` : la propriété du même nom
            // désigne les services affichés, ce n'est pas la même liste.
            let keepCount = quota.acceptableCount(result.services.count)
            let keptServices = Array(result.services.prefix(keepCount))
            lastImportDropped = result.services.count - keptServices.count

            importedList = keptServices.map(\.service)
            customList = []
            config.importedGroups = result.groups
            config.importedServices = keptServices
            config.custom = []
            for stored in keptServices {
                serviceTypes[stored.id] = IntegrationType(rawValue: stored.type) ?? .generic
                seedHistory(stored.id)
            }
            // Pas de clé écrite pour un service laissé de côté : le trousseau
            // garderait un identifiant valide pour un service absent de l'app.
            let keptIDs = Set(keptServices.map(\.id))
            for (id, key) in result.keys where keptIDs.contains(id) {
                KeychainStore.set(key, for: id)
            }
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
            let pending = keptServices
                .filter { result.unresolved[$0.id] != nil && apiKey(for: $0.id) == nil }
                .map(\.name)
            if lastImportDropped > 0 {
                fireToast(String(localized: "Import de services.yaml — \(keptServices.count) services importés, \(lastImportDropped) laissés de côté faute de place."))
            } else if pending.isEmpty {
                fireToast(String(localized: "Import de services.yaml — \(keptServices.count) services et \(result.groups.count) groupes reconnus"))
            } else {
                fireToast(String(localized: "Import de services.yaml — \(keptServices.count) services, \(pending.count) en attente de clé API : \(pending.joined(separator: ", "))"))
            }
        } catch {
            lastImportDropped = 0
            fireToast(String(localized: "Import impossible — services.yaml illisible"))
        }
    }

    /// Contenu du services.yaml. La destination est du ressort de l'appelant :
    /// panneau d'enregistrement sur macOS, feuille d'export sur iOS. Le fichier
    /// porte les clés API en clair — c'est ce qui rend la config transportable
    /// d'un appareil à l'autre, mais ça se range comme un secret.
    func exportYAMLText(includeKeys: Bool = true) -> String? {
        do {
            return try YamlConfig.export(groups: mainGroups, services: mainServices,
                                         types: serviceTypes,
                                         keys: includeKeys ? exportableKeys() : placeholderKeys())
        } catch {
            fireToast(String(localized: "Export impossible"))
            return nil
        }
    }

    #if os(macOS)
    /// Enregistre le services.yaml là où l'utilisateur le demande, après lui
    /// avoir fait choisir si les clés API partent avec.
    func exportYAMLToFile() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Exporter services.yaml")
        alert.informativeText = String(localized: "Le fichier peut emporter tes clés API en clair. C'est ce qui rend la configuration transportable d'un appareil à l'autre, mais ça se range alors comme un secret.")
        alert.addButton(withTitle: String(localized: "Avec les clés"))
        alert.addButton(withTitle: String(localized: "Sans les clés"))
        alert.addButton(withTitle: String(localized: "Annuler"))
        let choice = alert.runModal()
        guard choice != .alertThirdButtonReturn else { return }
        guard let yaml = exportYAMLText(includeKeys: choice == .alertFirstButtonReturn) else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "services.yaml"
        panel.allowedContentTypes = [.yaml]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try yaml.write(to: url, atomically: true, encoding: .utf8)
            fireToast(String(localized: "services.yaml enregistré"))
        } catch {
            fireToast(String(localized: "Export impossible"))
        }
    }
    #endif

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
