// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Alimente les URL absolues du sitemap, les canoniques et les balises
// hreflang. `.dev` est un domaine à HSTS préchargé : les navigateurs refusent
// le HTTP en clair, l'hébergement doit donc servir en HTTPS.
const SITE = 'https://specula.dev';

export default defineConfig({
  site: SITE,
  // Les cinq langues de l'application. L'anglais reste la langue par défaut —
  // c'est le `x-default` des hreflang, et ce que voient les robots, qui
  // n'annoncent aucune préférence. Un visiteur, lui, est envoyé vers sa langue
  // dès la racine : les `redirects` de `vercel.json` lisent son en-tête
  // `Accept-Language`, sans JavaScript ni fonction serveur.
  //
  // Cette redirection est recalculée à chaque requête et n'est jamais mise en
  // cache (Vercel la sert en `max-age=0, must-revalidate`). Inutile d'essayer
  // de lui ajouter un `Vary` par le bloc `headers` : les règles d'en-têtes ne
  // s'appliquent pas aux réponses de redirection — la CSP elle-même en est
  // absente.
  i18n: {
    defaultLocale: 'en',
    locales: [
      'en',
      'fr',
      'es',
      { path: 'zh', codes: ['zh-Hans', 'zh-CN', 'zh'] },
      'ar',
    ],
    routing: {
      // toutes les langues préfixées, y compris l'anglais : une URL par langue,
      // pas de page qui change de contenu selon l'en-tête Accept-Language
      prefixDefaultLocale: true,
      redirectToDefaultLocale: true,
    },
  },
  integrations: [
    sitemap({
      // la racine n'est qu'une redirection en noindex : elle n'a rien à faire
      // dans le sitemap, où elle ferait doublon avec /en/
      filter: (page) => page !== `${SITE}/`,
      i18n: {
        defaultLocale: 'en',
        locales: { en: 'en', fr: 'fr', es: 'es', zh: 'zh-Hans', ar: 'ar' },
      },
    }),
  ],
  // Feuille externe plutôt qu'inline : sur un site de 351 pages où l'on
  // navigue d'une intégration à l'autre, une feuille mise en cache une fois
  // bat le même CSS recopié dans chaque page.
  build: { inlineStylesheets: 'auto' },
  // Sous la limite (4 Ko par défaut), Astro recopie les scripts dans le HTML —
  // et la CSP à empreinte de vercel.json bloque tout inline non hashé. Limite
  // à zéro : les scripts de la vitrine et de la pilule restent des fichiers
  // /_astro/*.js, couverts par `script-src 'self'` quel que soit leur contenu.
  vite: { build: { assetsInlineLimit: 0 } },
  // Le seul JS client tient en deux petits modules (vitrine, pilule) et un
  // script de thème inline hashé dans la CSP.
  prefetch: false,
});
