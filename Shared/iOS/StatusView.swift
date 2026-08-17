#if os(iOS)
import SwiftUI

// MARK: - Statut : mur de disponibilité
//
// Le mur est dans `AvailabilityWall`, partagé avec le Mac. Ne reste ici que la
// barre de titre et le choix de la période d'ouverture : quatorze jours sur
// iPhone, trente sur iPad — sur 402 pt de large, trente carrés tombent à 8 pt,
// sous toute cible tactile praticable. Le sélecteur permet d'y aller quand
// même ; c'est un choix de l'utilisateur, pas un défaut par surprise.

struct StatusView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var period: WallPeriod
    @State private var incident: IncidentSelection?

    /// Sur iPad la page s'ouvre en feuille depuis l'en-tête ; sur iPhone elle
    /// est empilée dans la `NavigationStack`. Le bouton de sortie suit.
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad

    init() {
        _period = State(initialValue:
            UIDevice.current.userInterfaceIdiom == .pad ? .month : .fortnight)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                AvailabilityWall(period: $period, incident: $incident)
                    .padding(18)
                    .padding(.bottom, 30)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isPad ? "xmark" : "chevron.backward")
                        .font(.system(size: 13, weight: .semibold))
                    Text(isPad ? "Fermer" : "Retour")
                        .font(.archivo(13, .semibold))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Ink.text)
            Spacer()
            Text("Statut")
                .font(.archivo(13, .heavy))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}
#endif
