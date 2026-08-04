# Changelog

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
