/**
 * Les deux pages que l'App Store exige, reprises mot pour mot des pages
 * publiées dans `docs/`. Elles n'existent qu'en français et en anglais : un
 * texte juridique traduit sans relecture vaut moins que le même texte dans une
 * langue que le lecteur peut vérifier. Les autres langues du site servent la
 * version anglaise, en le disant.
 */

export interface LegalSection {
  h: string;
  html: string;
}

export interface LegalDoc {
  title: string;
  updated?: string;
  intro?: string;
  sections: LegalSection[];
}

import { APP_STORE, TESTFLIGHT } from './links';

const MAIL = '<a href="mailto:contact@smalard.ovh">contact@smalard.ovh</a>';

export const PRIVACY: Record<'fr' | 'en', LegalDoc> = {
  fr: {
    title: 'Politique de confidentialité',
    updated: '2026-08-03',
    sections: [
      {
        h: 'En un paragraphe',
        html: `<p>Specula ne collecte aucune donnée personnelle. L'application n'a pas de compte,
        pas de serveur, pas de télémétrie et pas de publicité. Elle interroge directement les
        services que vous hébergez, depuis votre appareil, et n'envoie rien à l'éditeur ni à un
        tiers.</p>`,
      },
      {
        h: 'Données que nous collectons',
        html: `<p>Aucune. Nous ne recevons ni votre adresse e-mail, ni votre adresse IP, ni la
        liste de vos services, ni la moindre statistique d'usage. Il n'existe aucun serveur
        Specula vers lequel ces informations pourraient être envoyées.</p>`,
      },
      {
        h: 'Données stockées sur votre appareil',
        html: `<p>Tout ce que vous configurez reste local&nbsp;:</p>
        <ul>
          <li>les adresses, noms et groupes de vos services&nbsp;;</li>
          <li>vos clés API et identifiants, conservés dans le trousseau (Keychain), jamais dans
          une sauvegarde ni sur iCloud&nbsp;;</li>
          <li>l'historique des pannes et des notifications, les préférences d'affichage.</li>
        </ul>
        <p>Ces données sont synchronisées entre l'app et ses widgets via un groupe
        d'applications partagé sur votre appareil. Supprimer l'application les efface.</p>`,
      },
      {
        h: 'Connexions réseau',
        html: `<p>Specula ouvre deux types de connexions, et rien d'autre&nbsp;:</p>
        <ul>
          <li><strong>Vos services</strong> — aux adresses que vous avez saisies ou importées,
          généralement sur votre réseau local ou via votre propre VPN. Vos clés API sont envoyées
          à ces machines, et à elles seules, pour lire leurs métriques.</li>
          <li><strong>Les logos des services</strong> — récupérés sur le CDN public
          <code>cdn.jsdelivr.net</code> (projet open source <em>dashboard-icons</em>). Cette
          requête ne transmet que le nom du logo demandé, jamais vos adresses ni vos clés. Vous
          pouvez la désactiver&nbsp;: Réglages → Pictogrammes → Logos des services.</li>
        </ul>`,
      },
      {
        h: 'Notifications',
        html: `<p>Les alertes (service hors ligne, disque presque plein, température) sont
        calculées et affichées localement par l'appareil. Aucun service de notification distant
        n'est utilisé.</p>`,
      },
      {
        h: 'Enfants',
        html: `<p>L'application ne s'adresse pas spécifiquement aux enfants et ne collecte aucune
        donnée les concernant.</p>`,
      },
      {
        h: 'Vos droits',
        html: `<p>N'ayant aucune donnée vous concernant, nous n'avons rien à consulter,
        rectifier, exporter ou supprimer à votre demande. Vos droits au titre du RGPD s'exercent
        directement sur votre appareil, en modifiant ou en supprimant l'application.</p>`,
      },
      {
        h: 'Modifications',
        html: `<p>Toute évolution de cette politique sera publiée sur cette page, avec une
        nouvelle date de mise à jour.</p>`,
      },
    ],
  },
  en: {
    title: 'Privacy policy',
    updated: '2026-08-05',
    sections: [
      {
        h: 'In one paragraph',
        html: `<p>Specula collects no personal data. The app has no account, no server, no
        telemetry and no advertising. It queries the services you host yourself, from your
        device, and sends nothing to the developer or to any third party.</p>`,
      },
      {
        h: 'Data we collect',
        html: `<p>None. We receive neither your email address, nor your IP address, nor the list
        of your services, nor a single usage statistic. There is no Specula server for such
        information to be sent to.</p>`,
      },
      {
        h: 'Data stored on your device',
        html: `<p>Everything you configure stays local:</p>
        <ul>
          <li>the addresses, names and groups of your services;</li>
          <li>your API keys and credentials, kept in the Keychain — never in a backup, never on
          iCloud;</li>
          <li>your outage and notification history, and your display preferences.</li>
        </ul>
        <p>This data is shared between the app and its widgets through an app group on your
        device. Deleting the app erases it.</p>`,
      },
      {
        h: 'Network connections',
        html: `<p>Specula opens two kinds of connection, and nothing else:</p>
        <ul>
          <li><strong>Your services</strong> — at the addresses you entered or imported,
          generally on your local network or through your own VPN. Your API keys are sent to
          those machines, and to them alone, to read their metrics.</li>
          <li><strong>Service logos</strong> — fetched from the public
          <code>cdn.jsdelivr.net</code> CDN (the open-source <em>dashboard-icons</em> project).
          That request carries only the name of the requested logo, never your addresses or your
          keys. You can turn it off: Settings → Icons → Service logos.</li>
        </ul>`,
      },
      {
        h: 'Notifications',
        html: `<p>Alerts (service offline, disk almost full, temperature) are computed and
        displayed locally by the device. No remote notification service is involved.</p>`,
      },
      {
        h: 'Children',
        html: `<p>The app is not directed at children and collects no data concerning them.</p>`,
      },
      {
        h: 'Your rights',
        html: `<p>Since we hold no data about you, we have nothing to disclose, correct, export
        or delete on request. Your rights under the GDPR are exercised directly on your device,
        by changing or deleting the app.</p>`,
      },
      {
        h: 'Changes',
        html: `<p>Any change to this policy will be published on this page, with a new update
        date.</p>`,
      },
    ],
  },
};

