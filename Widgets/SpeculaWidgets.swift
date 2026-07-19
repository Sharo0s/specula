import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widgets iOS
// Alimentés par l'état réel de l'app via l'App Group (SharedState).
// Si l'app n'a pas tourné depuis 30 min : scénario de démonstration
// (nominal → panne à +1 min → rétablissement).

struct SpeculaEntry: TimelineEntry {
    let date: Date
    let cpuText: String
    let tempText: String
    /// 0…1 pour la barre de progression ; nil = pas de source système.
    let cpuFraction: Double?
    let online: Int
    let total: Int
    let downName: String?
    let rows: [SharedPinned]

    var down: Bool { downName != nil }

    var footer: String {
        down ? "\(online)/\(total) EN LIGNE · \(total - online) PANNE"
             : "\(total)/\(total) SERVICES EN LIGNE"
    }

    // Instantané réel (App Group)
    static func from(_ s: SharedState, date: Date = .now) -> SpeculaEntry {
        SpeculaEntry(date: date,
                  cpuText: s.cpu.map { "\(Int($0)) %" } ?? "—",
                  tempText: s.temp.map { fr($0) + " °C" } ?? "—",
                  cpuFraction: s.cpu.map { $0 / 100 },
                  online: s.online,
                  total: s.total,
                  downName: s.downNames.first,
                  rows: s.pinned)
    }

    // Scénario de démonstration
    static func demo(date: Date = .now, down: Bool) -> SpeculaEntry {
        let cpu = Int.random(in: 6...28)
        let pins = Catalog.defaultPins.compactMap { id in Catalog.services.first { $0.id == id } }
        var rows = pins.prefix(3).map {
            SharedPinned(mono: $0.mono, name: shortName($0.name),
                         ping: "\(Int.random(in: 6...40)) MS", down: false)
        }
        if down {
            rows.append(SharedPinned(mono: "Ko", name: "Komga", ping: "PANNE", down: true))
        } else if let last = pins.dropFirst(3).first {
            rows.append(SharedPinned(mono: last.mono, name: shortName(last.name),
                                     ping: "\(Int.random(in: 6...40)) MS", down: false))
        }
        return SpeculaEntry(date: date,
                         cpuText: "\(cpu) %",
                         tempText: fr((Double.random(in: 42...48) * 10).rounded() / 10) + " °C",
                         cpuFraction: Double(cpu) / 100,
                         online: down ? 16 : 17,
                         total: 17,
                         downName: down ? "Komga" : nil,
                         rows: rows)
    }

    private static func shortName(_ name: String) -> String {
        switch name {
        case "Home Assistant": "Home A."
        case "UniFi Controller": "UniFi"
        default: name
        }
    }
}

struct SpeculaProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpeculaEntry { .demo(down: false) }

    func getSnapshot(in context: Context, completion: @escaping (SpeculaEntry) -> Void) {
        completion(SharedState.load().map { .from($0) } ?? .demo(down: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpeculaEntry>) -> Void) {
        let now = Date()
        if let shared = SharedState.load() {
            // État réel — l'app recharge les timelines à chaque changement
            completion(Timeline(entries: [.from(shared, date: now)],
                                policy: .after(now.addingTimeInterval(15 * 60))))
        } else {
            completion(Timeline(entries: [
                .demo(date: now, down: false),
                .demo(date: now.addingTimeInterval(60), down: true),
                .demo(date: now.addingTimeInterval(40 * 60), down: false),
            ], policy: .atEnd))
        }
    }
}

// MARK: - App Intent : redémarrage depuis le widget (interactif, iOS 17+)

struct RestartServiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Redémarrer le conteneur"
    static var isDiscoverable = false

    @Parameter(title: "Service")
    var serviceID: String

    init() {}
    init(serviceID: String) { self.serviceID = serviceID }

    func perform() async throws -> some IntentResult {
        // En prod : POST vers l'API Docker/Portainer du serveur, puis reload.
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Bundle

@main
struct SpeculaWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpeculaSystemWidget()
        SpeculaPinnedWidget()
        SpeculaLockWidget()
        SpeculaOutageActivity()
    }
}

// MARK: - Petit : CPU géant + temp., barre accent, pied x/17

struct SpeculaSystemWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpeculaSystem", provider: SpeculaProvider()) { entry in
            SystemWidgetView(entry: entry)
                .containerBackground(for: .widget) { Ink.bg }
        }
        .configurationDisplayName("Système")
        .description("CPU, température et services en ligne.")
        .supportedFamilies([.systemSmall])
    }
}

struct SystemWidgetView: View {
    let entry: SpeculaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Rectangle().fill(Ink.accent).frame(width: 10, height: 10)
                Text("SPECULA")
                    .upperLabel(8.5, .heavy)
                    .foregroundStyle(Ink.muted)
                Spacer()
            }
            Spacer()
            Text(entry.cpuText)
                .font(.archivo(34, .heavy))
                .monospacedDigit()
            Text("CPU · \(entry.tempText)")
                .font(.archivo(9.5))
                .monospacedDigit()
                .foregroundStyle(Ink.muted)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Ink.divider.opacity(0.4)
                    Ink.accent.frame(width: geo.size.width * (entry.cpuFraction ?? 0))
                }
            }
            .frame(height: 4)
            .padding(.vertical, 6)
            Text(entry.footer)
                .upperLabel(7.5, .heavy)
                .monospacedDigit()
                .foregroundStyle(entry.down ? Ink.accentText : Ink.muted)
        }
    }
}

