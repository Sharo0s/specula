#if os(iOS)
import SwiftUI

// MARK: - Ajout de service

struct AddServiceView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
    @State private var group = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Retour")
                            .font(.archivo(13, .semibold))
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Ink.text)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Ajouter un service")
                        .font(.archivo(24, .heavy))
                        .padding(.bottom, 14)
                    HRule(weight: 2).padding(.bottom, 18)

                    field("Nom", text: $name, placeholder: "Jellyfin")
                    field("URL", text: $url, placeholder: "http://jellyfin.local:8096")
                        .padding(.top, 14)
                    field("Clé API (optionnelle — rangée dans le Keychain)", text: $apiKey, placeholder: "")
                        .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Groupe")
                            .font(.archivo(12))
                            .foregroundStyle(Ink.text.opacity(0.7))
                        MSeg(options: Array(store.mainGroups.enumerated()).map { ($0.offset, shortName($0.element)) },
                             selection: $group, fontSize: 9.5)
                    }
                    .padding(.top, 14)

                    // Aperçu
                    HStack(spacing: 12) {
                        ZStack {
                            Ink.text
                            Text(mono)
                                .font(.archivo(14, .heavy))
                                .foregroundStyle(Ink.bg)
                        }
                        .frame(width: 38, height: 38)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(name.isEmpty ? "Nouveau service" : name)
                                .font(.archivo(14.5, .heavy))
                            Text(url.isEmpty ? "http://…" : url)
                                .font(.archivo(11))
                                .foregroundStyle(Ink.muted)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Ink.surface)
                    .padding(.top, 18)

                    Text("Détection automatique du type de service à la connexion — 200+ intégrations reconnues (Jellyfin, *arr, Proxmox, AdGuard…).")
                        .font(.archivo(11))
                        .foregroundStyle(Ink.muted)
                        .padding(.top, 10)

                    VStack(spacing: 8) {
                        MPrimaryButton(title: "Ajouter le service") {
                            store.addService(name: name.isEmpty ? "Nouveau service" : name,
                                             url: url, group: group, apiKey: apiKey)
                            dismiss()
                        }
                        MSecondaryButton(title: "Tester la connexion") {
                            store.testConnection(url: url)
                        }
                    }
                    .padding(.top, 18)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
    }

    private var mono: String {
        let base = name.isEmpty ? "Ns" : String(name.prefix(2))
        return base.prefix(1).uppercased() + base.dropFirst().lowercased()
    }

    private func shortName(_ g: String) -> String {
        g.components(separatedBy: " & ").first ?? g
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedStringKey(label))
                .font(.archivo(12))
                .foregroundStyle(Ink.text.opacity(0.7))
            TextField(LocalizedStringKey(placeholder), text: text)
                .font(.archivo(14))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 10)
                .frame(height: 40)
                .background(Ink.surface)
                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
        }
    }
}
#endif
