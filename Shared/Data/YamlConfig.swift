import Foundation
import Yams

// MARK: - services.yaml (format gethomepage.dev) — la source de vérité
// Aller-retour : import (groupes → services → widget/clés) et export compatible.
//
// - Média & Streaming:
//     - Jellyfin:
//         href: http://jellyfin.local:8096
//         description: Serveur multimédia
//         icon: jellyfin.png
//         widget:
//           type: jellyfin
//           url: http://jellyfin.local:8096
//           key: XXX

enum YamlConfig {

    struct ImportResult {
        var groups: [String] = []
        var services: [StoredService] = []
        /// id de service → clé API (à ranger dans le Keychain).
        var keys: [String: String] = [:]
    }

    // MARK: Import

    static func parse(_ text: String) throws -> ImportResult {
        // Homepage substitue {{HOMEPAGE_VAR_X}} avant de parser — sans son
        // environnement, on remplace par une chaîne vide (sinon YAML invalide).
        let cleaned = text.replacingOccurrences(
            of: #"\{\{[^}]*\}\}"#, with: "\"\"", options: .regularExpression)
        guard let root = try Yams.load(yaml: cleaned) as? [[String: Any]] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var result = ImportResult()
        var usedIDs: Set<String> = []
        for groupDict in root {
            for (groupName, rawServices) in groupDict {
                let gi = result.groups.count
                result.groups.append(groupName)
                guard let list = rawServices as? [[String: Any]] else { continue }
                for svcDict in list {
                    for (name, rawProps) in svcDict {
                        let props = rawProps as? [String: Any] ?? [:]
                        let widget = props["widget"] as? [String: Any]
                        let href = (props["href"] as? String)
                            ?? (widget?["url"] as? String) ?? ""
                        // Icône : slug dashboard-icons — pas les URLs directes
                        let slugRaw = (props["icon"] as? String).flatMap { icon -> String? in
                            icon.contains("://") ? nil : icon
                                .replacingOccurrences(of: ".png", with: "")
                                .replacingOccurrences(of: ".svg", with: "")
                        }
                        let aliases = ["jellyseerr": "overseerr", "forgejo": "gitea", "emby": "jellyfin",
                                       "changedetectionio": "changedetection", "firefly": "fireflyiii",
                                       "wireguard": "wgeasy", "nginxproxymanager": "npm"]
                        let rawType = (widget?["type"] as? String).map { aliases[$0] ?? $0 }
                        let type = rawType.flatMap(IntegrationType.init) ?? .generic
                        // id unique, même en cas de doublon de nom (2 FileBrowser…)
                        let base = "yaml-" + name.lowercased()
                            .replacingOccurrences(of: " ", with: "-") + "-\(gi)"
                        var id = base
                        var n = 2
                        while usedIDs.contains(id) { id = "\(base)-\(n)"; n += 1 }
                        usedIDs.insert(id)

                        var stored = StoredService(
                            service: Service(id: id, mono: Self.mono(name), name: name,
                                             desc: props["description"] as? String ?? "",
                                             group: gi, url: href,
                                             iconSlug: slugRaw, metrics: nil,
                                             apiURL: widget?["url"] as? String),
                            type: type)
                        if type == .generic, let slugRaw {
                            // le slug d'icône est souvent le type (jellyfin.png…)
                            stored.type = IntegrationType(rawValue: slugRaw.replacingOccurrences(of: "-", with: ""))?.rawValue ?? stored.type
                        }
                        result.services.append(stored)

                        // Clé API : widget.key, sinon header x-api-key,
                        // sinon username:password (Basic / RPC).
                        var key = (widget?["key"] as? String) ?? ""
                        if key.isEmpty, let headers = widget?["headers"] as? [String: Any] {
                            key = (headers["x-api-key"] as? String)
                                ?? (headers["X-Api-Key"] as? String) ?? ""
                        }
                        if key.isEmpty,
                           let u = widget?["username"] as? String, !u.isEmpty,
                           let p = widget?["password"] as? String, !p.isEmpty {
                            key = "\(u):\(p)"
                        }
                        if !key.isEmpty { result.keys[id] = key }
                    }
                }
            }
        }
        guard !result.services.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        return result
    }

    // MARK: Export

    static func export(groups: [String], services: [Service],
                       types: [String: IntegrationType],
                       keys: [String: String]) throws -> String {
        var root: [[String: Any]] = []
        for (gi, group) in groups.enumerated() {
            var list: [[String: Any]] = []
            for s in services where s.group == gi {
                var props: [String: Any] = ["href": fullURL(s.url)]
                if !s.desc.isEmpty { props["description"] = s.desc }
                if let slug = s.iconSlug { props["icon"] = slug + ".png" }
                let type = types[s.id] ?? .generic
                if type != .generic {
                    var widget: [String: Any] = ["type": type.rawValue,
                                                 "url": s.apiURL ?? fullURL(s.url)]
                    if let key = keys[s.id] { widget["key"] = key }
                    props["widget"] = widget
                }
                list.append([s.name: props])
            }
            root.append([group: list])
        }
        return try Yams.dump(object: root, sortKeys: false)
    }

    // MARK: Aides

    static func fullURL(_ url: String) -> String {
        url.contains("://") ? url : "http://" + url
    }

    static func mono(_ name: String) -> String {
        let base = String(name.prefix(2))
        return base.prefix(1).uppercased() + base.dropFirst().lowercased()
    }
}