// MARK: - Moyen : 4 épinglés + ⟳ interactif + badge panne

struct SpeculaPinnedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpeculaPinned", provider: SpeculaProvider()) { entry in
            PinnedWidgetView(entry: entry)
                .containerBackground(for: .widget) { Ink.bg }
        }
        .configurationDisplayName("Épinglés")
        .description("Tes services épinglés et leur latence.")
        .supportedFamilies([.systemMedium])
    }
}

struct PinnedWidgetView: View {
    let entry: SpeculaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Rectangle().fill(Ink.accent).frame(width: 10, height: 10)
                Text("SPECULA")
                    .upperLabel(8.5, .heavy)
                    .foregroundStyle(Ink.muted)
                Spacer()
                if entry.down {
                    Text("\(entry.total - entry.online) hors ligne")
                        .font(.archivo(8.5, .heavy))
                        .monospacedDigit()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Ink.accent)
                        .foregroundStyle(.white)
                }
            }
            ForEach(entry.rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ZStack {
                        row.down ? Ink.accent : Ink.text
                        Text(row.mono)
                            .font(.archivo(8, .heavy))
                            .foregroundStyle(Ink.bg)
                    }
                    .frame(width: 18, height: 18)
                    Text(row.name)
                        .font(.archivo(11, .heavy))
                        .foregroundStyle(row.down ? Ink.accentText : Ink.text)
                        .lineLimit(1)
                    Spacer()
                    Text(row.down ? "HORS LIGNE" : row.ping)
                        .font(.archivo(9.5, .heavy))
                        .monospacedDigit()
                        .foregroundStyle(row.down ? Ink.accentText : Ink.muted)
                    Button(intent: RestartServiceIntent(serviceID: row.name)) {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .font(.system(size: 8, weight: .bold))
                            .frame(width: 18, height: 18)
                            .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Ink.text)
                }
            }
        }
    }
}

// MARK: - Écran verrouillé : grille 2×2 des épinglés + cercle x/17

struct SpeculaLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpeculaLock", provider: SpeculaProvider()) { entry in
            LockWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("État du homelab")
        .description("Épinglés et services en ligne, sur l'écran verrouillé.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct LockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SpeculaEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    if entry.down {
                        Rectangle().fill(.red).frame(width: 6, height: 6)
                    }
                    Text("\(entry.online)/\(entry.total)")
                        .font(.archivo(13, .heavy))
                        .monospacedDigit()
                }
            }
        case .accessoryInline:
            Text(entry.downName.map { "Specula — \($0) hors ligne" }
                 ?? "Specula — \(entry.online)/\(entry.total) en ligne")
        default:
            // Rectangulaire : grille 2×2 des épinglés
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading),
                                GridItem(.flexible(), alignment: .leading)],
                      alignment: .leading, spacing: 3) {
                ForEach(entry.rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        Text(row.name)
                            .font(.archivo(9.5, .heavy))
                            .lineLimit(1)
                        Text(row.down ? "PANNE" : row.ping)
                            .font(.archivo(8.5))
                            .monospacedDigit()
                            .opacity(0.65)
                    }
                }
            }
        }
    }
}

// MARK: - Live Activity : île dynamique + bannière d'écran verrouillé

struct SpeculaOutageActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OutageActivityAttributes.self) { context in
            // Écran verrouillé — bannière encre
            HStack(spacing: 10) {
                Rectangle().fill(Color(hex: "ec3013")).frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(context.attributes.serviceName) hors ligne")
                        .font(.archivo(14, .heavy))
                    Text("\(context.state.online)/\(context.state.total) services en ligne")
                        .font(.archivo(10))
                        .monospacedDigit()
                        .opacity(0.65)
                }
                Spacer()
                Text(context.state.downSince, style: .timer)
                    .font(.archivo(16, .heavy))
                    .monospacedDigit()
                    .frame(maxWidth: 60)
            }
            .foregroundStyle(Color(hex: "f3f2f2"))
            .padding(14)
            .activityBackgroundTint(Color(hex: "201e1d"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Rectangle().fill(Color(hex: "ec3013")).frame(width: 10, height: 10)
                        Text("\(context.attributes.serviceName) hors ligne")
                            .font(.archivo(13, .heavy))
                            .foregroundStyle(Color(hex: "f3f2f2"))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.downSince, style: .timer)
                        .font(.archivo(13, .heavy))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: "ff9783"))
                        .frame(maxWidth: 52)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.online)/\(context.state.total) SERVICES EN LIGNE")
                        .upperLabel(8.5, .heavy)
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: "f3f2f2").opacity(0.65))
                }
            } compactLeading: {
                Rectangle().fill(Color(hex: "ec3013")).frame(width: 10, height: 10)
            } compactTrailing: {
                Text(context.state.downSince, style: .timer)
                    .font(.archivo(11, .heavy))
                    .monospacedDigit()
                    .foregroundStyle(Color(hex: "ff9783"))
                    .frame(maxWidth: 40)
            } minimal: {
                Rectangle().fill(Color(hex: "ec3013")).frame(width: 8, height: 8)
            }
        }
    }
}
