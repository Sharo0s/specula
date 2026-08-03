#if os(macOS)
import AppKit
import ServiceManagement

// MARK: - Démarrage à l'ouverture de session et vie en arrière-plan
// L'enregistrement passe par SMAppService : pas de helper à embarquer, et
// l'utilisateur garde la main dans Réglages Système > Général > Ouverture.

enum LoginItem {

    /// Le système est la source de vérité — l'utilisateur peut désactiver
    /// l'élément depuis les Réglages Système sans passer par l'app.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Renvoie l'état réellement obtenu, pas l'intention : si l'enregistrement
    /// échoue (refus, sandbox), l'interrupteur doit revenir tout seul.
    @discardableResult
    static func set(_ on: Bool) -> Bool {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            return isEnabled
        }
        return isEnabled
    }

    /// Vrai quand launchd vient d'ouvrir l'app pour l'ouverture de session :
    /// l'Apple Event d'ouverture porte alors `keyAELaunchedAsLogInItem`.
    /// Sert à démarrer sans fenêtre plutôt qu'en s'imposant à l'écran.
    static var launchedAtLogin: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication else { return false }
        return event.paramDescriptor(forKeyword: keyAEPropData)?
            .enumCodeValue == keyAELaunchedAsLogInItem
    }

    /// Icône du Dock masquée (`.accessory`) : Specula ne vit plus que dans la
    /// barre de menus. `.regular` la fait revenir et réactive l'app.
    static func applyDockVisibility(hidden: Bool) {
        let policy: NSApplication.ActivationPolicy = hidden ? .accessory : .regular
        guard NSApp.activationPolicy() != policy else { return }
        NSApp.setActivationPolicy(policy)
        if !hidden { NSApp.activate(ignoringOtherApps: true) }
    }

    /// Ferme la fenêtre principale sans quitter (le MenuBarExtra maintient
    /// l'app en vie et le relevé continue).
    static func closeMainWindow() {
        NSApp.windows.first { $0.isVisible && $0.canBecomeMain }?.close()
    }
}
#endif
