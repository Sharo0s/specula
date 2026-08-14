import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

/**
 * Les prix affichés viennent de `StoreKit/Specula.storekit`, pas d'une
 * constante recopiée ici : changer un tarif dans le projet Xcode suffit à
 * corriger le site au build suivant.
 *
 * Le fichier est la configuration StoreKit locale, libellée en euros (fr_FR) —
 * c'est pourquoi les pages annoncent un prix France et renvoient à l'App Store
 * pour la devise du lecteur. App Store Connect reste la source de vérité en cas
 * de désaccord.
 */

// Ce module est empaqueté avant d'être exécuté : `import.meta.url` ne pointe
// plus vers `src/data/`. On part donc du dossier de travail du build — `site/`
// en local comme sur Vercel (Root Directory = site) — et on tolère une
// exécution depuis la racine du dépôt.
const CANDIDATES = [
  resolve(process.cwd(), '../StoreKit/Specula.storekit'),
  resolve(process.cwd(), 'StoreKit/Specula.storekit'),
];
const storekitPath = CANDIDATES.find(existsSync);
if (!storekitPath) {
  throw new Error(
    `StoreKit/Specula.storekit introuvable (cherché : ${CANDIDATES.join(', ')}). ` +
      'Le site lit les prix depuis le projet Xcode ; lancer le build depuis site/.',
  );
}

const STOREKIT = JSON.parse(readFileSync(storekitPath, 'utf8')) as {
  products?: Array<{ productID: string; displayPrice: string }>;
};

const priceOf = (id: string) => {
  const product = STOREKIT.products?.find((p) => p.productID === id);
  if (!product) throw new Error(`Produit StoreKit introuvable : ${id}`);
  return Number(product.displayPrice);
};

export const PRICES = {
  slot: priceOf('com.smalard.specula.slot.one'),
  unlimited: priceOf('com.smalard.specula.unlimited'),
  currency: 'EUR',
};

/** « 0,49 € » dans la langue de la page, le montant restant en euros. */
export const formatPrice = (amount: number, lang: string) =>
  new Intl.NumberFormat(lang === 'zh' ? 'zh-Hans' : lang, {
    style: 'currency',
    currency: PRICES.currency,
  }).format(amount);
