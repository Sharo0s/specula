import { en } from './strings/en';
import { fr } from './strings/fr';
import { es } from './strings/es';
import { zh } from './strings/zh';
import { ar } from './strings/ar';

/** Les cinq langues de l'application, dans l'ordre du sélecteur. */
export const LOCALES = ['en', 'fr', 'es', 'zh', 'ar'] as const;
export type Locale = (typeof LOCALES)[number];

/** Le code BCP-47 réel — l'URL dit « zh », l'attribut lang dit « zh-Hans ». */
export const BCP47: Record<Locale, string> = {
  en: 'en',
  fr: 'fr',
  es: 'es',
  zh: 'zh-Hans',
  ar: 'ar',
};

export const LOCALE_NAMES: Record<Locale, string> = {
  en: 'English',
  fr: 'Français',
  es: 'Español',
  zh: '简体中文',
  ar: 'العربية',
};

export const dir = (lang: Locale) => (lang === 'ar' ? 'rtl' : 'ltr');

const DICTS = { en, fr, es, zh, ar } as const;
type Dict = typeof en;

/**
 * Traduction avec repli sur l'anglais : une langue peut être incomplète sans
 * casser le build ni laisser un trou dans la page.
 */
export function useTranslations(lang: Locale) {
  const dict = DICTS[lang] as Partial<Dict>;
  return function t<K extends keyof Dict>(key: K): Dict[K] {
    return (dict[key] ?? en[key]) as Dict[K];
  };
}

/** Préfixe d'URL d'une langue : `/fr/prix` etc. */
export const path = (lang: Locale, rest = '') => `/${lang}/${rest}`.replace(/\/+$/, '/');

export const isLocale = (value: string): value is Locale =>
  (LOCALES as readonly string[]).includes(value);
