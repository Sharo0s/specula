# Métadonnées App Store

Le texte des fiches App Store, versionné. Il n'existait jusqu'ici que dans
App Store Connect — un endroit qu'on ne peut ni relire côte à côte, ni comparer
d'une langue à l'autre, ni retrouver après une modification.

Un dossier par langue de fiche, nommé par le code d'App Store Connect :

```
fr-FR/    en-US/    es-ES/    zh-Hans/    ar-SA/
  description.txt              le corps de la fiche      4 000 caractères max
  keywords.txt                 séparés par des virgules,   100 caractères max
  subtitle.txt                 une ligne,                    30 caractères max
  release_notes.txt            les nouveautés,            4 000 caractères max
  testflight_description.txt   la fiche vue par les testeurs
  marketing_url.txt
  support_url.txt

zh-Hans/name.txt               le nom de l'app,              30 caractères max
review_notes.txt               les notes au vérificateur, hors arborescence de
                               langue : le champ est unique et se lit en anglais
```

Ces fichiers ne sont pas téléversés automatiquement : ils se copient à la main
dans App Store Connect. Le dépôt sert de source, pas de pipeline.

Trois destinations différentes, à ne pas confondre :

- `description`, `keywords`, `marketing_url`, `support_url` → la page de la
  **version**, plateforme par plateforme ;
- `release_notes` → « Nouveautés de cette version », sur la même page mais
  réécrit à chaque version, là où les précédents se reconduisent tels quels ;
- `subtitle` et `name` → **Informations sur l'app**, publiés avec la prochaine
  version soumise, quelle que soit la plateforme ;
- `testflight_description` → **TestFlight ▸ Informations de test**, visible des
  seuls testeurs et sans rapport avec la fiche publique ;
- `review_notes` → **Informations pour la vérification ▸ Notes**, lu par le seul
  vérificateur d'Apple et jamais publié.

## Les notes au vérificateur

Elles ne sont pas facultatives ici. Specula interroge des services d'un réseau
privé : le vérificateur n'en a aucun, et voit donc une app dont rien ne répond.
Sans explication, la conclusion est la guideline 2.1 — « nous n'avons pas pu
évaluer l'app ».

Le mode démo est ce qui rend l'app évaluable, et les notes servent à le dire :
qu'il s'ouvre au premier lancement, qu'il ne demande ni compte ni adresse, et
que toutes les surfaces y fonctionnent, achats intégrés compris.

## Le nom chinois

Les quatre autres marchés s'appellent `Specula`. Le chinois simplifié ne le peut
pas : au moment de créer la localisation, App Store Connect renvoie

```
STATE_ERROR.DUPLICATE_NAME.DIFFERENT_ACCOUNT
You cannot add this localization because the app name is already being used
by another app.
```

Un autre développeur détient `Specula` sur ce marché. Le contrôle ne se
déclenche qu'à la **création** d'une localisation, ce qui explique que les
versions antérieures — sans fiche chinoise — soient passées sans rien signaler.

D'où `zh-Hans/name.txt`. Le nom localisé ne vaut que pour la Chine ; ne pas le
propager aux autres langues, et ne pas le retirer en croyant à une coquille.

## Ce qui n'est pas ici

Le texte promotionnel, les nouveautés de version et le « à tester » de
TestFlight : ils changent à chaque livraison, et les recopier ici les ferait
diverger sans qu'on s'en aperçoive. Les captures d'écran non plus — Apple
réutilise celles de la langue principale pour toutes les autres.

`testflight_description.txt` fait exception parce qu'il ne bouge pas d'un build
à l'autre : il décrit l'app, pas la livraison. Ne rien y écrire de propre à une
version.

## Apple Watch

Les cibles watchOS ont été supprimées en 1.2.0. Aucun texte ne doit plus
promettre d'app ou de complications Apple Watch — c'est précisément l'écart qui
a fait garder la mention dans la description TestFlight jusqu'au 15 août 2026,
longtemps après la disparition du code.

## Les prix

**Seul le français annonce des montants.** La fiche française sert un marché en
euros ; les autres langues renvoient à l'App Store, qui affiche la monnaie du
lecteur. Une fiche chinoise qui promet « 0,49 € » ment à qui paiera en yuans.

Si un jour le français devient lui aussi multi-marché, retirer les montants de
`fr-FR/description.txt` de la même façon.

## Langues

L'app parle français, anglais, espagnol, chinois simplifié et arabe. Les fiches
App Store doivent suivre cette liste — ni plus (une fiche allemande promettrait
une langue que l'app n'a pas), ni moins.

`en-CA` reprend `en-US` tel quel.

## Cohérence avec l'app et le site

Les descriptions reprennent le vocabulaire de `Resources/Localizable.xcstrings`
— *Demo* / 演示, *Estado* / 状态, *Alertas* / 提醒 — pour qu'une fiche ne nomme
pas autrement ce que l'interface affiche.

Les URL pointent vers `specula.dev`, dans la langue de la fiche. Attention : les
pages `support` et `privacy` n'existent qu'en français et en anglais ; les
autres langues servent la version anglaise en le disant. C'est délibéré, et
Apple l'accepte.
