/**
 * Les monogrammes colorés : le repli natif de l'app quand les logos distants
 * sont coupés. Seize paires encre/fond calées sur les couleurs des projets ;
 * le catalogue les recycle en boucle pour ses 65 cartes, comme le mockup.
 */
export const PALETTE: [name: string, color: string, bg: string][] = [
  ['Jellyfin', '#7b4dc9', 'rgba(146, 107, 222, 0.14)'],
  ['Proxmox VE', '#c2691a', 'rgba(230, 138, 60, 0.14)'],
  ['Home Assistant', '#1c7f9e', 'rgba(64, 163, 199, 0.12)'],
  ['AdGuard Home', '#3d8b3d', 'rgba(104, 190, 104, 0.14)'],
  ['Immich', '#b23a6e', 'rgba(199, 64, 120, 0.1)'],
  ['Nextcloud', '#2f5ec0', 'rgba(64, 110, 199, 0.1)'],
  ['UniFi', '#4a63c8', 'rgba(107, 140, 222, 0.12)'],
  ['Portainer', '#17798b', 'rgba(38, 166, 187, 0.12)'],
  ['Vaultwarden', '#25795f', 'rgba(53, 160, 128, 0.12)'],
  ['Paperless-ngx', '#6b7015', 'rgba(160, 166, 53, 0.14)'],
  ['Plex', '#96700f', 'rgba(199, 148, 38, 0.14)'],
  ['Grafana', '#c05e17', 'rgba(230, 120, 38, 0.12)'],
  ['Pi-hole', '#b23535', 'rgba(214, 68, 68, 0.1)'],
  ['TrueNAS', '#2a5ea8', 'rgba(56, 120, 214, 0.1)'],
  ['Uptime Kuma', '#217a44', 'rgba(60, 199, 120, 0.12)'],
  ['Traefik', '#177a6d', 'rgba(38, 187, 166, 0.12)'],
];

/** Paire encre/fond d'un monogramme, par index — la boucle du mockup. */
export const badgePalette = (i: number): [string, string] => {
  const [, color, bg] = PALETTE[i % PALETTE.length];
  return [color, bg];
};
