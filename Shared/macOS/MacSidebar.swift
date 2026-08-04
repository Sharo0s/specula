#if os(macOS)
import SwiftUI

// MARK: - Sidebar 230 px (surface, filet droit 2 px)

struct MacSidebar: View {
    @Environment(AppStore.self) private var store
    @Bindable var ui: MacUIState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Marque
            HStack(spacing: 9) {
                BrandSquare()
                Text("Specula")
                    .font(.archivo(18, .heavy))
                if store.dataMode == .demo {
                    Text("DÉMO")
                        .font(.archivo(8, .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Ink.accent2Bg)
                        .foregroundStyle(Ink.accent2Text)
                }
                if store.homelabUnreachable {
                    Text("INJOIGNABLE")
                        .font(.archivo(8, .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Ink.accent)
                        .foregroundStyle(Ink.bg)
                }
                if store.net == .tailscale {
                    Text("TS")
                        .font(.archivo(8, .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(Rectangle().strokeBorder(Ink.accent2, lineWidth: 1))
                        .foregroundStyle(Ink.accent2Text)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Serveurs multi-instances (la seedbox n'existe qu'en démo)
                    sectionLabel("Serveurs")
                    ForEach(store.serverList, id: \.id) { server in
                        let active = store.serverID == server.id
                        Button {
                            store.serverID = server.id
                            ui.group = nil
                            ui.selection = nil
                            if ui.view != .notifs && ui.view != .settings { ui.view = .dash }
                        } label: {
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(active ? Ink.accent : Ink.text.opacity(0.25))
                                    .frame(width: 8, height: 8)
                                Text(LocalizedStringKey(server.name))
                                    .font(.archivo(12.5, active ? .heavy : .semibold))
                                Spacer()
                                Text("\(server.id == "seed" ? Catalog.seedServices.count : store.mainServices.count)")
                                    .font(.archivo(10)).monospacedDigit()
                                    .foregroundStyle(active ? Ink.bg.opacity(0.7) : Ink.muted)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(active ? Ink.text : .clear)
                            .foregroundStyle(active ? Ink.bg : Ink.text)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                    }

                    // Navigation
                    Spacer().frame(height: 18)
                    navItem("Tableau de bord", active: ui.view == .dash && ui.group == nil) {
                        ui.view = .dash
                        ui.group = nil
                    }
                    navItem("Statut", active: ui.view == .status) { ui.view = .status }
                    navItem("Notifications", active: ui.view == .notifs, badge: store.unread) {
                        ui.view = .notifs
                        store.markAllRead()
                    }
                    navItem("Réglages", active: ui.view == .settings) { ui.view = .settings }

                    // Groupes
                    Spacer().frame(height: 18)
                    sectionLabel("Groupes")
                    ForEach(store.visibleGroups(), id: \.index) { group in
                        navItem(group.name,
                                active: ui.view == .dash && ui.group == group.index,
                                meta: String(format: "%02d", group.services.count)) {
                            ui.view = .dash
                            ui.group = group.index
                        }
                    }
                }
                .padding(.bottom, 16)
            }

            Spacer()
            HRule(weight: 2)
            Button {
                ui.view = .add
            } label: {
                Text("+ Ajouter un service")
                    .font(.archivo(12.5, .heavy))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Ink.text)
        }
        .background(Ink.surface)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(LocalizedStringKey(text))
            .upperLabel(9, .heavy)
            .foregroundStyle(Ink.muted)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
    }

    private func navItem(_ label: String, active: Bool, meta: String? = nil, badge: Int = 0,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey(label))
                    .font(.archivo(12.5, active ? .heavy : .semibold))
                    .lineLimit(1)
                Spacer()
                if badge > 0 {
                    Text("\(badge)")
                        .font(.archivo(9.5, .heavy)).monospacedDigit()
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Ink.accent)
                }
                if let meta {
                    Text(meta)
                        .font(.archivo(10)).monospacedDigit()
                        .foregroundStyle(active ? Ink.bg.opacity(0.7) : Ink.muted)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(active ? Ink.text : .clear)
            .foregroundStyle(active ? Ink.bg : Ink.text)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}
#endif
