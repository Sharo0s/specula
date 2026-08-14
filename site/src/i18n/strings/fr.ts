export const fr = {
  // — méta —
  'site.tagline': 'Le tableau de bord natif de ton homelab',
  'site.description':
    'Tableau de bord natif pour tes services auto-hébergés, sur iPhone, iPad et Mac. Il lit leurs vraies métriques, repère les pannes et alimente les widgets. Sans compte, sans serveur, sans télémétrie.',

  // — navigation —
  'nav.integrations': 'Intégrations',
  'nav.pricing': 'Prix',
  'nav.privacy': 'Vie privée',
  'nav.changelog': 'Journal',
  'theme.toggle': 'Changer de thème',
  'nav.cta': 'Rejoindre la bêta',
  'nav.cta.live': 'Télécharger',

  // — hero —
  'hero.title': 'Ton homelab dans ta main',
  'hero.title.accent': 'dans ta main',
  'hero.lede':
    'Un coup d’œil au réveil et tu sais tout : ce qui tourne, ce qui rame, ce qui est tombé cette nuit. Sur iPhone, iPad et Mac.',
  'hero.proof.privacy': 'Aucun compte, aucun serveur, aucune télémétrie.',
  'hero.proof.platforms': 'iPhone, iPad et Mac — en natif.',
  'hero.cta.primary': 'Rejoindre la bêta TestFlight',
  'hero.cta.secondary': 'Voir les intégrations',
  'hero.caption':
    'Mode démo — toutes les surfaces de l’app fonctionnent sans le moindre homelab.',

  // — captures d'écran —
  'shot.ios.alt':
    'Specula sur iPhone : la liste des services par groupe avec la latence de chacun, le bandeau système en tête, Komga marqué hors ligne.',
  'shot.ipados.alt':
    'Specula sur iPad : les services, groupe par groupe, en grille, chacun avec les métriques lues via son API.',

  // — fonctionnalités —
  'features.eyebrow': 'Ce que ça fait',
  'features.title': 'Un ping dit « ça répond ». Specula dit quoi.',

  'features.metrics.title': 'Les vraies métriques, via l’API de chaque service',
  'features.metrics.body':
    'Specula parle à chaque service dans sa propre langue : /control/stats pour AdGuard, l’API cluster de Proxmox, les statistiques du NAS. Tu vois des chiffres qui veulent dire quelque chose, pas une pastille verte.',

  'features.outage.title': 'Détection de panne, pas d’alerte au moindre hoquet',
  'features.outage.body':
    'Il faut trois tentatives échouées pour qu’un service passe hors ligne — le Wi-Fi qui tousse ne réveille personne. Ensuite : notification, Live Activity, et un mur de statut qui garde trente jours et calcule la disponibilité réelle.',

  'features.surfaces.title': 'Sur tous tes écrans',
  'features.surfaces.body':
    'Widgets d’écran d’accueil et d’écran verrouillé alimentés par l’état réel, accès depuis la barre des menus du Mac, Live Activity pendant une panne. Une app native, pas une page web dans une coque.',

  'features.demo.title': 'Un mode démo qui n’attend rien de toi',
  'features.demo.body':
    'L’app s’ouvre en mode démo au premier lancement : un homelab complet, des métriques crédibles et une panne scénarisée. Tu juges l’app avant de lui donner la moindre adresse.',

  // — prise en main —
  'surface.home': 'Écran d’accueil',
  'surface.lock': 'Écran verrouillé',
  'surface.menubar': 'Barre des menus',
  'feature.uptime': 'Disponibilité sur trente jours',
  'feature.demo.chip': 'Mode démo',

  'setup.eyebrow': 'Prise en main',
  'setup.title': 'Trois façons de commencer',
  'setup.scan.title': 'Scanner le réseau',
  'setup.scan.body':
    'Specula écoute le Bonjour de ton réseau, trouve ce qui s’annonce et devine le type de chaque service.',
  'setup.yaml.title': 'Importer un services.yaml',
  'setup.yaml.body':
    'Le format de gethomepage.dev, repris tel quel : groupes, URL et widgets. L’export existe aussi, dans les deux sens.',
  'setup.manual.title': 'Saisir une adresse',
  'setup.manual.body':
    'Une URL, éventuellement une clé API. Ce qui rend ton homelab joignable de l’extérieur — VPN, reverse proxy, tunnel — se règle sous l’app, pas dedans.',

  // — vie privée —
  'privacy.body':
    'L’app parle à tes machines et à rien d’autre. Pas d’inscription, pas d’intermédiaire par lequel transitent tes adresses, pas de mouchard. Les clés API vivent dans le trousseau de l’appareil — jamais dans une sauvegarde, jamais sur iCloud.',
  'privacy.link': 'Lire la politique de confidentialité',

  // — prix —
  'pricing.eyebrow': 'Prix',
  'pricing.title': 'Quatre services gratuits, puis une place à la fois',
  'pricing.body':
    'Les quatre premiers services sont gratuits, sans limite de durée et sans compte. Au-delà, chaque place supplémentaire s’achète une fois. Le prix est strictement linéaire : pas de pack, pas de palier, pas d’abonnement. Tu choisis combien de places et tu paies en une transaction.',
  'pricing.free.title': 'Gratuit quoi qu’il arrive',
  'pricing.free.items': [
    'Le mode démo entier',
    'Toutes les intégrations',
    'Les alertes et la détection de panne',
    'Les widgets et la Live Activity',
    'L’import et l’export de services.yaml',
  ],
  'pricing.quota.title': 'Ce que le quota compte',
  'pricing.quota.body':
    'Uniquement le nombre de services surveillés en même temps. Supprimer un service libère sa place pour un autre. Un déverrouillage illimité existe à part, pour soutenir le projet.',
  'pricing.note': 'Prix France. L’App Store affiche le tien, dans ta devise.',

  // — intégrations —
  'integrations.eyebrow': 'Intégrations',
  'integrations.title': 'Les services que Specula reconnaît',
  'integrations.lede':
    'Chaque intégration est écrite à la main contre l’API du service. Voici ce que Specula lit de chacun — et ce qu’il ne lit pas.',
  'integrations.metrics.title': 'Ce que Specula lit',
  'integrations.metrics.none':
    'Aucune métrique : Specula suit sa disponibilité et sa latence, rien de plus.',
  'integrations.endpoints.title': 'Les points d’API appelés',
  'integrations.key.title': 'Identifiant demandé',
  'integrations.key.none': 'Aucun — une URL suffit.',
  'integrations.key.userPassword': 'Utilisateur et mot de passe',
  'integrations.key.password': 'Mot de passe',
  'integrations.key.token': 'Jeton unique',
  'integrations.missing': 'Ton service n’est pas là ?',
  'integrations.missing.body':
    'Toute adresse qui répond est suivie en générique — disponibilité, latence, historique. Et les intégrations s’ajoutent : demande la tienne sur GitHub.',
  'integrations.missing.cta': 'Proposer une intégration',

  // — pages légales —
  'legal.updated': 'Dernière mise à jour :',
  'legal.notice':
    'Cette page n’existe qu’en français et en anglais. Un texte juridique traduit sans relecture vaut moins que le même texte dans une langue que vous pouvez vérifier.',

  // — journal —
  'changelog.title': 'Ce qui est sorti, version par version',
  'changelog.description':
    'Toutes les versions de Specula, telles que le dépôt les publie. Les numéros et les notes sont générés à partir des commits eux-mêmes.',
  'changelog.language':
    'Les notes sont en français : elles viennent des messages de commit, et en traduire une copie la ferait diverger dès la prochaine version.',

  // — page prix —
  'pricing.price.slot': 'la place, achat unique',
  'pricing.price.unlimited': 'le déverrouillage illimité',
  'pricing.page.title': 'Prix',
  'pricing.how.title': 'Comment marche une place',
  'pricing.how.body':
    'Une place, c’est un service surveillé. Tu commences avec quatre. Au-delà, chaque place s’achète une fois, à prix unitaire fixe — en prendre deux maintenant et trois plus tard coûte exactement le même prix qu’en prendre cinq d’un coup.',
  'pricing.restore.title': 'Changer d’appareil',
  'pricing.restore.body':
    'Le nombre de places possédées est écrit dans ton stockage clé-valeur iCloud : un nouvel iPhone ou un nouveau Mac les retrouve. Les achats se restaurent aussi depuis l’App Store à tout moment.',
  'pricing.unlimited.title': 'Déverrouillage illimité',
  'pricing.unlimited.body':
    'Un achat unique, séparé, qui lève complètement le compteur de places. Il existe pour les gros homelabs — et pour ceux qui veulent simplement soutenir le projet.',
  'pricing.refund.title': 'Remboursements',
  'pricing.refund.body':
    'Les achats passent par l’App Store : les remboursements sont donc traités par Apple, selon ses conditions. Specula ne voit jamais tes informations de paiement.',

  // — familles de services —
  'family.media': 'Médias',
  'family.downloads': 'Téléchargement et bibliothèques',
  'family.network': 'Réseau',
  'family.infra': 'Machines et stockage',
  'family.home': 'Domotique',
  'family.monitoring': 'Surveillance',
  'family.tools': 'Outils',

  // — page d'une intégration —
  'integration.heading': '{service} sur ton iPhone, ton iPad et ton Mac',
  'integration.lede':
    'Specula lit {service} via sa propre API et affiche {metrics} — sur l’écran d’accueil, dans un widget et dans la barre des menus du Mac. Sans compte, sans agent à installer, sans intermédiaire.',
  'integration.lede.plain':
    'Specula suit {service} : s’il répond, à quelle vitesse, et trente jours d’historique de disponibilité — sur ton iPhone, ton iPad et ton Mac. Sans compte, sans agent à installer, sans intermédiaire.',
  'integration.back': 'Toutes les intégrations',
  'integration.official': 'Site officiel',
  'integration.setup': 'L’ajouter prend une minute',
  'integration.setup.body':
    'Scanne ton réseau en Bonjour, importe ton services.yaml existant, ou saisis l’adresse. Specula devine le type tout seul.',
  'integration.cta': 'Essayer avec {service}',
  'integration.family': 'Famille',

  // — FAQ —
  'faq.eyebrow': 'Questions',
  'faq.title': 'Ce qu’on demande le plus souvent',
  'faq.remote.q': 'Et si mon homelab n’est pas exposé sur Internet ?',
  'faq.remote.a':
    'Specula demande une seule URL par service et n’essaie pas de percer ton réseau. Ce qui rend ton homelab joignable de l’extérieur — VPN, reverse proxy, tunnel — se règle sous l’app. Depuis ton réseau local, rien à faire.',
  'faq.selfhost.q': 'Faut-il héberger quelque chose ?',
  'faq.selfhost.a':
    'Non. Pas d’agent à installer, pas de conteneur à lancer, pas de compte à créer. L’app interroge directement les API que tes services exposent déjà.',
  'faq.versions.q': 'Pourquoi iOS 26 et macOS 26 seulement ?',
  'faq.versions.a':
    'L’app est écrite pour les API de cette génération. Aucune version antérieure n’est prise en charge.',
  'faq.homepage.q': 'J’utilise déjà gethomepage. Faut-il tout ressaisir ?',
  'faq.homepage.a':
    'Non. Specula importe ton services.yaml tel quel — groupes, URL et widgets — et sait le réexporter.',

  // — fermeture —
    'cta.store': 'Télécharger dans l’App Store',
  'cta.title.live': 'Specula est sur l’App Store',
  'cta.body.live': 'Une seule app pour l’iPhone, l’iPad et le Mac. Le mode démo se lance sans rien configurer.',
  'cta.price': 'Gratuit jusqu’à quatre services, puis {price} la place',
'cta.title': 'La bêta est ouverte',
  'cta.body':
    'Un seul lien TestFlight pour l’iPhone, l’iPad et le Mac. Le mode démo se lance sans rien configurer.',

  // — pied de page —
  'footer.source': 'Code source',
  'footer.support': 'Assistance',
  'footer.privacy': 'Confidentialité',
  'footer.changelog': 'Journal des versions',
  'footer.license': 'GPL-3.0 © nysia. Police Archivo sous SIL Open Font License 1.1.',
  'footer.language': 'Langue',
} as const;
