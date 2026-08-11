import Foundation

// MARK: - État partagé app ↔ widgets (App Group)
// L'app écrit un instantané JSON à chaque tick ; les extensions le lisent
// dans leur timeline provider. Au-delà de 30 min sans écriture, les widgets
// retombent sur le scénario de démonstration.

struct SharedPinned: Codable, Hashable {
    let mono: String
    let name: String
    let ping: String
    let down: Bool
}

struct SharedState: Codable {
    var updatedAt: Date
    var live: Bool
    var online: Int
    var total: Int
    var downNames: [String]
    /// nil = pas de source système (Glances absent en mode Homelab).
    var cpu: Double?
    var temp: Double?
    var pinned: [SharedPinned]

    /// Injecté à la compilation depuis `SPECULA_BUNDLE_PREFIX` (Signing.xcconfig)
    /// via la clé `SpeculaAppGroup` de chaque Info.plist : app, extensions et
    /// entitlements partagent ainsi un seul préfixe, celui du compte qui signe.
    static let groupID = Bundle.main.object(forInfoDictionaryKey: "SpeculaAppGroup") as? String
        ?? "group.com.smalard.specula"

    static var fileURL: URL {
        let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Specula", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("specula-state.json")
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }

    static func load(maxAge: TimeInterval = 1800) -> SharedState? {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(SharedState.self, from: data),
              Date().timeIntervalSince(state.updatedAt) < maxAge else { return nil }
        return state
    }
}
