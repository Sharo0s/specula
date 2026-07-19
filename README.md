# Specula

Dashboard homelab natif pour iOS, iPadOS, macOS et watchOS — le principe de
[gethomepage.dev](https://gethomepage.dev) porté en SwiftUI. *Specula* : la tour
de guet, en latin.

Surveille tes services selfhosted (Jellyfin, \*arr, AdGuard, Proxmox, Immich,
Transmission…) : latences en direct, métriques par intégration, détection de
panne (3 échecs → hors ligne + notification + Live Activity), widgets et
complications alimentés par l'état réel.

## Construire

```bash
brew install xcodegen
xcodegen generate
open Specula.xcodeproj
```

Targets : `Specula-iOS` (18+), `Specula-macOS` (15+), `Specula-Watch` (11+,
autonome), plus les extensions widgets iOS et complications watchOS.
`project.yml` est la source de vérité — relancer `xcodegen generate` après
tout ajout de fichier.

## Architecture

- `Shared/` — design system Modernist (`Theme`, `Components`), modèles,
  `AppStore` (@Observable, scheduler démo/live), vues par plateforme
  (`iOS/`, `macOS/`, racine partagée).
- `Shared/Data/` — couche réelle : HTTP (latence mesurée, TLS auto-signé),
  intégrations (détection automatique + métriques par API), YAML gethomepage
  aller-retour (Yams), Keychain, découverte Bonjour, NWPathMonitor/Tailscale.
- `Widgets/`, `WatchWidgets/`, `Watch/` — extensions et app Watch, nourries
  par `SharedState` via l'App Group `group.ovh.smalard.specula`.

## Modes de données

- **Démo** — le simulateur du prototype de design (random-walk, panne
  scénarisée) : toutes les surfaces fonctionnent sans homelab.
- **Homelab** — vraies requêtes vers tes services : importe ton
  `services.yaml` (format gethomepage.dev), scanne le réseau en Bonjour, ou
  ajoute tes URLs à la main. Réglages → Configuration → Données.

Design : système « Modernist » — flat, architectural, radius 0, filets
structurels, un seul accent rouge (`#ec3013`), typographie Archivo.
