<p align="center">
  <img src=".github/icon.png" width="110" alt="Specula icon">
</p>

<h1 align="center">Specula</h1>

<p align="center">
  <a href="https://github.com/Sharo0s/specula/actions/workflows/ci.yml"><img src="https://github.com/Sharo0s/specula/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/iOS-26%2B-111" alt="iOS 26+">
  <img src="https://img.shields.io/badge/macOS-26%2B-111" alt="macOS 26+">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-ec3013" alt="License: GPL-3.0"></a>
  <a href="README.fr.md"><img src="https://img.shields.io/badge/lire%20en-fran%C3%A7ais-111" alt="Lire en français"></a>
</p>

<p align="center">
  <b>Specula</b> is a native homelab dashboard for iPhone, iPad and Mac.<br>
  It reads the <b>real metrics</b> of your self-hosted services, catches outages,
  and feeds widgets from live state.
</p>

<p align="center">
  <a href="https://specula.dev/">Website</a> ·
  <a href="https://specula.dev/en/support/">Support</a> ·
  <a href="https://specula.dev/en/privacy/">Privacy policy</a>
</p>

## 🛠 TestFlight

The beta is open. One link covers iPhone, iPad and Mac.

<a href="https://testflight.apple.com/join/mXBXqMnN"><img src="https://img.shields.io/badge/Get%20the%20beta%20on-TestFlight-0D96F6?logo=apple&logoColor=white" alt="Get the beta on TestFlight" height="34"></a>

Requires **iOS/iPadOS 26, macOS 26**. No earlier version is supported.

## ✨ Features

- **Integrations** — Jellyfin, \*arr, AdGuard, Proxmox, Immich, Nextcloud,
  Home Assistant, UniFi, Portainer, Vaultwarden, Paperless and more, each recognised
  automatically and read through its own API. The
  [catalogue](https://specula.dev/en/integrations/) lists them all, one page each.
- **Outage detection** — three failed attempts mark a service offline, with a
  notification and a Live Activity. The status wall keeps thirty days of history and
  computes real availability.
- **Every screen you look at** — widgets on the Home Screen, a menu bar item on
  the Mac.
- **Demo mode** — simulated data, scripted outage, no homelab needed. It is what the
  app opens on first launch.

## 🚀 Setup

Three ways to add your services, offered on first launch and available any time in
Settings:

- **Scan the network** over Bonjour — Specula finds what is advertised and guesses
  each type.
- **Import a `services.yaml`** in gethomepage.dev format — groups, URLs and widgets
  come over as they are.
- **Type an address** by hand.

One URL per service: whatever makes your homelab reachable from outside — VPN,
reverse proxy, tunnel — is configured below the app, not inside it.

## 💳 Service slots

The **first four services are free**, forever and without an account. Beyond that,
each extra slot is a one-off purchase. Pricing is strictly linear — no packs, no
tiers: pick how many slots you want and pay in a single transaction. An unlimited
unlock exists separately, to support the project. Prices are whatever the App Store
shows, in your currency.

Free no matter what: the whole demo mode, every integration, alerts, widgets, and
`services.yaml` import and export. The quota only covers how many services you watch
at once — removing a service frees its slot for another.

## 🔒 Privacy

No account, no telemetry, no server in the middle. The app talks to your machines and
nothing else, and API keys live in the Keychain — never in a backup, never on iCloud.

Two exceptions, and both are named. The **number** of service slots you bought is
written to your iCloud key-value store, so that switching devices does not lose them.
One integer, nothing else — not your services, not their addresses, not your keys.

The second: service logos come from the public
[dashboard-icons](https://github.com/homarr-labs/dashboard-icons) CDN through jsDelivr,
which therefore sees which logos are requested — never your addresses or your data.
A switch in Settings turns it off, and the app falls back to monograms.

## 🌐 Website

[**specula.dev**](https://specula.dev/) is the shop window, in the five languages the
app speaks — English, French, Spanish, Chinese and Arabic — served from your browser's
`Accept-Language`:

- the [integration catalogue](https://specula.dev/en/integrations/), one page per
  service, saying what Specula reads from each API. It is extracted from the Swift
  sources, so the site and the app cannot drift apart.
- the [changelog](https://specula.dev/en/changelog/), rendered from `CHANGELOG.md`
- [pricing](https://specula.dev/en/pricing/), [support](https://specula.dev/en/support/)
  and the [privacy policy](https://specula.dev/en/privacy/)

Its sources live in [`site/`](site/) — an Astro build deployed on Vercel, with its own
[README](site/README.md).

## ⚙️ Development

Thank you for your interest in Specula! Please check out the
[Contribution Guidelines](CONTRIBUTING.md) to get started.

## 📄 License

[GPL-3.0](LICENSE) © nysia. Any redistribution, modified or not, stays under the same
license and publishes its sources.

The app is also distributed through Apple — TestFlight today, the App Store next — whose
terms are incompatible with GPLv3: contributions therefore need an extra distribution
grant, described in CONTRIBUTING.md.

**Name and icon** — the license covers the code. The name “Specula” and the app icon
are not part of it and remain the property of their author. Building, studying,
modifying and redistributing the code stays entirely free; a publicly distributed fork
just has to carry another name and another icon, as free software custom goes.

The Archivo typeface (Omnibus-Type) ships under the
[SIL Open Font License 1.1](Resources/Fonts/OFL.txt), independently of the code.
