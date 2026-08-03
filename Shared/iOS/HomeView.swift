#if os(iOS)
import SwiftUI

// MARK: - Accueil iPhone

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Binding var path: [IOSRoute]
    @Binding var ctxService: Service?

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 0) {
                    if store.systemBandVisible {
                        systemBand
                    }
                    HStack {
                        Spacer()
                        MSeg(options: [(LayoutMode.liste, "Liste"), (LayoutMode.grille, "Grille")],
                             selection: $store.iosLayout)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                    if store.mainServices.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Aucun service configuré")
                                .font(.archivo(19, .heavy))
                            Text("Mode Homelab : Specula n'interroge que tes services. Importe ton services.yaml ou scanne le réseau depuis les réglages.")
                                .font(.archivo(12))
                                .foregroundStyle(Ink.muted)
                            MPrimaryButton(title: "Importer ou scanner…") { path.append(.settings) }
                                .padding(.top, 6)
                        }
                        .padding(18)
                        .padding(.top, 24)
                    }
                    ForEach(store.homeGroups(), id: \.index) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            GroupHeader(name: group.name, count: group.services.count)
                                .padding(.horizontal, 18)
                                .padding(.top, 14)
                            if store.iosLayout == .grille {
                                grid(group.services)
                            } else {
                                list(group.services)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            BrandSquare()
            Text("Specula")
                .font(.archivo(20, .heavy))
            if store.dataMode == .demo {
                Text("DÉMO")
                    .font(.archivo(9, .heavy))
                    .tracking(0.45)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Ink.accent2Bg)
                    .foregroundStyle(Ink.accent2Text)
            }
            if store.net == .tailscale {
                Text("VIA TAILSCALE")
                    .font(.archivo(9, .heavy))
                    .tracking(0.45)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .overlay(Rectangle().strokeBorder(Ink.accent2, lineWidth: 1))
                    .foregroundStyle(Ink.accent2Text)
            }
            if store.guestPreview {
                Text("INVITÉ")
                    .font(.archivo(9, .heavy))
                    .tracking(0.45)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Ink.accent)
                    .foregroundStyle(.white)
            }
            Spacer()
            if store.guestPreview {
                Button {
                    store.guestPreview = false
                } label: {
                    Text("Quitter")
                        .font(.archivo(12, .heavy))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Ink.text)
            } else {
                iconButton {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 16, weight: .medium))
                        if store.unread > 0 {
                            Text("\(store.unread)")
                                .font(.archivo(8, .heavy)).monospacedDigit()
                                .foregroundStyle(.white)
                                .frame(width: 13, height: 13)
                                .background(Ink.accent)
                                .offset(x: 7, y: -6)
                        }
                    }
                } action: { path.append(.notifs) }
                iconButton {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .medium))
                } action: { path.append(.settings) }
                iconButton {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                } action: { path.append(.add) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func iconButton(@ViewBuilder _ label: () -> some View, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label()
                .frame(width: 38, height: 38)
                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Ink.text)
    }

    // MARK: Bandeau système — 4 cellules

    private var systemBand: some View {
        VStack(spacing: 0) {
            HRule(weight: 2)
            HStack(spacing: 0) {
                cell(store.cpuText, "CPU")
                VRule()
                cell(store.tempText, "Temp.", warn: store.tempWarning)
                VRule()
                cell(store.ramText, "Libre")
                VRule()
                cell(store.guestPreview
                     ? "\(store.homeGroups().flatMap(\.services).count)"
                     : "\(store.onlineCount)/\(store.totalCount)",
                     "En ligne",
                     accent: store.anyDown && !store.guestPreview)
            }
            HRule(weight: 2)
        }
        .padding(.top, 8)
    }

    private func cell(_ value: String, _ label: String, accent: Bool = false, warn: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.archivo(17, .heavy))
                .monospacedDigit()
                .foregroundStyle(accent ? Ink.accentText : (warn ? Ink.accent2Text : Ink.text))
            Text(LocalizedStringKey(label))
                .upperLabel(8.5)
                .foregroundStyle(Ink.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.leading, 14)
    }

    // MARK: Liste

    private func list(_ services: [Service]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(services.enumerated()), id: \.element.id) { i, s in
                if i > 0 { HRule().padding(.leading, 18) }
                ServiceRow(service: s)
                    .tapOrDoubleTap(tap: { path.append(.detail(s)) },
                                    open: { store.openWeb(s) })
                    .onLongPressGesture(minimumDuration: 0.48) { ctxService = s }
            }
        }
    }

    // MARK: Grille — tuiles 56 px, 4 colonnes

    private func grid(_ services: [Service]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .topLeading), count: 4),
                  alignment: .leading, spacing: 14) {
            ForEach(services) { s in
                VStack(alignment: .leading, spacing: 4) {
                    ServiceTile(service: s, size: 56, down: store.isDown(s))
                    Text(s.name)
                        .font(.archivo(10, .heavy))
                        .foregroundStyle(store.isDown(s) ? Ink.accentText : Ink.text)
                        .lineLimit(1)
                    Text(store.pingShort(s))
                        .font(.archivo(8.5)).monospacedDigit()
                        .foregroundStyle(store.isDown(s) ? Ink.accentText : Ink.muted)
                }
                .contentShape(.rect)
                .tapOrDoubleTap(tap: { path.append(.detail(s)) },
                                open: { store.openWeb(s) })
                .onLongPressGesture(minimumDuration: 0.48) { ctxService = s }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }
}

// MARK: - Rangée de service

struct ServiceRow: View {
    @Environment(AppStore.self) private var store
    let service: Service

    var body: some View {
        HStack(spacing: 12) {
            ServiceTile(service: service, size: 38, down: store.isDown(service))
            VStack(alignment: .leading, spacing: 1) {
                Text(service.name)
                    .font(.archivo(14.5, .heavy))
                    .foregroundStyle(store.isDown(service) ? Ink.accentText : Ink.text)
                Text(LocalizedStringKey(service.desc))
                    .font(.archivo(11))
                    .foregroundStyle(Ink.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            LatencyTag(text: store.pingText(service), down: store.isDown(service),
                       slow: store.isSlow(service))
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Ink.muted)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .contentShape(.rect)
    }
}
#endif
