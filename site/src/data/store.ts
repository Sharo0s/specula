/**
 * La version réellement installable depuis l'App Store.
 *
 * Le CHANGELOG avance au merge, l'App Store à la validation d'Apple : entre
 * les deux, le dépôt annonce une version que personne ne peut installer. Le
 * journal du site ne montre donc que ce qu'Apple sert vraiment.
 *
 * L'appel se fait au build. S'il échoue — pas de réseau, API muette — on
 * retombe sur LAST_KNOWN : le journal montre alors un peu moins que la
 * réalité, jamais plus.
 *
 * La fraîcheur suit les déploiements : une version validée par Apple
 * n'apparaît qu'au build suivant. Un Deploy Hook Vercel appelé par un cron
 * quotidien évite d'attendre le prochain push.
 */

const APP_ID = '6793012573';

/**
 * Dernière version constatée en ligne, repli quand l'API ne répond pas.
 * À remonter de temps en temps — un repli trop vieux ne casse rien, il
 * ampute juste le journal quand Apple ne répond pas.
 */
const LAST_KNOWN = '1.3.1';

/**
 * Deux fiches derrière un seul identifiant : l'app iOS et l'app macOS avancent
 * chacune à son rythme, et Apple peut valider l'une sans l'autre. On interroge
 * donc les deux entités et on retient la version la plus haute — le journal
 * annonce ce qui est installable quelque part, pas le plus petit dénominateur.
 *
 * Le storefront américain est le seul à répondre pour cet identifiant : les
 * autres pays renvoient `resultCount: 0` tant que l'app n'y est pas
 * distribuée. Sans paramètre `country`, l'API interroge les États-Unis.
 */
const ENTITES = ['software', 'macSoftware'] as const;
const lookup = (entite: string) =>
  `https://itunes.apple.com/lookup?id=${APP_ID}&entity=${entite}`;

/** Compare deux versions numériques (« 1.3.10 » > « 1.3.9 »). */
export function compareVersions(a: string, b: string): number {
  const pa = a.split('.').map(Number);
  const pb = b.split('.').map(Number);
  for (let i = 0; i < Math.max(pa.length, pb.length); i += 1) {
    const diff = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (diff !== 0) return diff;
  }
  return 0;
}

/**
 * Une seule interrogation par build : la page est rendue cinq fois (une par
 * langue) et l'endpoint /store-version.json une sixième, mais tous partagent
 * la même promesse.
 */
let enCours: Promise<string> | null = null;

export function storeVersion(): Promise<string> {
  enCours ??= interroge();
  return enCours;
}

async function interroge(): Promise<string> {
  const versions = (await Promise.all(ENTITES.map(lit))).filter(
    (v): v is string => v !== null,
  );
  if (versions.length === 0) {
    console.warn(`[changelog] version App Store indisponible, repli sur ${LAST_KNOWN}`);
    return LAST_KNOWN;
  }
  return versions.sort(compareVersions).at(-1)!;
}

/** Une plateforme muette n'en condamne pas une autre : elle rend `null`. */
async function lit(entite: string): Promise<string | null> {
  try {
    const response = await fetch(lookup(entite), { signal: AbortSignal.timeout(5000) });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const version = (await response.json())?.results?.[0]?.version;
    if (typeof version !== 'string' || !/^\d+(\.\d+)*$/.test(version)) {
      throw new Error(`version inattendue : ${JSON.stringify(version)}`);
    }
    return version;
  } catch (error) {
    console.warn(
      `[changelog] ${entite} : ${error instanceof Error ? error.message : error}`,
    );
    return null;
  }
}
