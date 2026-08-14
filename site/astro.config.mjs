// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Alimente les URL absolues du sitemap, les canoniques et les balises
// hreflang. `.dev` est un domaine à HSTS préchargé : les navigateurs refusent
// le HTTP en clair, l'hébergement doit donc servir en HTTPS.
const SITE = 'https://specula.dev';

export default defineConfig({
  site: SITE,
  // Les cinq langues de l'application. L'anglais mène : le trafic organique
  // visé (r/selfhosted, Hacker News, lobste.rs) est anglophone.
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
  // Aucun JS client : le site est du HTML et du CSS.
  prefetch: false,
});
