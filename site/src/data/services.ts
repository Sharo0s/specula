/**
 * Nom d'affichage et famille de chaque intégration.
 *
 * Les faits (métriques lues, points d'API appelés, identifiant demandé) ne
 * vivent pas ici : ils sont extraits des sources Swift dans
 * `integrations.json` par `scripts/extract-integrations.py`. Ce fichier ne
 * porte que ce que le code ne dit pas — comment le service s'écrit et à quelle
 * famille il appartient.
 */

export type Family =
  | 'media'
  | 'downloads'
  | 'network'
  | 'infra'
  | 'home'
  | 'monitoring'
  | 'tools';

export interface ServiceMeta {
  name: string;
  family: Family;
  /** Site officiel du projet — lien sortant de la page d'intégration. */
  site: string;
}

export const SERVICES: Record<string, ServiceMeta> = {
  // — médias —
  jellyfin: { name: 'Jellyfin', family: 'media', site: 'https://jellyfin.org' },
  plex: { name: 'Plex', family: 'media', site: 'https://www.plex.tv' },
  tautulli: { name: 'Tautulli', family: 'media', site: 'https://tautulli.com' },
  overseerr: { name: 'Overseerr', family: 'media', site: 'https://overseerr.dev' },
  immich: { name: 'Immich', family: 'media', site: 'https://immich.app' },
  photoprism: { name: 'PhotoPrism', family: 'media', site: 'https://www.photoprism.app' },
  komga: { name: 'Komga', family: 'media', site: 'https://komga.org' },
  kavita: { name: 'Kavita', family: 'media', site: 'https://www.kavitareader.com' },
  audiobookshelf: { name: 'Audiobookshelf', family: 'media', site: 'https://www.audiobookshelf.org' },
  navidrome: { name: 'Navidrome', family: 'media', site: 'https://www.navidrome.org' },
  peertube: { name: 'PeerTube', family: 'media', site: 'https://joinpeertube.org' },

  // — téléchargement et bibliothèques —
  radarr: { name: 'Radarr', family: 'downloads', site: 'https://radarr.video' },
  sonarr: { name: 'Sonarr', family: 'downloads', site: 'https://sonarr.tv' },
  lidarr: { name: 'Lidarr', family: 'downloads', site: 'https://lidarr.audio' },
  readarr: { name: 'Readarr', family: 'downloads', site: 'https://readarr.com' },
  bazarr: { name: 'Bazarr', family: 'downloads', site: 'https://www.bazarr.media' },
  prowlarr: { name: 'Prowlarr', family: 'downloads', site: 'https://prowlarr.com' },
  jackett: { name: 'Jackett', family: 'downloads', site: 'https://github.com/Jackett/Jackett' },
  transmission: { name: 'Transmission', family: 'downloads', site: 'https://transmissionbt.com' },
  qbittorrent: { name: 'qBittorrent', family: 'downloads', site: 'https://www.qbittorrent.org' },
  deluge: { name: 'Deluge', family: 'downloads', site: 'https://deluge-torrent.org' },
  sabnzbd: { name: 'SABnzbd', family: 'downloads', site: 'https://sabnzbd.org' },

  // — réseau —
  adguard: { name: 'AdGuard Home', family: 'network', site: 'https://adguard.com/adguard-home/overview.html' },
  pihole: { name: 'Pi-hole', family: 'network', site: 'https://pi-hole.net' },
  unifi: { name: 'UniFi Controller', family: 'network', site: 'https://ui.com' },
  traefik: { name: 'Traefik', family: 'network', site: 'https://traefik.io' },
  npm: { name: 'Nginx Proxy Manager', family: 'network', site: 'https://nginxproxymanager.com' },
  wgeasy: { name: 'WG-Easy', family: 'network', site: 'https://github.com/wg-easy/wg-easy' },
  speedtest: { name: 'Speedtest Tracker', family: 'network', site: 'https://speedtest-tracker.dev' },

  // — machines et stockage —
  proxmox: { name: 'Proxmox VE', family: 'infra', site: 'https://www.proxmox.com' },
  portainer: { name: 'Portainer', family: 'infra', site: 'https://www.portainer.io' },
  truenas: { name: 'TrueNAS', family: 'infra', site: 'https://www.truenas.com' },
  omv: { name: 'OpenMediaVault', family: 'infra', site: 'https://www.openmediavault.org' },
  nextcloud: { name: 'Nextcloud', family: 'infra', site: 'https://nextcloud.com' },
  filebrowser: { name: 'FileBrowser', family: 'infra', site: 'https://filebrowser.org' },
  syncthing: { name: 'Syncthing', family: 'infra', site: 'https://syncthing.net' },
  scrutiny: { name: 'Scrutiny', family: 'infra', site: 'https://github.com/AnalogJ/scrutiny' },

  // — domotique —
  homeassistant: { name: 'Home Assistant', family: 'home', site: 'https://www.home-assistant.io' },
  frigate: { name: 'Frigate', family: 'home', site: 'https://frigate.video' },
  esphome: { name: 'ESPHome', family: 'home', site: 'https://esphome.io' },
  octoprint: { name: 'OctoPrint', family: 'home', site: 'https://octoprint.org' },

  // — surveillance —
  grafana: { name: 'Grafana', family: 'monitoring', site: 'https://grafana.com' },
  netdata: { name: 'Netdata', family: 'monitoring', site: 'https://www.netdata.cloud' },
  glances: { name: 'Glances', family: 'monitoring', site: 'https://nicolargo.github.io/glances/' },
  uptimekuma: { name: 'Uptime Kuma', family: 'monitoring', site: 'https://uptime.kuma.pet' },
  healthchecks: { name: 'Healthchecks', family: 'monitoring', site: 'https://healthchecks.io' },
  gotify: { name: 'Gotify', family: 'monitoring', site: 'https://gotify.net' },
  changedetection: { name: 'changedetection.io', family: 'monitoring', site: 'https://changedetection.io' },

  // — outils —
  vaultwarden: { name: 'Vaultwarden', family: 'tools', site: 'https://github.com/dani-garcia/vaultwarden' },
  paperless: { name: 'Paperless-ngx', family: 'tools', site: 'https://docs.paperless-ngx.com' },
  authentik: { name: 'authentik', family: 'tools', site: 'https://goauthentik.io' },
  gitea: { name: 'Gitea', family: 'tools', site: 'https://about.gitea.com' },
  gitlab: { name: 'GitLab', family: 'tools', site: 'https://about.gitlab.com' },
  n8n: { name: 'n8n', family: 'tools', site: 'https://n8n.io' },
  bookstack: { name: 'BookStack', family: 'tools', site: 'https://www.bookstackapp.com' },
  miniflux: { name: 'Miniflux', family: 'tools', site: 'https://miniflux.app' },
  linkding: { name: 'linkding', family: 'tools', site: 'https://linkding.link' },
  mealie: { name: 'Mealie', family: 'tools', site: 'https://mealie.io' },
  grocy: { name: 'Grocy', family: 'tools', site: 'https://grocy.info' },
  fireflyiii: { name: 'Firefly III', family: 'tools', site: 'https://www.firefly-iii.org' },
  wordpress: { name: 'WordPress', family: 'tools', site: 'https://wordpress.org' },
  ghost: { name: 'Ghost', family: 'tools', site: 'https://ghost.org' },
  matomo: { name: 'Matomo', family: 'tools', site: 'https://matomo.org' },
  ollama: { name: 'Ollama', family: 'tools', site: 'https://ollama.com' },
};

export const FAMILY_ORDER: Family[] = [
  'media',
  'downloads',
  'network',
  'infra',
  'home',
  'monitoring',
  'tools',
];
