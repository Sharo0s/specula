#if os(macOS)
import SwiftUI

// MARK: - Palette ⌘K (overlay, fond assombri 42 %)

struct MacPalette: View {
    @Environment(AppStore.self) private var store
    @Bindable var ui: MacUIState
    @State private var query = ""
    @FocusState private var focused: Bool

    private var results: [Service] {
        store.services.filter {
            query.isEmpty || ($0.name + " " + $0.desc).localizedCaseInsensitiveContains(query)
        }
        .prefix(6).map { $0 }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture { ui.paletteOpen = false }

            VStack(spacing: 0) {
                // Champ de recherche
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Ink.muted)
                    TextField("Rechercher un service, une action…", text: $query)
                        .textFieldStyle(.plain)
                        .font(.archivo(14))
                        .focused($focused)
                        .onSubmit {
                            if let first = results.first { open(first) }
                        }
                    Text("ESC")
                        .font(.archivo(9, .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                        .foregroundStyle(Ink.muted)
                }
                .padding(14)
                HRule(weight: 2)

                // Résultats
                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { i, s in
                        if i > 0 { HRule() }
                        resultRow(s)
                    }
                }

                HRule(weight: 2)
                HStack(spacing: 16) {
                    shortcut("↩", "ouvrir")
                    shortcut("⟳", "redémarrer")
                    shortcut("↗", "interface web")
                    Spacer()
                    shortcut("⌘K", "fermer")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .frame(width: 520)
            .background(Ink.bg)
            .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 2))
            .padding(.top, 120)
        }
        .onAppear { focused = true }
        .onExitCommand { ui.paletteOpen = false }
    }

    private func open(_ s: Service) {
        ui.paletteOpen = false
        ui.view = .dash
        ui.selection = s.id
    }

    private func resultRow(_ s: Service) -> some View {
        let down = store.isDown(s)
        return Button {
            open(s)
        } label: {
            HStack(spacing: 10) {
                ServiceTile(service: s, size: 26, down: down)
                Text(s.name)
                    .font(.archivo(13, .heavy))
                    .foregroundStyle(down ? Ink.accentText : Ink.text)
                Text("\(down ? "HORS LIGNE" : "EN LIGNE") · \(groupName(s))")
                    .font(.archivo(10))
                    .foregroundStyle(Ink.muted)
                Spacer()
                actionButton("arrow.trianglehead.2.clockwise") {
                    ui.paletteOpen = false
                    store.restart(s)
                }
                actionButton("arrow.up.right") {
                    ui.paletteOpen = false
                    store.openWeb(s)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func groupName(_ s: Service) -> String {
        let names = store.groups(of: store.server)
        return s.group < names.count ? names[s.group] : ""
    }

    private func actionButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 24, height: 24)
                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Ink.text)
    }

    private func shortcut(_ key: String, _ label: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.archivo(9, .heavy))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
            Text(label)
                .font(.archivo(9.5))
        }
        .foregroundStyle(Ink.muted)
    }
}
#endif