export const SUPPORT: Record<'fr' | 'en', LegalDoc> = {
  fr: {
    title: 'Assistance',
    intro:
      'Tableau de bord pour services auto-hébergés, sur iPhone, iPad et Mac.',
    sections: [
      {
        h: 'Nous écrire',
        html: `<p>${MAIL}<br><span class="muted">Réponse sous quelques jours. Précisez la version
        de l'app, l'appareil et, si possible, le service concerné.</span></p>`,
      },
      {
        h: 'Installer Specula',
        html: `<p>Specula est sur l'App&nbsp;Store&nbsp;:
        <a href="${APP_STORE ?? TESTFLIGHT}">voir la fiche</a>. La même app couvre l'iPhone,
        l'iPad et le Mac. Le téléchargement est gratuit, quatre services compris&nbsp;; les
        places suivantes s'achètent depuis l'application.</p>
        <p>Si vous utilisiez la bêta <a href="${TESTFLIGHT}">TestFlight</a>, installez la version
        de l'App&nbsp;Store&nbsp;: vos services et vos clés restent en place, et vous cessez de
        dépendre d'une build qui expire.</p>`,
      },
      {
        h: 'Ajouter vos services',
        html: `<p>Trois façons, proposées au premier lancement et disponibles à tout moment dans
        Réglages&nbsp;:</p>
        <ul>
          <li><strong>Scanner le réseau</strong> — Specula cherche les services visibles autour
          de vous et devine leur type.</li>
          <li><strong>Importer un <code>services.yaml</code></strong> — le format de
          gethomepage. Groupes, adresses et widgets sont repris tels quels.</li>
          <li><strong>Ajouter à la main</strong> — une adresse, un nom.</li>
        </ul>
        <p>Pour essayer sans rien installer&nbsp;: «&nbsp;Explorer la démo d'abord&nbsp;» au
        premier lancement, ou Réglages → Configuration → Données → Démo.</p>`,
      },
      {
        h: 'Une carte affiche « Clé API requise »',
        html: `<p>L'intégration a besoin d'un identifiant pour lire ses métriques. Sélectionnez
        le service, puis Modifier, et saisissez la clé au format indiqué sous le champ (jeton, ou
        <code>utilisateur:motdepasse</code> selon le service).</p>`,
      },
      {
        h: "J'ai importé un services.yaml mais les clés manquent",
        html: `<p>Si votre fichier utilise des variables <code>{{HOMEPAGE_VAR_…}}</code>, elles
        sont résolues par Homepage depuis son fichier <code>.env</code>, auquel Specula n'a pas
        accès. L'app vous signale les services concernés&nbsp;: saisissez leur clé une fois dans
        l'application.</p>`,
      },
      {
        h: 'Un service est marqué hors ligne alors qu’il fonctionne',
        html: `<p>Specula le déclare hors ligne après trois tentatives échouées. Vérifiez que
        l'adresse est joignable depuis l'appareil, telle quelle&nbsp;: un service en
        <code>http://</code> sur le réseau local ne répond plus en déplacement, sauf VPN actif.
        Specula ne gère qu'une adresse par service et n'en change jamais tout seul — si vous
        consultez votre homelab de l'extérieur, saisissez l'adresse qui fonctionne des deux côtés
        (VPN, reverse proxy ou tunnel).</p>`,
      },
      {
        h: 'Une alerte disque revient à chaque lancement',
        html: `<p>C'est un volume plein par nature (archives, montage en lecture seule). Réglages
        → Alertes → Volumes surveillés&nbsp;: décochez-le, il sera ignoré.</p>`,
      },
      {
        h: 'Le bandeau système reste vide',
        html: `<p>CPU, température et RAM proviennent d'une source Glances. Sans elle, le bandeau
        n'a rien à afficher — vous pouvez le masquer dans Réglages → Pictogrammes → Bandeau
        système.</p>`,
      },
      {
        h: 'Où sont stockées mes clés ?',
        html: `<p>Dans le trousseau (Keychain) de votre appareil, et nulle part ailleurs&nbsp;:
        ni dans une sauvegarde, ni sur iCloud. Elles ne sont envoyées qu'aux machines que vous
        avez configurées.</p>`,
      },
      {
        h: 'Changer la langue de l’application',
        html: `<p>Specula existe en français, anglais, espagnol, chinois simplifié et arabe. Elle
        suit la langue du système par défaut&nbsp;; pour en choisir une autre sans changer celle
        de l'appareil&nbsp;: Réglages → Langue. Relancez l'app pour que le changement s'applique
        partout.</p>`,
      },
      { h: 'Compatibilité', html: `<p>iOS et iPadOS 26, macOS 26.</p>` },
    ],
  },
  en: {
    title: 'Support',
    intro: 'A dashboard for self-hosted services, on iPhone, iPad and Mac.',
    sections: [
      {
        h: 'Get in touch',
        html: `<p>${MAIL}<br><span class="muted">Expect a reply within a few days. Please mention
        the app version, the device and, if possible, the service involved.</span></p>`,
      },
      {
        h: 'Install Specula',
        html: `<p>Specula is on the App Store:
        <a href="${APP_STORE ?? TESTFLIGHT}">see the listing</a>. The same app covers iPhone,
        iPad and Mac. Downloading is free, four services included; further slots are bought from
        inside the app.</p>
        <p>If you were running the <a href="${TESTFLIGHT}">TestFlight</a> beta, install the App
        Store build: your services and keys stay put, and you stop depending on a build that
        expires.</p>`,
      },
      {
        h: 'Adding your services',
        html: `<p>Three ways, offered on first launch and available any time in Settings:</p>
        <ul>
          <li><strong>Scan the network</strong> — Specula looks for services advertised around
          you and guesses their type.</li>
          <li><strong>Import a <code>services.yaml</code></strong> — the gethomepage format.
          Groups, addresses and widgets come over as they are.</li>
          <li><strong>Add one by hand</strong> — an address and a name.</li>
        </ul>
        <p>To try it without installing anything: choose “Explore the demo first” on launch, or
        Settings → Configuration → Data → Demo.</p>`,
      },
      {
        h: 'A card says “API key required”',
        html: `<p>The integration needs a credential to read its metrics. Select the service,
        then Edit, and enter the key in the format shown under the field (a token, or
        <code>username:password</code> depending on the service).</p>`,
      },
      {
        h: 'I imported a services.yaml but the keys are missing',
        html: `<p>If your file uses <code>{{HOMEPAGE_VAR_…}}</code> variables, Homepage resolves
        them from its <code>.env</code> file, which Specula has no access to. The app tells you
        which services are affected: enter their key once in the app.</p>`,
      },
      {
        h: 'A service shows as offline even though it works',
        html: `<p>Specula marks a service offline after three failed attempts. Check that the
        address is reachable from the device, exactly as entered: a service on
        <code>http://</code> on your local network stops answering once you leave home, unless a
        VPN is up. Specula handles one address per service and never switches on its own — if you
        check your homelab from outside, enter the address that works from both sides (VPN,
        reverse proxy or tunnel).</p>`,
      },
      {
        h: 'A disk alert comes back on every launch',
        html: `<p>That volume is full by design (archives, a read-only mount). Settings → Alerts
        → Monitored volumes: uncheck it and it will be ignored.</p>`,
      },
      {
        h: 'The system band stays empty',
        html: `<p>CPU, temperature and RAM come from a Glances source. Without one, the band has
        nothing to show — you can hide it under Settings → Icons → System band.</p>`,
      },
      {
        h: 'Where are my keys stored?',
        html: `<p>In your device’s Keychain, and nowhere else: not in a backup, not on iCloud.
        They are only ever sent to the machines you configured.</p>`,
      },
      {
        h: 'Changing the app’s language',
        html: `<p>Specula is available in English, French, Spanish, Simplified Chinese and
        Arabic. It follows the system language by default; to pick another one without changing
        your device: Settings → Language. Relaunch the app for the change to apply
        everywhere.</p>`,
      },
      { h: 'Compatibility', html: `<p>iOS and iPadOS 26, macOS 26.</p>` },
    ],
  },
};
