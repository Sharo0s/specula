export const en = {
  // — meta —
  'site.description':
    'A native dashboard for your self-hosted services on iPhone, iPad and Mac. It reads their real metrics, catches outages and drives the widgets. No account, no server, no telemetry.',

  // — navigation —
  'nav.integrations': 'Integrations',
  'nav.pricing': 'Pricing',
  'nav.privacy': 'Privacy',
  'nav.changelog': 'Changelog',
  'theme.toggle': 'Switch theme',
  'nav.cta': 'Join the beta',
  'nav.cta.live': 'Download',

  // — hero —
  'hero.title': 'Your homelab in your hand',
  'hero.title.accent': 'in your hand',
  'hero.lede':
    'One glance in the morning and you know everything: what’s running, what’s crawling, what went down overnight. On iPhone, iPad and Mac.',
  'hero.proof.privacy': 'No account, no server, no telemetry.',
  'hero.proof.platforms': 'iPhone, iPad and Mac — natively.',
  'hero.cta.primary': 'Join the TestFlight beta',
  'hero.cta.secondary': 'Browse the integrations',

  // — captures d'écran —
  'shot.macos.alt':
    'Specula on macOS: sources and groups down one side, service cards with their metrics in the middle, and one service’s detail alongside.',
  'shot.ios.alt':
    'Specula on iPhone: services listed by group with each one’s latency, the system band on top, Komga marked offline.',
  'shot.ipados.alt':
    'Specula on iPad: the services, group by group, in a grid, each with the metrics read from its own API.',

  // — features —
  'features.eyebrow': 'What it does',
  'features.title': 'A ping says “it answers”. Specula says what.',

  'features.metrics.title': 'Real metrics, through each service’s own API',
  'features.metrics.body':
    'Specula speaks each service’s own language: /control/stats for AdGuard, the Proxmox cluster API, the NAS’s own statistics. You get numbers that mean something, not a green dot.',

  'features.outage.title': 'Outage detection, not alerts on every hiccup',
  'features.outage.body':
    'It takes three failed attempts before a service is marked down — flaky Wi-Fi doesn’t wake anyone up. Then: a notification, a Live Activity, and a status wall that keeps thirty days and computes real uptime.',

  'features.surfaces.title': 'On every screen you own',
  'features.surfaces.body':
    'Home Screen and Lock Screen widgets driven by live state, a menu bar item on the Mac, a Live Activity while a service is down. A native app, not a web page in a shell.',

  'features.demo.title': 'A demo mode that asks nothing of you',
  'features.demo.body':
    'The app opens in demo mode on first launch: a full homelab, believable metrics and a scripted outage. You judge the app before handing it a single address.',

  // — setup —
  'surface.home': 'Home Screen',
  'surface.lock': 'Lock Screen',
  'surface.menubar': 'Menu bar',
  'feature.uptime': 'Thirty days of uptime',
  'feature.demo.chip': 'Demo mode',

  'setup.eyebrow': 'Getting started',
  'setup.title': 'Three ways to start',
  'setup.scan.title': 'Scan the network',
  'setup.scan.body':
    'Specula listens for Bonjour on your network, finds what announces itself and guesses each service’s type.',
  'setup.yaml.title': 'Import a services.yaml',
  'setup.yaml.body':
    'The gethomepage.dev format, taken as-is: groups, URLs and widgets. Export works too, both directions.',
  'setup.manual.title': 'Type an address',
  'setup.manual.body':
    'One URL, an API key if the service needs one. Whatever makes your homelab reachable from outside — VPN, reverse proxy, tunnel — belongs under the app, not inside it.',

  // — privacy —
  'privacy.body':
    'The app talks to your machines and to nothing else. No signup, no middleman your addresses travel through, no tracker. API keys live in the device keychain — never in a backup, never on iCloud.',

  // — pricing —
  'pricing.eyebrow': 'Pricing',
  'pricing.title': 'Four services free, then one slot at a time',
  'pricing.body':
    'The first four services are free, with no time limit and no account. Beyond that, each extra slot is a one-time purchase. Pricing is strictly linear: no bundles, no tiers, no subscription. You pick how many slots you want and pay once.',
  'pricing.free.title': 'Free no matter what',
  'pricing.free.items': [
    'The entire demo mode',
    'Every integration',
    'Alerts and outage detection',
    'Widgets and Live Activity',
    'services.yaml import and export',
  ],
  'pricing.quota.title': 'What the quota counts',
  'pricing.quota.body':
    'Only how many services you monitor at once. Deleting a service frees its slot for another. An unlimited unlock exists separately, for those who want to support the project.',
  'pricing.note': 'French price. The App Store shows yours, in your own currency.',

  // — integrations —
  'integrations.eyebrow': 'Integrations',
  'integrations.title': 'The services Specula recognises',
  'integrations.lede':
    'Every integration is hand-written against the service’s own API. Here is what Specula reads from each one — and what it doesn’t.',
  'integrations.metrics.title': 'What Specula reads',
  'integrations.metrics.none':
    'No metrics: Specula tracks its availability and latency, nothing more.',
  'integrations.endpoints.title': 'API endpoints called',
  'integrations.key.title': 'Credential required',
  'integrations.key.none': 'None — a URL is enough.',
  'integrations.key.userPassword': 'Username and password',
  'integrations.key.password': 'Password',
  'integrations.key.token': 'A single token',
  'integrations.missing': 'Your service isn’t listed?',
  'integrations.missing.body':
    'Any address that answers is tracked as generic — availability, latency, history. And integrations keep landing: ask for yours on GitHub.',
  'integrations.missing.cta': 'Request an integration',

  // — pages légales —
  'legal.updated': 'Last updated:',
  'legal.notice':
    'This page exists in English and French only. A legal text translated without review is worth less than the same text in a language you can check.',

  // — journal —
  'changelog.title': 'What shipped, release by release',
  'changelog.description':
    'Every Specula release, straight from the repository. Versions and notes are generated from the commits themselves.',
  'changelog.language':
    'The notes are written in French: they come from the commit messages, and translating a copy would let it drift at the next release.',

  // — page prix —
  'pricing.price.slot': 'per slot, one-time',
  'pricing.price.unlimited': 'for the unlimited unlock',
  'pricing.page.title': 'Pricing',
  'pricing.how.title': 'How a slot works',
  'pricing.how.body':
    'A slot is one monitored service. You start with four. Buying more is a one-time purchase per slot, at a flat per-slot price — buy two now and three later and you pay exactly the same as buying five at once.',
  'pricing.restore.title': 'Changing devices',
  'pricing.restore.body':
    'The number of slots you own is stored in your iCloud key-value store, so a new iPhone or Mac finds them again. Purchases can also be restored from the App Store at any time.',
  'pricing.unlimited.title': 'Unlimited unlock',
  'pricing.unlimited.body':
    'A separate one-time purchase that lifts the slot count entirely. It exists for people who run large homelabs — and for those who simply want to support the project.',
  'pricing.refund.title': 'Refunds',
  'pricing.refund.body':
    'Purchases go through the App Store, so refunds are handled by Apple, under Apple’s terms — Specula never sees your payment details.',

  // — familles de services —
  'family.media': 'Media',
  'family.downloads': 'Downloads & libraries',
  'family.network': 'Network',
  'family.infra': 'Machines & storage',
  'family.home': 'Home automation',
  'family.monitoring': 'Monitoring',
  'family.tools': 'Tools',

  // — page d'une intégration —
  'integration.heading': '{service} on your iPhone, iPad and Mac',
  'integration.lede':
    'Specula reads {service} through its own API and shows {metrics} — on the Home Screen, in a widget, and in the menu bar of your Mac. No account, no agent to install, no middleman.',
  'integration.lede.plain':
    'Specula tracks {service}: whether it answers, how fast, and thirty days of uptime history — on your iPhone, iPad and Mac. No account, no agent to install, no middleman.',
  'integration.back': 'All integrations',
  'integration.official': 'Official site',
  'integration.setup': 'Adding it takes a minute',
  'integration.setup.body':
    'Scan your network over Bonjour, import your existing services.yaml, or type the address. Specula guesses the type on its own.',
  'integration.cta': 'Try it with {service}',

  // — FAQ —
  'faq.eyebrow': 'Questions',
  'faq.title': 'What people ask most',
  'faq.remote.q': 'What if my homelab isn’t exposed to the internet?',
  'faq.remote.a':
    'Specula asks for one URL per service and never tries to punch through your network. Whatever makes your homelab reachable from outside — VPN, reverse proxy, tunnel — belongs under the app. On your own network, there is nothing to do.',
  'faq.away.q': 'How do I check on it while I’m away?',
  'faq.away.a':
    'One address per service: the one that works from both sides. With a mesh network like Tailscale, enter the MagicDNS name — jellyfin.your-tailnet.ts.net — it resolves at home and away, and traffic still goes straight over your LAN when you are on it. A reverse proxy or a tunnel does the same job. Specula never builds a route: it follows yours, and keeps accepting your service’s self-signed certificate on the tailnet address range.',
  'faq.selfhost.q': 'Do I have to host anything?',
  'faq.selfhost.a':
    'No. No agent to install, no container to run, no account to create. The app queries the APIs your services already expose.',
  'faq.versions.q': 'Why iOS 26 and macOS 26 only?',
  'faq.versions.a':
    'The app is written against that generation’s APIs. No earlier version is supported.',
  'faq.homepage.q': 'I already run gethomepage. Do I retype everything?',
  'faq.homepage.a':
    'No. Specula imports your services.yaml as-is — groups, URLs and widgets — and can export it back.',

  // — closing —
    'cta.store': 'Download on the App Store',
  'cta.title.live': 'Specula is on the App Store',
  'cta.body.live': 'One app for iPhone, iPad and Mac. Demo mode runs with nothing configured.',
  'cta.price': 'Free up to four services, then {price} per slot',
'cta.title': 'The beta is open',
  'cta.body':
    'One TestFlight link for iPhone, iPad and Mac. Demo mode runs with nothing configured.',

  // — footer —
  'footer.support': 'Support',
  'footer.privacy': 'Privacy',
  'footer.changelog': 'Changelog',
  'footer.license': 'GPL-3.0 © nysia. Archivo typeface under SIL Open Font License 1.1.',
  'footer.language': 'Language',
} as const;
