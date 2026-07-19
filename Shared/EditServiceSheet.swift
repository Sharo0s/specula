import SwiftUI

// MARK: - Modifier un service (mode Homelab) — feuille partagée iOS / macOS

struct EditServiceSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let service: Service

    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
    @State private var group = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Modifier le service")
                    .font(.archivo(17, .heavy))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Annuler")
                        .font(.archivo(12, .heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Ink.text)
            }

            field("Nom", text: $name)
            field("URL", text: $url)
            field("Clé API (vide = inchangée)", text: $apiKey)
            if let hint = LiveFetcher.keyHint(for: store.type(of: service)) {
                Text(verbatim: hint)
                    .font(.archivo(10.5))
                    .foregroundStyle(Ink.muted)
                    .padding(.top, -8)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Groupe")
                    .font(.archivo(12))
                    .foregroundStyle(Ink.text.opacity(0.7))
                MSeg(options: Array(store.mainGroups.enumerated()).map { ($0.offset, $0.element) },
                     selection: $group, fontSize: 9.5)
            }

            MPrimaryButton(title: "Enregistrer") {
                store.updateService(service.id, name: name, url: url,
                                    group: group, apiKey: apiKey)
                dismiss()
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(minWidth: 380, minHeight: 330)
        .background(Ink.bg)
        .onAppear {
            name = service.name
            url = service.url
            group = min(service.group, max(0, store.mainGroups.count - 1))
        }
    }

    private func field(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedStringKey(label))
                .font(.archivo(12))
                .foregroundStyle(Ink.text.opacity(0.7))
            TextField("", text: text)
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
                .font(.archivo(14))
                .padding(.horizontal, 10)
                .frame(height: 38)
                .background(Ink.surface)
                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
        }
    }
}
