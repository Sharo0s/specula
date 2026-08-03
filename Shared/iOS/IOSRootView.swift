#if os(iOS)
import SwiftUI

enum IOSRoute: Hashable {
    case detail(Service)
    case notifs
    case add
    case settings
}

struct IOSRootView: View {
    @Environment(AppStore.self) private var store
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var path: [IOSRoute] = []
    /// Service ciblé par l'appui long (menu contextuel).
    @State private var ctxService: Service?
    /// Service en cours d'édition.
    @State private var editService: Service?

    var body: some View {
        ZStack {
            Ink.bg.ignoresSafeArea()
            if !hasOnboarded {
                // Tutoriel de premier lancement (iPhone et iPad)
                OnboardingView(done: {
                    hasOnboarded = true
                    store.finishOnboarding()
                })
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                // iPadOS : colonne latérale + grille dense, tap = interface web
                IPadRootView()
            } else {
                NavigationStack(path: $path) {
                    HomeView(path: $path, ctxService: $ctxService)
                        .navigationBarHidden(true)
                        .navigationDestination(for: IOSRoute.self) { route in
                            Group {
                                switch route {
                                case .detail(let s): ServiceDetailView(service: s)
                                case .notifs: NotificationsView()
                                case .add: AddServiceView()
                                case .settings: SettingsView(path: $path)
                                }
                            }
                            .navigationBarHidden(true)
                            .background(Ink.bg)
                        }
                }
            }

            // Feuille contextuelle (appui long 480 ms)
            if let s = ctxService {
                ContextSheet(service: s, path: $path, edit: { editService = $0 },
                             dismiss: { ctxService = nil })
            }

            ToastOverlay()
        }
        .sheet(item: $editService) { s in EditServiceSheet(service: s).environment(store) }
        .tint(Ink.accent)
    }
}

// MARK: - Feuille contextuelle

private struct ContextSheet: View {
    @Environment(AppStore.self) private var store
    let service: Service
    @Binding var path: [IOSRoute]
    let edit: (Service) -> Void
    let dismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    ServiceTile(service: service, size: 30, down: store.isDown(service))
                    Text(service.name)
                        .font(.archivo(14.5, .heavy))
                    Spacer()
                }
                .padding(14)

                HRule(weight: 2)
                row("Ouvrir l'interface web") { store.openWeb(service) }
                HRule()
                row("Voir les détails") { path.append(.detail(service)) }
                HRule()
                row("Redémarrer le conteneur") { store.restart(service) }
                HRule()
                row("Copier l'URL") { store.copyURL(service) }
                if store.dataMode == .live {
                    HRule()
                    row("Modifier le service") { edit(service) }
                    HRule()
                    Button {
                        dismiss()
                        store.removeService(service)
                    } label: {
                        Text("Supprimer le service")
                            .font(.archivo(13.5, .heavy))
                            .foregroundStyle(Ink.accentText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                HRule(weight: 2)
                Button {
                    dismiss()
                } label: {
                    Text("Annuler")
                        .font(.archivo(13.5, .heavy))
                        .foregroundStyle(Ink.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .background(Ink.bg)
            .padding(.bottom, 8)
        }
    }

    private func row(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            dismiss()
            action()
        } label: {
            Text(LocalizedStringKey(title))
                .font(.archivo(13.5, .semibold))
                .foregroundStyle(Ink.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
#endif
