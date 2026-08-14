// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Le domaine n'est pas encore acheté — cette valeur alimente les URL absolues
// du sitemap et des balises hreflang, et doit être corrigée avant la mise en
// ligne (et dans vercel.json si l'hébergement en dépend).
const SITE = 'https://specula.app';

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
