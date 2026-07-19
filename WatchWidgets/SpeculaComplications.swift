import WidgetKit
import SwiftUI

// MARK: - Complications watchOS : « 16/17 » + carré rouge si panne
// Alimentées par l'état réel de l'app Watch (App Group). Repli : scénario
// de démonstration (nominal → panne à +1 min → retour).

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let online: Int
    let total: Int
    let downName: String?

    var down: Bool { downName != nil }
    var countText: String { "\(online)/\(total)" }

    static func from(_ s: SharedState, date: Date = .now) -> ComplicationEntry {
        ComplicationEntry(date: date, online: s.online, total: s.total,
                          downName: s.downNames.first)
    }

    static func demo(date: Date = .now, down: Bool) -> ComplicationEntry {
        ComplicationEntry(date: date, online: down ? 16 : 17, total: 17,
                          downName: down ? "Komga" : nil)
    }
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry { .demo(down: false) }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(SharedState.load().map { .from($0) } ?? .demo(down: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let now = Date()
        if let shared = SharedState.load() {
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

@main
struct SpeculaComplicationBundle: WidgetBundle {
    var body: some Widget {
        SpeculaComplication()
    }
}

struct SpeculaComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpeculaComplication", provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Specula")
        .description("Services en ligne — carré rouge en cas de panne.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCorner:
            Text(entry.countText)
                .font(.archivo(12, .heavy))
                .monospacedDigit()
                .foregroundStyle(entry.down ? Color(hex: "ff9783") : .primary)
                .widgetLabel(entry.downName.map { String(localized: "\($0) en panne") } ?? String(localized: "Tous en ligne"))
        case .accessoryInline:
            Text(entry.downName.map { String(localized: "Specula — \($0) ✕") } ?? "Specula — \(entry.countText)")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(entry.down ? Color(hex: "ec3013") : .primary)
                        .frame(width: 8, height: 8)
                    Text("SPECULA")
                        .font(.archivo(10, .heavy))
                        .tracking(0.8)
                }
                Text(String(localized: "\(entry.countText) en ligne"))
                    .font(.archivo(12, .heavy))
                    .monospacedDigit()
                if let name = entry.downName {
                    Text(String(localized: "\(name) hors ligne"))
                        .font(.archivo(10))
                        .foregroundStyle(Color(hex: "ff9783"))
                }
            }
        default:
            // Circulaire — la complication du cadran
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    if entry.down {
                        Rectangle().fill(Color(hex: "ec3013")).frame(width: 6, height: 6)
                    }
                    Text(entry.countText)
                        .font(.archivo(13, .heavy))
                        .monospacedDigit()
                }
            }
        }
    }
}
