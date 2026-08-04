# Specula

[![Licence: GPL-3.0](https://img.shields.io/badge/licence-GPL--3.0-ec3013)](LICENSE)
![Plateformes: iOS · iPadOS · macOS · watchOS](https://img.shields.io/badge/plateformes-iOS%20%C2%B7%20iPadOS%20%C2%B7%20macOS%20%C2%B7%20watchOS-111)

Dashboard homelab natif pour iOS, iPadOS, macOS et watchOS — le principe de
[gethomepage.dev](https://gethomepage.dev) porté en SwiftUI. *Specula* : la tour
de guet, en latin.

Surveille tes services selfhosted (Jellyfin, \*arr, AdGuard, Proxmox, Immich,
Transmission…) : latences en direct, métriques par intégration, détection de
panne (3 échecs → hors ligne + notification + Live Activity), widgets et
complications alimentés par l'état réel.

<!-- Captures à ajouter ici : docs/screenshots/{ios,macos,watch}.png -->

## Installation

### TestFlight

Lien public à venir.

### Compiler soi-même

Prérequis : macOS 26 et Xcode 26 — les cibles sont iOS 26, macOS 26 et
watchOS 26, aucune version antérieure n'est prise en charge. Plus
[XcodeGen](https://github.com/yonaskolb/XcodeGen) :

```bash
brew install xcodegen
cp Signing.local.xcconfig.example Signing.local.xcconfig
xcodegen generate
open Specula.xcodeproj
```

`Signing.local.xcconfig` (ignoré par git) porte deux valeurs : `DEVELOPMENT_TEAM`,
l'identifiant de ton équipe Apple Developer, et `SPECULA_BUNDLE_PREFIX`, un
préfixe reverse-DNS qui t'appartient. Les identifiants d'app et les App Groups
sont uniques à l'échelle mondiale : ceux en `com.smalard` sont déposés, il faut
les tiens. Le reste en découle — extensions, App Group, entitlements.

Targets : `Specula-iOS`, `Specula-macOS`, `Specula-Watch` (autonome), plus les
extensions widgets iOS et complications watchOS. `project.yml` est la source de
vérité — relancer `xcodegen generate` après tout ajout de fichier.

## Modes de données

- **Démo** — le simulateur du prototype de design (random-walk, panne
  scénarisée) : toutes les surfaces fonctionnent sans homelab, dès le premier
  lancement.
- **Homelab** — vraies requêtes vers tes services : importe ton
  `services.yaml` (format gethomepage.dev), scanne le réseau en Bonjour, ou
  ajoute tes URLs à la main. Réglages → Configuration → Données.

## Architecture

- `Shared/` — design system Modernist (`Theme`, `Components`), modèles,
  `AppStore` (@Observable, scheduler démo/live), vues par plateforme
  (`iOS/`, `macOS/`, racine partagée).
- `Shared/Data/` — couche réelle : HTTP (latence mesurée, TLS auto-signé),
  intégrations (détection automatique + métriques par API), YAML gethomepage
  aller-retour (Yams), Keychain, découverte Bonjour.

Une seule URL par service : ce qui rend un homelab joignable de l'extérieur
(tailnet, reverse proxy, tunnel) se règle sous l'app, pas dedans.
- `Widgets/`, `WatchWidgets/`, `Watch/` — extensions et app Watch, nourries
  par `SharedState` via l'App Group `group.<préfixe>.specula`.

Design : système « Modernist » — flat, architectural, radius 0, filets
structurels, un seul accent rouge (`#ec3013`), typographie Archivo.

## Vie privée

Aucune télémétrie, aucun compte, aucun serveur intermédiaire : l'app parle à tes
services et à rien d'autre, jetons et mots de passe restent dans le trousseau.
Seule exception, les icônes de services, chargées depuis le CDN public
[dashboard-icons](https://github.com/homarr-labs/dashboard-icons) via jsDelivr —
qui voit donc quelles icônes sont demandées, jamais tes URLs ni tes données.

## Contribuer

Voir [CONTRIBUTING.md](CONTRIBUTING.md). Les commits doivent être des
[Conventional Commits](https://www.conventionalcommits.org) valides : le dépôt
est branché sur release-please, un en-tête mal formé est ignoré par l'outil.

## Licence

[GPL-3.0](LICENSE) © Sylvain Malard. Toute redistribution, modifiée ou non, reste
sous la même licence et publie ses sources.

L'app est par ailleurs publiée sur l'App Store, dont les conditions sont
incompatibles avec la GPLv3 : les contributions demandent donc une autorisation
de distribution supplémentaire, décrite dans
[CONTRIBUTING.md](CONTRIBUTING.md#licence-et-distribution).

La police Archivo (Omnibus-Type) est distribuée sous
[SIL Open Font License 1.1](Resources/Fonts/OFL.txt), indépendamment du code.
