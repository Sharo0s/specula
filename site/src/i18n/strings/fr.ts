export const fr = {
  // — méta —
  'site.description':
    'Tableau de bord natif pour tes services auto-hébergés, sur iPhone, iPad et Mac. Il lit leurs métriques, repère les pannes et alimente les widgets. Sans compte, sans serveur, sans télémétrie.',

  // — navigation —
  'nav.integrations': 'Intégrations',
  'nav.pricing': 'Prix',
  'nav.how': 'Fonctionnement',
  'nav.faq': 'FAQ',
  'nav.privacy': 'Vie privée',
  'nav.changelog': 'Journal',
  'theme.toggle': 'Changer de thème',
  'nav.cta': 'Rejoindre la bêta',

  // — hero —
  'hero.title': 'Tes services tombent en silence.',
  'hero.title.accent': 'en silence.',
  'hero.lede':
    'Plus maintenant. Specula lit les métriques de ton homelab, repère les pannes et te prévient — notification, Live Activity, widget.',
  'hero.cta.primary': 'Rejoindre la bêta TestFlight',

  // — captures d'écran —
  'shot.ios.alt':
    'Specula sur iPhone : la liste des services par groupe avec la latence de chacun, le bandeau système en tête, Komga marqué hors ligne.',

  // — marquee d'intégrations —
  'marquee.label': 'Reconnus automatiquement — lus via leur propre API',
  'marquee.more': '+ {count} autres',
  'marquee.browse': 'Parcourir les {count} intégrations',

  // — le constat —
  'watch.eyebrow': 'Le constat',
  'watch.title': 'Ton homelab tourne. Qui le regarde ?',
  'watch.title.accent': 'Qui le regarde ?',
  'watch.p1':
    'La plupart des tableaux de bord affichent des liens. Jolis quand tout va bien, muets quand ça casse — et c’est un utilisateur qui te préviendra que Jellyfin est tombé.',
  'watch.p2':
    'Specula lit les métriques de chaque service, via sa propre API. Trois lectures échouées, et le service passe hors ligne : notification, Live Activity, et le mur de statut garde la trace.',
  'stat.fail.b': '3',
  'stat.fail.text': 'tentatives échouées, et le service est déclaré hors ligne — pas une de plus',
  'stat.history.b': '30 j',
  'stat.history.text': 'd’historique de statut, avec la disponibilité réelle calculée',
  'stat.zero.b': '0',
  'stat.zero.text': 'compte, serveur intermédiaire ou télémétrie — l’app parle à tes machines, à rien d’autre',

  // — fonctionnalités —
  'features.eyebrow': 'Fonctionnalités',
  'features.title': 'Tout pour monter la garde.',
  'features.sub': 'Pas un mur de liens : un tableau de bord qui lit, vérifie et alerte.',
  'features.detect.title': 'Détection de panne',
  'features.detect.body':
    'Trois tentatives échouées passent un service hors ligne, avec notification et Live Activity. Le retour en ligne est notifié aussi.',
  'features.screens.title': 'Sur tous tes écrans',
  'features.screens.body':
    'Widgets sur l’écran d’accueil, accès depuis la barre de menus du Mac. L’état réel, sans ouvrir l’app.',
  'features.private.title': 'Rien ne sort de chez toi',
  'features.private.body':
    'Aucun compte, aucune télémétrie. Les clés API vivent dans le trousseau — jamais dans une sauvegarde, jamais sur iCloud.',

  // — comment ça marche —
  'how.eyebrow': 'Comment ça marche',
  'how.title': 'De zéro à surveillé en trois gestes.',
  'how.step': 'Étape',
  'how.scan.title': 'Scanne ton réseau',
  'how.scan.b1': 'Specula écoute ton réseau local et reconnaît tout seul ce qui y tourne',
  'how.scan.b2': 'Un services.yaml au format gethomepage.dev s’importe tel quel',
  'how.scan.b3': 'Et une adresse se saisit toujours à la main',
  'how.scan.demo': 'Scan en cours',
  'how.recognized': 'reconnu',
  'how.scan.found': '12 services trouvés',
  'how.read.title': 'Lit les vraies métriques',
  'how.read.b1': 'Chaque intégration parle l’API native du service',
  'how.read.b2': 'Les clés API entrent dans le trousseau, pas dans un fichier',
  'how.read.b3': 'Les widgets affichent ces chiffres-là, pas un cache',
  'how.read.demo': 'Lecture en direct',
  'how.jellyfin.movies': '412 films',
  'how.jellyfin.shows': '87 séries',
  'how.alert.title': 'Ne rate aucune panne',
  'how.alert.b1': 'Trois échecs, et le service passe hors ligne — notification immédiate',
  'how.alert.b2': 'Une Live Activity suit la panne jusqu’au retour',
  'how.alert.b3': 'Le mur de statut garde trente jours et calcule la disponibilité réelle',
  'how.alert.demo': 'Panne détectée',
  'how.alert.notif': 'Home Assistant est hors ligne',
  'how.alert.notifBody': 'trois tentatives échouées sur 192.168.1.56.',
  'how.tl.down': 'hors ligne · 03 h 12',
  'how.tl.up': 'en ligne · 03 h 34',
  'how.tl.note': '22 min d’interruption, historisées',

  // — vie privée —
  'privacy.body':
    'L’app parle à tes machines et à rien d’autre. Pas d’inscription, pas d’intermédiaire par lequel transitent tes adresses, pas de mouchard. Les clés API vivent dans le trousseau de l’appareil — jamais dans une sauvegarde, jamais sur iCloud.',

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
  'integrations.key.chip': 'clé API',
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
  'changelog.title': 'Ce qui change',
  'changelog.description':
    'Le journal est généré depuis les commits — chaque version raconte exactement ce qu’elle apporte.',
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
    'Scanne ton réseau en Bonjour, importe ton services.yaml existant, ou saisis l’adresse. Specula reconnaît le service tout seul.',
  'integration.cta': 'Essayer avec {service}',

  // — FAQ —
  'faq.eyebrow': 'FAQ',
  'faq.title': 'Questions fréquentes',
  'faq.vpn.q': 'Mon homelab n’est joignable qu’en VPN. Ça marche ?',
  'faq.vpn.a':
    'Oui. Une seule URL par service : ce qui rend un homelab joignable de l’extérieur — VPN, reverse proxy, tunnel — se règle sous l’app, pas dedans. Si ton appareil atteint le service, Specula aussi.',
  'faq.egress.q': 'Qu’est-ce qui sort de mon réseau, exactement ?',
  'faq.egress.a':
    'Presque rien, et tout est nommé. Le nombre de places achetées est écrit dans ton stockage clé-valeur iCloud — un entier, ni tes services, ni leurs adresses, ni tes clés. Et les logos viennent du CDN public dashboard-icons ; un interrupteur le coupe, l’app retombe sur des monogrammes.',
  'faq.homepage.q': 'J’utilise déjà Homepage, je recommence tout ?',
  'faq.homepage.a':
    'Non : importe ton services.yaml au format gethomepage.dev — groupes, adresses et widgets sont repris tels quels. Seules les clés en variables {{HOMEPAGE_VAR_…}} restent à saisir une fois : elles vivent dans le .env de Homepage, auquel Specula n’a pas accès.',
  'faq.generic.q': 'Mon service n’est pas dans les 65 intégrations ?',
  'faq.generic.a':
    'Toute adresse qui répond est suivie en générique — disponibilité, latence, trente jours d’historique. Et les intégrations s’ajoutent : demande la tienne sur GitHub, le nom du service et un lien vers la doc de son API suffisent.',
  'faq.more': 'Une autre question ?',
  'faq.more.link': 'L’assistance répond',

  // — fermeture —
  'cta.store': 'Télécharger dans l’App Store',
  'cta.eyebrow': 'Specula, du latin « tour de guet »',
  'cta.title.live': 'Prêt à monter la garde ?',
  'cta.title.accent': 'la garde ?',
  'cta.body.live':
    'Gratuit, sans compte, quatre services compris. La même app sur l’iPhone, l’iPad et le Mac.',
  'cta.price': 'Gratuit jusqu’à quatre services, puis {price} la place',
  'cta.title': 'La bêta est ouverte',
  'cta.body':
    'Un seul lien TestFlight pour l’iPhone, l’iPad et le Mac. Le mode démo se lance sans rien configurer.',

  // — vitrine défilante de l'accueil —
  'journey.read': 'Lire',
  'journey.alert': 'Alerter',
  'journey.status': 'Statut',
  'journey.settings': 'Réglages',
  'journey.adguard.reqs': '31 402 req/j',
  'journey.adguard.blocked': '22 % bloquées',
  'journey.proxmox.nodes': '3 nœuds',
  'journey.proxmox.cpu': 'CPU 12 %',
  'journey.down.title': 'Komga ne répond plus',
  'journey.down.body': 'trois tentatives échouées.',
  'journey.down.time': '03 h 12',
  'journey.up.title': 'Komga est de retour',
  'journey.up.body': '22 min d’interruption.',
  'journey.up.time': '03 h 34',
  'journey.incident.title': 'Incident — Komga',
  'journey.incident.date': '12 août · 22 min',
  'journey.incident.body': 'connexion refusée, notifiée à 03 h 12.',
  'journey.uptime.title': 'Disponibilité moyenne',
  'journey.uptime.value': '99,9 %',
  'journey.uptime.body': 'Trente jours d’historique, calculés sur trois lectures par service.',
  'journey.pinned.title': 'Épinglés',
  'journey.pinned.body': 'Quatre services affichés dans le widget et la barre de menus du Mac.',
  'journey.theme.title': 'Thème & langues',
  'journey.theme.body': 'Système, clair ou sombre — et cinq langues, dont l’arabe et le chinois.',
  'journey.alert.alt': 'Le détail d’une panne : Komga hors ligne, latence à plat, journal du conteneur.',
  'journey.status.alt': 'Le mur de disponibilité : une rangée de trente jours par service, les incidents en rouge.',
  'journey.settings.alt': 'Les réglages : pictogrammes, groupes et services épinglés.',

  // — pied de page —
  'support.title': 'On répond.',
  'support.lede': 'Un mail, un dépôt public, et les réponses aux questions qui reviennent.',
  'footer.support': 'Assistance',
  'footer.privacy': 'Confidentialité',
  'footer.changelog': 'Journal des versions',
  'footer.license': 'Police Archivo sous SIL Open Font License 1.1.',
  'footer.language': 'Langue',
} as const;
