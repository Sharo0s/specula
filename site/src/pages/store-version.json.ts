import type { APIRoute } from 'astro';
import { storeVersion } from '../data/store';

/**
 * La version App Store retenue au moment du build, en clair.
 *
 * Le workflow `store-version.yml` la compare chaque jour à ce qu'Apple sert
 * vraiment : si les deux divergent, une version validée depuis le dernier
 * déploiement n'est pas encore dans le journal, et le Deploy Hook reconstruit
 * le site. Sans ce fichier il faudrait gratter le HTML de la page.
 */
export const GET: APIRoute = async () =>
  new Response(JSON.stringify({ version: await storeVersion() }), {
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
