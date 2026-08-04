# Specula — consignes projet

## Commits

**Tous les commits doivent être des Conventional Commits valides.** Le dépôt est
branché sur [release-please](https://github.com/googleapis/release-please) : le
message de commit *est* la source du changelog et du numéro de version. Un
commit mal formé est purement et simplement ignoré par l'outil.

Format de l'en-tête, strict, **sans espace avant les deux-points** :

```
type(scope): sujet en français, minuscule, à l'impératif, sans point final
```

Le corps et le pied de page restent en français avec la typographie normale
(espaces insécables, tirets cadratins…) — seule la ligne d'en-tête est contrainte
par le parser.

Types utilisés :

| Type | Effet sur la version | Section du changelog |
|---|---|---|
| `feat` | minor (1.1.0) | Fonctionnalités |
| `fix` | patch (1.0.1) | Corrections |
| `perf` | patch | Performances |
| `refactor` | patch | Refactorisations |
| `docs`, `test`, `build`, `ci`, `chore`, `style` | aucun | masqué |

Changement cassant : `!` après le scope (`feat(api)!: …`) ou un pied de page
`BREAKING CHANGE: …` → bump major.

Scopes courants : `onboarding`, `ios`, `macos`, `watch`, `widgets`, `live`,
`demo`, `notifs`, `theme`, `yaml`, `keychain`, `release`.

Exemples :

```
fix(onboarding): gèle le simulateur pendant le tutoriel
feat(macos): démarrage à l'ouverture de session
chore(release): build 16 pour l'archive macOS
```

## Versions

- `MARKETING_VERSION` dans `project.yml` est mis à jour **automatiquement** par
  release-please (annotation `# x-release-please-version`) — ne pas l'éditer à la
  main.
- `CURRENT_PROJECT_VERSION` (numéro de build) reste manuel : App Store Connect
  refuse un numéro déjà téléversé **pour la même plateforme**. iOS et macOS ont
  chacun leur espace de numérotation — le 4 août 2026, un build 19 a été
  téléversé sur les deux à trois minutes d'intervalle, sans conflit (16, 8, 7 et
  6 existent aussi des deux côtés). Une seule valeur partagée suffit donc, et
  les deux archives peuvent partir d'affilée sans bump entre elles.
- Ne jamais pousser (`git push`) ni créer de tag sans demande explicite.

## Construire

`project.yml` est la source de vérité — relancer `xcodegen generate` après tout
ajout ou suppression de fichier.

```bash
xcodebuild -project Specula.xcodeproj -scheme Specula-iOS -destination 'generic/platform=iOS Simulator' build
xcodebuild -project Specula.xcodeproj -scheme Specula-macOS build
xcodebuild -project Specula.xcodeproj -scheme Specula-Watch -destination 'generic/platform=watchOS Simulator' build
```

Vérifier les trois plateformes après une modification de `Shared/` : le code y
est partagé, mais gardé par des `#if os(...)`.
