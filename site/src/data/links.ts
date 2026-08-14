/**
 * Le basculement bêta → App Store tient dans ce fichier.
 *
 * Tant que `APP_STORE` vaut `null`, le site parle de la bêta TestFlight. Dès
 * qu'on y colle l'URL App Store, tout suit au build suivant : le bouton change
 * de lien et de libellé, et la section de clôture cesse d'annoncer une bêta.
 */

/** L'URL App Store, dès que l'app est en vente. Format :
 *  https://apps.apple.com/app/specula/id0000000000 */
export const APP_STORE: string | null = 'https://apps.apple.com/app/specula/id6793012573';

export const TESTFLIGHT = 'https://testflight.apple.com/join/mXBXqMnN';

/** Vrai une fois l'app publiée — pilote les libellés et le lien du bouton. */
export const IS_LIVE = APP_STORE !== null;

export const STORE_URL = APP_STORE ?? TESTFLIGHT;
