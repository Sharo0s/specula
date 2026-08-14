# Site de Specula

Site vitrine statique : Astro, aucun JavaScript envoyé au navigateur, aucun
service tiers. Cinq langues (`en`, `fr`, `es`, `zh`, `ar`), 351 pages générées.

```bash
pnpm install
pnpm dev        # http://localhost:4321
pnpm build      # dist/
pnpm preview
```

## Le catalogue d'intégrations

Les pages `/[lang]/integrations/[slug]/` ne sont pas écrites à la main : elles
sont générées à partir des sources Swift de l'app.

```bash
pnpm catalog    # relit ../Shared/** et réécrit src/data/integrations.json
```

Le script [`scripts/extract-integrations.py`](scripts/extract-integrations.py)
extrait, pour chaque `IntegrationType` :

- les métriques réellement lues (les libellés du switch `metricsOne` /
  `metricsMore`) ;
- les points d'API appelés ;
- l'identifiant demandé, avec ses traductions reprises telles quelles de
  `Resources/Localizable.xcstrings` — le site et l'app disent le même mot.

**À relancer après toute modification de `Shared/Data/Integrations.swift` ou de
l'énumération `IntegrationType`.** Sans ça, le site annonce des métriques que
l'app ne lit plus.

Ce que le code ne dit pas — le nom d'affichage du service, sa famille, son site
officiel — vit dans [`src/data/services.ts`](src/data/services.ts). Ajouter une
intégration à l'app demande donc une ligne ici.

## Traductions

Un fichier par langue dans `src/i18n/strings/`, l'anglais faisant foi : une clé
absente ailleurs retombe sur l'anglais plutôt que de laisser un trou. Les
libellés de métriques, eux, sont traduits dans `src/i18n/metrics.ts` (leur
source est le français, langue des sources Swift).

Les pages `privacy` et `support` n'existent qu'en français et en anglais
(`src/data/legal.ts`) : les autres langues servent la version anglaise et le
disent. Un texte juridique traduit sans relecture ne vaut pas le texte original.

## Déploiement

Hébergement prévu : Vercel, avec **Root Directory = `site`** dans les réglages
du projet (le dépôt contient l'app iOS à sa racine). `vercel.json` fixe la
redirection de `/` vers `/en/`, le cache des polices et une CSP qui interdit
tout script.

### Avant la mise en ligne

- **Les captures sont en français** alors que le site parle cinq langues.
  L'app étant localisée, il faut les refaire par langue (simulateur en `es`,
  `zh-Hans`, `ar`) et les ranger en `public/screenshots/<lang>/`.
- **L'image Open Graph** (`public/og.png`) est composée à part : la source est
  `scripts/og.html`, rendue en 1200×630 par Chrome sans interface. Refaire
  l'image après un changement de discours ou de captures :

  ```bash
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless \
    --allow-file-access-from-files --force-device-scale-factor=2 \
    --screenshot=/tmp/og.png --window-size=1200,630 file://$PWD/scripts/og.html
  sips --resampleWidth 1200 /tmp/og.png --out public/og.png
  ```
