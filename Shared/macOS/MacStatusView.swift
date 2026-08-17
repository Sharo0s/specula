#if os(macOS)
import SwiftUI

// MARK: - Statut : mur de disponibilité 30 j
//
// Le mur lui-même vit dans `AvailabilityWall`, partagé avec l'iPhone et l'iPad.
// Il ne reste ici que la mise en page de la fenêtre.

struct MacStatusView: View {
    @State private var period: WallPeriod = .month
    @State private var incident: IncidentSelection?

    var body: some View {
        ScrollView {
            AvailabilityWall(period: $period, incident: $incident)
                .padding(20)
                .padding(.bottom, 30)
        }
    }
}
#endif
