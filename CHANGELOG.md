# Changelog

## [1.3.2](https://github.com/Sharo0s/specula/compare/v1.3.1...v1.3.2) (2026-08-17)


### Fonctionnalités

* **ios:** ajoute la page statut et la lecture en cours à la liste ([4dab0ca](https://github.com/Sharo0s/specula/commit/4dab0ca08cda07b0c7bcc83e01bbde0d85e6cb0c))
* **status:** refond le mur de disponibilité et le partage entre plateformes ([74fc91c](https://github.com/Sharo0s/specula/commit/74fc91c7d6d2a7a286d0ae0e1cbb01b730a7f20a))


### Corrections

* **status:** abrège le mois au changement dans les repères du mur ([88444fb](https://github.com/Sharo0s/specula/commit/88444fba76d5fa8a7e334cbf137d66260da68ffb))


### Divers

* **release:** passe au build 30 et force la version 1.3.2 ([9650e71](https://github.com/Sharo0s/specula/commit/9650e7128ed24383dfad5394ee8d2fef98fa2174))

## [1.3.1](https://github.com/Sharo0s/specula/compare/v1.3.0...v1.3.1) (2026-08-15)


### Corrections

* **demo:** remplace la seedbox par un VPS applicatif ([d75224a](https://github.com/Sharo0s/specula/commit/d75224a38c574559c183dd21c2cb78921bca1daa))
* **demo:** retire quatre services du catalogue de démonstration ([aa8fb73](https://github.com/Sharo0s/specula/commit/aa8fb7344036b1ef32c5abae4cf59b358f1d0e55))
* **ios:** retire le décompte d'intégrations invérifiable ([69d583d](https://github.com/Sharo0s/specula/commit/69d583df113f87c45d814d74e7a51e03de6ede0b))
* **site:** rétablit l'envoi des mesures derrière le proxy PostHog ([b673e06](https://github.com/Sharo0s/specula/commit/b673e06dca589d5f03ae9dc97bc24106364c6171))
* **theme:** rétablit la bascule clair/sombre et l'ajoute sur iOS ([f9b2bff](https://github.com/Sharo0s/specula/commit/f9b2bff9f94119ce24193248c7f2ae88e4e67c24))

## [1.3.0](https://github.com/Sharo0s/specula/compare/v1.2.0...v1.3.0) (2026-08-13)


### Fonctionnalités

* **billing:** conserve les places achetées d'un appareil à l'autre ([#14](https://github.com/Sharo0s/specula/issues/14)) ([293ceae](https://github.com/Sharo0s/specula/commit/293ceaede54c593609962d5037950d0de09fd601))
* **billing:** quatre services offerts, les suivants à l'unité ([#12](https://github.com/Sharo0s/specula/issues/12)) ([bbe3031](https://github.com/Sharo0s/specula/commit/bbe30313b25256069aeda068752625a2f6b04711))

## [1.2.0](https://github.com/Sharo0s/specula/compare/v1.1.1...v1.2.0) (2026-08-11)


### Fonctionnalités

* **ios:** aligne les actions du détail sur celles du Mac ([46f1b78](https://github.com/Sharo0s/specula/commit/46f1b78810a11816a3740e236e20ed41dda05ebc))
* **watch:** retire l'application et les complications watchOS ([dad22f4](https://github.com/Sharo0s/specula/commit/dad22f4e3b25f7fc67acfaab1634ee71bfcda6d4))

## [1.1.1](https://github.com/Sharo0s/specula/compare/v1.1.0...v1.1.1) (2026-08-05)


### Corrections

* **keychain:** passe au trousseau protégé et dérive le service du préfixe ([8ead137](https://github.com/Sharo0s/specula/commit/8ead137eda6ad21bf438017bf9775c7b0dd9fce6))
* **keychain:** reprend l'ancien trousseau en une seule passe énumérée ([73e7b13](https://github.com/Sharo0s/specula/commit/73e7b13c252ed8a5b86650b0ddeb9183203ef71c))

## [1.1.0](https://github.com/Sharo0s/specula/compare/v1.0.0...v1.1.0) (2026-08-04)


### Fonctionnalités

* **i18n:** ajoute le chinois simplifié et l'arabe ([3a23b01](https://github.com/Sharo0s/specula/commit/3a23b018b1c793532c22f4761484b1c9ddc3630c))
* **i18n:** complète l'anglais et l'espagnol ([f516a2c](https://github.com/Sharo0s/specula/commit/f516a2cf933ea33fe5e3e390e63803372ca37a36))
* **i18n:** traduit les libellés de l'export sans clés ([a2495e6](https://github.com/Sharo0s/specula/commit/a2495e69ac14c7c7f09b58f28d7e13a8e38a6cbf))
* **yaml:** exporte services.yaml dans un fichier ([3caad75](https://github.com/Sharo0s/specula/commit/3caad75ef769e3accc1713138d325e6bb02d7f53))
* **yaml:** propose l'export de services.yaml sans les clés API ([b3382d3](https://github.com/Sharo0s/specula/commit/b3382d3f1f1a101d66271d72c935b19b8f7a9ce8))


### Corrections

* **demo:** retire les hôtes personnels du catalogue de démonstration ([998d6a8](https://github.com/Sharo0s/specula/commit/998d6a81e9516493412362ad43f6defdc19aa8ab))
* **http:** limite l'acceptation des certificats auto-signés au réseau local ([f050a2e](https://github.com/Sharo0s/specula/commit/f050a2eae7b5e11901ad5db4c861ea872ad6a85c))
* **i18n:** active l'extraction des chaînes localisées ([168d326](https://github.com/Sharo0s/specula/commit/168d3269b221acddfd337436dd14cb972d943a13))
* **i18n:** bascule la langue de repli sur l'anglais ([bc79991](https://github.com/Sharo0s/specula/commit/bc79991def8a07d9ad7c6b48a437fcb266832c9a))
* **i18n:** régénère les Info.plist avec l'anglais en langue de repli ([06dc974](https://github.com/Sharo0s/specula/commit/06dc97423b15831c60df0c74af7457011c46f0d9))
* **integrations:** ne fait plus planter l'app sur une adresse malformée ([7485764](https://github.com/Sharo0s/specula/commit/74857644143bd509d509574b213ce6a1f02676fd))
* **keychain:** sort les clés API du fichier de configuration ([e90b23e](https://github.com/Sharo0s/specula/commit/e90b23e47a95244b3678433a91054c3da7b0aee9))
* **live:** ne déclare plus une panne par service quand plus rien ne répond ([6e0b78d](https://github.com/Sharo0s/specula/commit/6e0b78d93bff008382a669b3932fe77fbd978841))
* **macos:** empêche le retour à la ligne des segments de langue ([2a07c68](https://github.com/Sharo0s/specula/commit/2a07c68096a994b4133adae938c5294f9c698fe5))
* **notifs:** aligne l'alerte hors ligne sur les 5 minutes annoncées ([3fa7a97](https://github.com/Sharo0s/specula/commit/3fa7a97d62efaf578cb6773ae30e59eaf5b75309))


### Refactorisations

* **live:** supprime la bascule Tailscale ([5cb5737](https://github.com/Sharo0s/specula/commit/5cb57370e058ceec3059fa9c6d7b50f3fa794e09))
