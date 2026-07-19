#if os(iOS)
import ActivityKit
import Foundation

// MARK: - Live Activity de panne
// Partagé entre l'app iOS (qui la démarre à la panne) et l'extension widgets
// (qui fournit l'île dynamique + la bannière d'écran verrouillé).

struct OutageActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var online: Int
        var total: Int
        var downSince: Date
    }

    var serviceName: String
}
#endif
