# Contribuer à Specula

Merci de l'intérêt. Le projet est petit et tenu par une seule personne : une
issue avant un gros patch évite de travailler pour rien.

Les échanges se font en français ou en anglais, au choix.

## Monter l'environnement

macOS 26, Xcode 26, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
cp Signing.local.xcconfig.example Signing.local.xcconfig
xcodegen generate
```

Renseigne `DEVELOPMENT_TEAM` et `SPECULA_BUNDLE_PREFIX` dans
`Signing.local.xcconfig` — le fichier est ignoré par git, et un préfixe qui
t'appartient est indispensable : identifiants d'app et App Groups sont uniques à
l'échelle mondiale.

`Specula.xcodeproj` n'est pas suivi par git : **`project.yml` est la source de
vérité**. Tout ajout, déplacement ou suppression de fichier passe par lui, suivi
d'un `xcodegen generate`.

## Repères dans le code

- `Shared/` — design system Modernist (`Theme`, `Components`), modèles, `AppStore`
  (@Observable, scheduler démo/live), vues par plateforme (`iOS/`, `macOS/`, racine
  partagée pour ce qui vaut partout).
- `Shared/Data/` — la couche réelle : HTTP (latence mesurée, tolérance TLS bornée au
  réseau local), intégrations (détection automatique et métriques par API), YAML
  gethomepage aller-retour via Yams, trousseau, découverte Bonjour.
- `Widgets/` — extensions widgets et Live Activities, nourries par `SharedState`
  à travers l'App Group.

Une seule URL par service : ce qui rend un homelab joignable de l'extérieur — VPN,
reverse proxy, tunnel — se règle sous l'app, pas dedans. C'est une décision de
conception, pas un manque.

## Vérifier avant de proposer

Le code de `Shared/` est partagé entre les deux plateformes, gardé par des
`#if os(...)` : une modification qui compile sur iOS peut casser macOS. Les
deux cibles, systématiquement.

```bash
xcodebuild -project Specula.xcodeproj -scheme Specula-iOS -destination 'generic/platform=iOS Simulator' build
xcodebuild -project Specula.xcodeproj -scheme Specula-macOS build
```

Et lancer les tests — ils portent sur du code de `Shared/`, hébergés par la
cible macOS, donc sans simulateur à démarrer :

```bash
xcodebuild test -project Specula.xcodeproj -scheme Specula-macOS -destination 'platform=macOS'
```

Ils couvrent l'aller-retour `services.yaml`, la classification des hôtes locaux
qui borne la dérogation TLS, l'encodage des clés en query string et les aides de
lecture JSON. Les fonctions qui interrogent réellement un service ne sont pas
couvertes : elles appellent `HTTPClient` directement, il faudrait injecter le
client pour les tester.

Une PR qui touche l'interface gagne à montrer une capture avant/après.

## Commits

**Tous les commits doivent être des Conventional Commits valides.** Le dépôt est
branché sur [release-please](https://github.com/googleapis/release-please) : le
message de commit *est* la source du changelog et du numéro de version. Un
commit mal formé n'est pas rejeté, il est simplement ignoré — ni entrée de
changelog, ni bump.

En-tête strict, **sans espace avant les deux-points** :

```
type(scope): sujet en français, minuscule, à l'impératif, sans point final
```

Le corps garde la typographie française normale (espaces insécables, tirets
cadratins) ; seule la ligne d'en-tête est contrainte par le parser.

| Type | Effet sur la version | Section du changelog |
|---|---|---|
| `feat` | minor | Fonctionnalités |
| `fix` | patch | Corrections |
| `perf` | patch | Performances |
| `refactor` | patch | Refactorisations |
| `docs`, `test`, `build`, `ci`, `chore`, `style` | aucun | masqué |

Changement cassant : `!` après le scope (`feat(api)!: …`) ou un pied de page
`BREAKING CHANGE: …` → bump majeur.

Scopes courants : `onboarding`, `ios`, `macos`, `widgets`, `live`,
`demo`, `notifs`, `theme`, `yaml`, `keychain`, `i18n`, `release`.

```
fix(onboarding): gèle le simulateur pendant le tutoriel
feat(macos): démarrage à l'ouverture de session
```

## Style

Suivre le code alentour plutôt qu'une règle abstraite. Deux points structurants :

- **Design system.** Couleurs, espacements et typographie viennent de `Theme` —
  pas de valeur en dur dans une vue. Le système « Modernist » est flat : radius 0,
  filets structurels, un seul accent rouge.
- **Localisation.** Aucune chaîne visible en dur dans le code : elles passent par
  le catalogue `Resources/Localizable.xcstrings`, avec le français comme langue
  source. `SWIFT_EMIT_LOC_STRINGS` fait l'extraction ; ne pas éditer les
  traductions à la main hors de l'éditeur de catalogue d'Xcode.

## Ajouter une intégration

Une intégration = détection du service + lecture de ses métriques via son API.
Le plus simple est de partir d'une intégration existante dans `Shared/Data/`, de
la copier et d'adapter l'appel. Les identifiants passent par le trousseau,
jamais par `UserDefaults` ni par le YAML exporté.

## Licence et distribution

Ta contribution est distribuée sous [GPL-3.0](LICENSE), comme le reste du
projet, et tu en gardes le droit d'auteur.

Specula est aussi publié sur l'App Store, dont les conditions sont
incompatibles avec la GPLv3. En proposant une contribution, tu accordes donc en
plus à nysia, éditeur du projet, une licence non exclusive, irrévocable,
mondiale et gratuite de l'utiliser, la modifier et la distribuer sous d'autres
conditions, y compris celles des magasins d'applications d'Apple et des
binaires signés qui en découlent.

Ce n'est pas une cession : le code reste le tien et reste libre. Sans cette
autorisation en revanche, une seule contribution extérieure suffirait à rendre
toute publication ultérieure sur l'App Store impossible — c'est exactement ce
qui est arrivé à VLC.
