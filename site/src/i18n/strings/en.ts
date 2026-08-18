export const en = {
  // — meta —
  'site.description':
    'A native dashboard for your self-hosted services on iPhone, iPad and Mac. It reads their metrics, catches outages and drives the widgets. No account, no server, no telemetry.',

  // — navigation —
  'nav.integrations': 'Integrations',
  'nav.pricing': 'Pricing',
  'nav.how': 'How it works',
  'nav.faq': 'FAQ',
  'nav.privacy': 'Privacy',
  'nav.changelog': 'Changelog',
  'theme.toggle': 'Switch theme',
  'nav.cta': 'Join the beta',
  'nav.menu': 'Menu',

  // — hero —
  'hero.title': 'Your homelab, without the worry.',
  'hero.title.accent': 'without the worry.',
  'hero.lede':
    'Specula sees everything: live metrics, every service watched, instant alerts.',
  'hero.cta.primary': 'Join the TestFlight beta',

  // — captures d'écran —
  'shot.ios.alt':
    'Specula on iPhone: services listed by group with each one’s latency, the system band on top, Komga marked offline.',

  // — integrations marquee —
  'marquee.label': 'Recognized automatically — read through their own API',
  'marquee.more': '+ {count} more',
  'marquee.browse': 'Browse all {count} integrations',

  // — the observation —
  'watch.eyebrow': 'The problem',
  'watch.title': 'Your homelab runs. Who’s watching it?',
  'watch.title.accent': 'Who’s watching it?',
  'watch.p1':
    'Most dashboards show links. Pretty when everything works, silent when something breaks — and it’s a user who ends up telling you Jellyfin went down.',
  'watch.p2':
    'Specula reads each service’s metrics through its own API. Three failed reads, and the service goes offline: a notification, a Live Activity, and the status wall keeps the record.',
  'stat.fail.b': '3',
  'stat.fail.text': 'failed attempts before a service is declared down — not one more',
  'stat.history.b': '30 d',
  'stat.history.text': 'of status history, with real uptime computed',
  'stat.zero.b': '0',
  'stat.zero.text': 'accounts, middleman servers or telemetry — the app talks to your machines, nothing else',

  // — features —
  'features.eyebrow': 'Features',
  'features.title': 'Everything to stand guard.',
  'features.sub': 'Not a wall of links: a dashboard that reads, checks and alerts.',
  'features.detect.title': 'Outage detection',
  'features.detect.body':
    'Three failed attempts mark a service offline, with a notification and a Live Activity. Recovery is notified too.',
  'features.screens.title': 'On every screen you own',
  'features.screens.body':
    'Widgets on the Home Screen, quick access from the Mac menu bar. Live state, without opening the app.',
  'features.private.title': 'Nothing leaves your home',
  'features.private.body':
    'No account, no telemetry. API keys live in the keychain — never in a backup, never on iCloud.',

  // — how it works —
  'how.eyebrow': 'How it works',
  'how.title': 'From zero to monitored in three moves.',
  'how.step': 'Step',
  'how.scan.title': 'Scan your network',
  'how.scan.b1': 'Specula listens to your local network and recognizes what runs on it, on its own',
  'how.scan.b2': 'A services.yaml in the gethomepage.dev format imports as-is',
  'how.scan.b3': 'And an address can always be typed by hand',
  'how.scan.demo': 'Scan in progress',
  'how.recognized': 'recognized',
  'how.scan.found': '12 services found',
  'how.read.title': 'Reads the real metrics',
  'how.read.b1': 'Each integration speaks the service’s native API',
  'how.read.b2': 'API keys go into the keychain, not into a file',
  'how.read.b3': 'The widgets show those numbers, not a cache',
  'how.read.demo': 'Live reading',
  'how.jellyfin.movies': '412 movies',
  'how.jellyfin.shows': '87 shows',
  'how.alert.title': 'Never misses an outage',
  'how.alert.b1': 'Three failures, and the service goes offline — immediate notification',
  'how.alert.b2': 'A Live Activity follows the outage until recovery',
  'how.alert.b3': 'The status wall keeps thirty days and computes real uptime',
  'how.alert.demo': 'Outage detected',
  'how.alert.notif': 'Home Assistant is offline',
  'how.alert.notifBody': 'three failed attempts on 192.168.1.56.',
  'how.tl.down': 'offline · 3:12 AM',
  'how.tl.up': 'online · 3:34 AM',
  'how.tl.note': '22 min of downtime, kept on record',

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
  'integrations.title': 'The services Specula recognizes',
  'integrations.lede':
    'Every integration is hand-written against the service’s own API. Here is what Specula reads from each one — and what it doesn’t.',
  'integrations.metrics.title': 'What Specula reads',
  'integrations.metrics.none':
    'No metrics: Specula tracks its availability and latency, nothing more.',
  'integrations.endpoints.title': 'API endpoints called',
  'integrations.key.chip': 'API key',
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
  'changelog.title': 'What changes',
  'changelog.description': 'What changed in Specula with every update.',
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
    'Scan your network over Bonjour, import your existing services.yaml, or type the address. Specula recognizes the type on its own.',
  'integration.cta': 'Try it with {service}',

  // — FAQ —
  'faq.eyebrow': 'FAQ',
  'faq.title': 'Frequently asked questions',
  'faq.vpn.q': 'My homelab is only reachable over VPN. Does it work?',
  'faq.vpn.a':
    'Yes. One URL per service: whatever makes a homelab reachable from outside — VPN, reverse proxy, tunnel — belongs under the app, not inside it. If your device can reach the service, so can Specula.',
  'faq.egress.q': 'What leaves my network, exactly?',
  'faq.egress.a':
    'Almost nothing, and all of it is named. The number of purchased slots is written to your iCloud key-value store — an integer, not your services, their addresses or your keys. And logos come from the public dashboard-icons CDN; a switch turns it off, and the app falls back to monograms.',
  'faq.homepage.q': 'I already run Homepage. Do I start over?',
  'faq.homepage.a':
    'No: import your services.yaml in the gethomepage.dev format — groups, addresses and widgets carry over as-is. Only keys stored as {{HOMEPAGE_VAR_…}} variables need typing once: they live in Homepage’s .env, which Specula has no access to.',
  'faq.generic.q': 'My service isn’t among the {count} integrations?',
  'faq.generic.a':
    'Any address that answers is tracked as generic — availability, latency, thirty days of history. And integrations keep landing: ask for yours on GitHub, the service’s name and a link to its API docs are enough.',
  'faq.more': 'Another question?',
  'faq.more.link': 'Support has answers',

  // — closing —
  'cta.store': 'Download on the App Store',
  'cta.eyebrow': 'Specula, Latin for “watchtower”',
  'cta.title.live': 'Ready to stand guard?',
  'cta.title.accent': 'stand guard?',
  'cta.body.live':
    'Free, no account, four services included. The same app on iPhone, iPad and Mac.',
  'cta.price': 'Free up to four services, then {price} per slot',
  'cta.title': 'The beta is open',
  'cta.body':
    'One TestFlight link for iPhone, iPad and Mac. Demo mode runs with nothing configured.',

  // — vitrine défilante de l'accueil —
  'journey.read': 'Read',
  'journey.alert': 'Alert',
  'journey.status': 'Status',
  'journey.settings': 'Settings',
  'journey.adguard.reqs': '31,402 req/day',
  'journey.adguard.blocked': '22% blocked',
  'journey.proxmox.nodes': '3 nodes',
  'journey.proxmox.cpu': 'CPU 12%',
  'journey.down.title': 'Komga stopped responding',
  'journey.down.body': 'three failed attempts.',
  'journey.down.time': '3:12 AM',
  'journey.up.title': 'Komga is back',
  'journey.up.body': '22 min of downtime.',
  'journey.up.time': '3:34 AM',
  'journey.incident.title': 'Incident — Komga',
  'journey.incident.date': 'Aug 12 · 22 min',
  'journey.incident.body': 'connection refused, notified at 3:12 AM.',
  'journey.uptime.title': 'Average availability',
  'journey.uptime.value': '99.9%',
  'journey.uptime.body': 'Thirty days of history, computed from three reads per service.',
  'journey.pinned.title': 'Pinned',
  'journey.pinned.body': 'Four services shown on the widget and in the Mac menu bar.',
  'journey.theme.title': 'Theme & languages',
  'journey.theme.body': 'System, light or dark — and five languages, Arabic and Chinese included.',
  'journey.alert.alt': 'An outage in detail: Komga offline, latency flatlined, container log.',
  'journey.status.alt': 'The availability wall: one thirty-day row per service, incidents in red.',
  'journey.settings.alt': 'Settings: icons, groups and pinned services.',

  // — footer —
  'support.title': 'We answer.',
  'support.lede': 'One email, a public repository, and answers to the questions that keep coming back.',
  'footer.support': 'Support',
  'footer.privacy': 'Privacy',
  'footer.changelog': 'Changelog',
  'footer.license': 'Archivo typeface under SIL Open Font License 1.1.',
  'footer.language': 'Language',
} as const;
