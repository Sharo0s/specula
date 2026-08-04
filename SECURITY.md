# Politique de sécurité

## Versions suivies

Seule la dernière version publiée reçoit des correctifs.

## Signaler une faille

**Ne pas ouvrir d'issue publique.** Passe par le signalement privé de GitHub :
onglet **Security** du dépôt → **Report a vulnerability**. La discussion reste
entre toi et le mainteneur jusqu'au correctif.

Réponse sous une semaine environ. Le projet est tenu par une seule personne sur
son temps libre : pas de prime, mais un crédit dans les notes de version si tu
le souhaites.

## Surface concernée

Specula est une app locale, sans backend : elle interroge les services de
l'utilisateur et n'expose aucun serveur. Sont donc particulièrement pertinents :

- fuite d'identifiants hors du trousseau — journaux, `UserDefaults`, YAML
  exporté, instantané de l'App Group ;
- validation TLS : l'app accepte les certificats auto-signés pour les hôtes du
  homelab, tout élargissement involontaire de cette tolérance est une faille ;
- traitement d'un `services.yaml` importé, ou d'une réponse hostile d'un service
  interrogé ;
- données atteignables par les extensions widgets et complications via l'App
  Group.

Hors périmètre : le fait que l'app joigne des services en HTTP simple sur le
réseau local, et l'usage du CDN public d'icônes — deux choix documentés dans le
[README](README.md).
