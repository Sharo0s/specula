<p align="center">
  <img src="docs/icon.png" width="110" alt="Icône de Specula">
</p>

<h1 align="center">Specula</h1>

<p align="center">
  <a href="https://github.com/Sharo0s/specula/actions/workflows/ci.yml"><img src="https://github.com/Sharo0s/specula/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/iOS-26%2B-111" alt="iOS 26+">
  <img src="https://img.shields.io/badge/macOS-26%2B-111" alt="macOS 26+">
  <img src="https://img.shields.io/badge/watchOS-26%2B-111" alt="watchOS 26+">
  <a href="LICENSE"><img src="https://img.shields.io/badge/licence-GPL--3.0-ec3013" alt="Licence : GPL-3.0"></a>
  <a href="README.md"><img src="https://img.shields.io/badge/read%20in-english-111" alt="Read in English"></a>
</p>

<p align="center">
  <b>Specula</b> est un tableau de bord homelab natif pour iPhone, iPad, Mac et Apple Watch —
  le principe de <a href="https://gethomepage.dev">gethomepage.dev</a>, porté en SwiftUI.<br>
  Il lit les <b>vraies métriques</b> de tes services auto-hébergés, repère les pannes,
  et alimente widgets et complications avec l'état réel.
</p>

<p align="center"><i>Specula</i> : la tour de guet, en latin.</p>

## 🛠 TestFlight

La bêta est ouverte. Un seul lien pour l'iPhone, l'iPad et le Mac ; l'app Watch
s'installe avec celle de l'iPhone.

<a href="https://testflight.apple.com/join/mXBXqMnN"><img src="https://img.shields.io/badge/Rejoindre%20la%20b%C3%AAta%20sur-TestFlight-0D96F6?logo=apple&logoColor=white" alt="Rejoindre la bêta sur TestFlight" height="34"></a>

Nécessite **iOS/iPadOS 26, macOS 26, watchOS 26**. Aucune version antérieure n'est
prise en charge.

## 📸 Captures

<p align="center">
  <img src="docs/screenshots/macos.png" width="880"
       alt="Fenêtre macOS en trois colonnes : à gauche les sources et les groupes, au centre les services en cartes avec leurs métriques, à droite l'inspecteur de Jellyfin — histogramme de latence, compteurs, journal du conteneur. En haut le bandeau système ; Komga est signalé hors ligne en rouge.">
</p>

<p align="center">
  <img src="docs/screenshots/ios.png" width="215"
       alt="iPhone : liste des services par groupe avec la latence de chacun, bandeau système en tête, Komga marqué hors ligne.">
  <img src="docs/screenshots/ios-detail.png" width="215"
       alt="iPhone, fiche Jellyfin : histogramme de latence sur une minute, compteurs de films, séries et épisodes, disponibilité sur 30 jours, journal du conteneur.">
  <img src="docs/screenshots/ipados.png" width="290"
       alt="iPad : les dix-sept services des quatre groupes en grille, chacun avec ses métriques lues via son API.">
  <img src="docs/screenshots/watchos.png" width="105"
       alt="Apple Watch : seize services en ligne sur dix-sept, panne de Komga en tête, puis les services épinglés avec leur latence.">
</p>

<p align="center"><em>Mode démo — toutes les surfaces fonctionnent sans homelab.</em></p>

## ✨ Fonctionnalités

- **Plus de soixante intégrations** — Jellyfin, \*arr, AdGuard, Proxmox, Immich,
  Nextcloud, Home Assistant, UniFi, Portainer, Vaultwarden, Paperless et d'autres,
  reconnues automatiquement et lues via leur propre API.
- **Détection de panne** — trois tentatives échouées passent un service hors ligne,
  avec notification et Live Activity. Le mur de statut garde trente jours d'historique
  et calcule la disponibilité réelle.
- **Sur tous tes écrans** — widgets sur l'écran d'accueil, complications au poignet,
  accès depuis la barre de menus du Mac.
- **Mode démo** — données simulées, panne scénarisée, aucun homelab requis. C'est là
  que l'app s'ouvre au premier lancement.

## 🚀 Prise en main

Trois façons d'ajouter tes services, proposées au premier lancement et disponibles à
tout moment dans les réglages :

- **Scanner le réseau** en Bonjour — Specula trouve ce qui s'annonce et devine chaque
  type.
- **Importer un `services.yaml`** au format gethomepage.dev — groupes, URL et widgets
  sont repris tels quels.
- **Saisir une adresse** à la main.

Une seule URL par service : ce qui rend un homelab joignable de l'extérieur — VPN,
reverse proxy, tunnel — se règle sous l'app, pas dedans.

## 🔒 Vie privée

Aucun compte, aucune télémétrie, aucun serveur intermédiaire. L'app parle à tes
machines et à rien d'autre, et les clés API vivent dans le trousseau — jamais dans une
sauvegarde, jamais sur iCloud.

Une exception : les logos des services viennent du CDN public
[dashboard-icons](https://github.com/homarr-labs/dashboard-icons) via jsDelivr, qui
voit donc quels logos sont demandés — jamais tes adresses ni tes données. Un
interrupteur dans les réglages le coupe, l'app retombe alors sur des monogrammes.

## ⚙️ Développement

`project.yml` est la source de vérité — le projet Xcode est généré par
[XcodeGen](https://github.com/yonaskolb/XcodeGen). Voir
[CONTRIBUTING.md](CONTRIBUTING.md) pour l'installation.

Les commits doivent être des [Conventional Commits](https://www.conventionalcommits.org)
valides : le dépôt est branché sur release-please, et un en-tête mal formé est
purement ignoré.

Le design suit un système « Modernist » — flat, architectural, radius 0, filets
structurels, un seul accent rouge (`#ec3013`), typographie Archivo.

## 📄 Licence

[GPL-3.0](LICENSE) © nysia. Toute redistribution, modifiée ou non, reste sous la même
licence et publie ses sources.

L'app est par ailleurs publiée sur l'App Store, dont les conditions sont incompatibles
avec la GPLv3 : les contributions demandent donc une autorisation de distribution
supplémentaire, décrite dans
[CONTRIBUTING.md](CONTRIBUTING.md#licence-et-distribution).

**Nom et icône** — la licence porte sur le code. Le nom « Specula » et l'icône de
l'application n'en font pas partie et restent la propriété de leur auteur. Compiler,
étudier, modifier et redistribuer le code reste entièrement libre ; un fork distribué
publiquement doit simplement porter un autre nom et une autre icône, comme le veut
l'usage du logiciel libre.

La police Archivo (Omnibus-Type) est distribuée sous
[SIL Open Font License 1.1](Resources/Fonts/OFL.txt), indépendamment du code.
