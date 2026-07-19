#if os(macOS)
import SwiftUI

// MARK: - Popover de la barre de menus (344 px)

struct MenuBarPopover: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header : marque + CPU/temp/RAM
            HStack(spacing: 8) {
                BrandSquare(size: 12)
                Text("Specula")
                    .font(.archivo(14, .heavy))
                Spacer()
                Text(verbatim: "CPU \(store.cpuText) · \(store.tempLongText) · \(store.ramLongText)")
                    .font(.archivo(10)).monospacedDigit()
                    .foregroundStyle(Ink.muted)
            }
            .padding(12)
            HRule(weight: 2)

            // Bloc état
            if store.anyDown {
                HStack(spacing: 10) {
                    Rectangle().fill(.white).frame(width: 8, height: 8)
                    Text(String(localized: "\(store.downName) hors ligne"))
                        .font(.archivo(12.5, .heavy))
                    Spacer()
                    Text(verbatim: "\(store.downDurationMin) min")
                        .font(.archivo(11, .heavy)).monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Ink.accent)
            } else {
                HStack(spacing: 10) {
                    Rectangle().fill(Ink.text).frame(width: 8, height: 8)
                    Text("Tous les services en ligne")
                        .font(.archivo(12.5, .bold))
                    Spacer()
                    Text(verbatim: "\(store.onlineCount)/\(store.totalCount)")
                        .font(.archivo(11, .heavy)).monospacedDigit()
                        .foregroundStyle(Ink.muted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
            }
            HRule()

            // 4 épinglés avec latence
            VStack(spacing: 0) {
                ForEach(Array(store.pinnedServices.prefix(4).enumerated()), id: \.element.id) { i, s in
                    if i > 0 { HRule() }
                    HStack(spacing: 10) {
                        ServiceTile(service: s, size: 24, down: store.isDown(s))
                        Text(s.name)
                            .font(.archivo(12, .bold))
                            .foregroundStyle(store.isDown(s) ? Ink.accentText : Ink.text)
                        Spacer()
                        Text(store.pingShort(s))
                            .font(.archivo(10.5, .heavy)).monospacedDigit()
                            .foregroundStyle(store.isDown(s) ? Ink.accentText : Ink.muted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                }
            }
            HRule(weight: 2)

            // Pied
            HStack {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Text("Ouvrir Specula")
                        .font(.archivo(11.5, .heavy))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Text("Réglages…")
                        .font(.archivo(11.5))
                        .foregroundStyle(Ink.muted)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
        .frame(width: 344)
        .background(Ink.bg)
    }
}

// MARK: - Mode TV / kiosque (fenêtre dédiée, toujours sombre)

struct MacTVView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            // Header : marque, x/17, CPU, horloge géante
            HStack(spacing: 16) {
                BrandSquare(size: 18)
                Text("Specula")
                    .font(.archivo(24, .heavy))
                Text(String(localized: "\(store.onlineCount)/\(store.totalCount) en ligne · CPU \(store.cpuText)"))
                    .font(.archivo(13)).monospacedDigit()
                    .opacity(0.75)
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(context.date, format: .dateTime.hour().minute())
                        .font(.archivo(44, .heavy)).monospacedDigit()
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)

            // Bandeau rouge de panne
            if store.anyDown {
                HStack(spacing: 12) {
                    Rectangle().fill(.white).frame(width: 10, height: 10)
                    Text(String(localized: "\(store.downName) HORS LIGNE"))
                        .upperLabel(15, .heavy)
                    Spacer()
                    Text(verbatim: "\(store.downDurationMin) min")
                        .font(.archivo(15, .heavy)).monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Ink.accent)
            }
            HRule(weight: 2)

            // Grille 4×2 de tuiles géantes
            GeometryReader { geo in
                let cols = 4
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: cols), spacing: 2) {
                    ForEach(Catalog.services.prefix(8)) { s in
                        tvTile(s)
                            .frame(height: (geo.size.height - 2) / 2)
                    }
                }
            }
            .padding(2)
        }
        .background(Ink.bg)
        .preferredColorScheme(.dark)
        .frame(minWidth: 960, minHeight: 540)
    }

    private func tvTile(_ s: Service) -> some View {
        let down = store.isDown(s)
        let m = store.metrics(s).first
        return VStack(alignment: .leading, spacing: 8) {
            ServiceTile(service: s, size: 36, down: down)
            Spacer()
            Text(s.name)
                .font(.archivo(17, .heavy))
                .foregroundStyle(down ? .white : Ink.text)
            if let m {
                Text(verbatim: "\(m[0]) ") + Text(LocalizedStringKey(m[1]))
                    .font(.archivo(11)).monospacedDigit()
                    .foregroundStyle(down ? .white.opacity(0.8) : Ink.muted)
            }
            Text(down ? String(localized: "HORS LIGNE") : "\(store.ping(s)) MS")
                .font(.archivo(19, .heavy)).monospacedDigit()
                .foregroundStyle(down ? .white : Ink.text)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(down ? Ink.accent : Ink.surface)
    }
}
#endif
