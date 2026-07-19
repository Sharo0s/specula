#if os(watchOS)
import SwiftUI
import WatchKit

// MARK: - App watchOS : épinglés + latence, panne en accent, vibration à la panne

@main
struct SpeculaWatchApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(store)
        }
    }
}

struct WatchHomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Marque + compteur
                HStack(spacing: 7) {
                    Rectangle().fill(Ink.accent).frame(width: 10, height: 10)
                    Text("Specula")
                        .font(.archivo(15, .heavy))
                    Spacer()
                    Text(verbatim: "\(store.onlineCount)/\(store.totalCount)")
                        .font(.archivo(13, .heavy))
                        .monospacedDigit()
                        .foregroundStyle(store.anyDown ? Ink.accentText : Ink.text)
                }
                .padding(.bottom, 6)
                HRule(weight: 2)

                // Bandeau de panne
                if store.anyDown {
                    HStack(spacing: 6) {
                        Text(verbatim: "✕ \(store.downName)")
                            .font(.archivo(12, .heavy))
                        Spacer()
                        Text(verbatim: "\(store.downDurationMin) min")
                            .font(.archivo(11, .heavy))
                            .monospacedDigit()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Ink.accent)
                    .padding(.top, 6)
                }

                // Épinglés
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                        if i > 0 { HRule() }
                        HStack {
                            Text(row.name)
                                .font(.archivo(12.5, row.down ? .heavy : .semibold))
                                .foregroundStyle(row.down ? Ink.accentText : Ink.text)
                                .lineLimit(1)
                            Spacer()
                            Text(row.value)
                                .font(.archivo(12, .heavy))
                                .monospacedDigit()
                                .foregroundStyle(row.down ? Ink.accentText : Ink.muted)
                        }
                        .padding(.vertical, 7)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Ink.bg)
    }

    private struct Row {
        let name: String
        let value: String
        let down: Bool
    }

    /// 3 premiers épinglés + le service en panne ✕ (sinon le 4e épinglé).
    private var rows: [Row] {
        let pins = store.pinnedServices
        var result = pins.prefix(3).map {
            Row(name: shortName($0.name), value: "\(store.ping($0))", down: false)
        }
        if let downSvc = store.downList.first {
            result.append(Row(name: shortName(downSvc.name), value: "✕", down: true))
        } else if let last = pins.dropFirst(3).first {
            result.append(Row(name: shortName(last.name), value: "\(store.ping(last))", down: false))
        }
        return result
    }

    private func shortName(_ name: String) -> String {
        switch name {
        case "Home Assistant": "Home A."
        case "UniFi Controller": "UniFi"
        default: name
        }
    }
}
#endif
