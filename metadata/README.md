# Métadonnées App Store

Le texte des fiches App Store, versionné. Il n'existait jusqu'ici que dans
App Store Connect — un endroit qu'on ne peut ni relire côte à côte, ni comparer
d'une langue à l'autre, ni retrouver après une modification.

Un dossier par langue de fiche, nommé par le code d'App Store Connect :

```
fr-FR/    en-US/    es-ES/    zh-Hans/    ar-SA/
  description.txt      le corps de la fiche      4 000 caractères max
  keywords.txt         séparés par des virgules,   100 caractères max
  subtitle.txt         une ligne,                    30 caractères max
  marketing_url.txt
  support_url.txt

zh-Hans/name.txt       le nom de l'app,              30 caractères max
```

Ces fichiers ne sont pas téléversés automatiquement : ils se copient à la main
dans App Store Connect. Le dépôt sert de source, pas de pipeline.

Attention : `subtitle.txt` et `name.txt` se collent dans **Informations sur
l'app**, pas dans la page de version. Ils se publient avec la prochaine version
soumise, quelle que soit la plateforme.

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

Le texte promotionnel et les nouveautés de version : ils changent à chaque
livraison, et les recopier ici les ferait diverger sans qu'on s'en aperçoive.
Les captures d'écran non plus — Apple réutilise celles de la langue principale
pour toutes les autres.

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
