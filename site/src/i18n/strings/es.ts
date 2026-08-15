export const es = {
  // — meta —
  'site.description':
    'Panel nativo para tus servicios autoalojados, en iPhone, iPad y Mac. Lee sus métricas reales, detecta las caídas y alimenta los widgets. Sin cuenta, sin servidor, sin telemetría.',

  // — navegación —
  'nav.integrations': 'Integraciones',
  'nav.pricing': 'Precio',
  'nav.privacy': 'Privacidad',
  'nav.changelog': 'Novedades',
  'theme.toggle': 'Cambiar de tema',
  'nav.cta': 'Unirse a la beta',
  'nav.cta.live': 'Descargar',

  // — portada —
  'hero.title': 'Tu homelab en la mano',
  'hero.title.accent': 'en la mano',
  'hero.lede':
    'Un vistazo al despertar y lo sabes todo: qué funciona, qué va lento y qué se cayó esta noche. En iPhone, iPad y Mac.',
  'hero.proof.privacy': 'Sin cuenta, sin servidor, sin telemetría.',
  'hero.proof.platforms': 'iPhone, iPad y Mac, en nativo.',
  'hero.cta.primary': 'Unirse a la beta de TestFlight',
  'hero.cta.secondary': 'Ver las integraciones',

  // — capturas —
  'shot.macos.alt':
    'Specula en macOS: las fuentes y los grupos a un lado, los servicios en tarjetas con sus métricas en el centro y el detalle de un servicio al lado.',
  'shot.ios.alt':
    'Specula en iPhone: la lista de servicios por grupo con la latencia de cada uno, la banda de sistema arriba y Komga marcado fuera de línea.',
  'shot.ipados.alt':
    'Specula en iPad: los servicios, grupo a grupo, en cuadrícula, cada uno con las métricas leídas por su API.',

  // — funciones —
  'features.eyebrow': 'Qué hace',
  'features.title': 'Un ping dice «responde». Specula dice qué.',

  'features.metrics.title': 'Métricas reales, por la API de cada servicio',
  'features.metrics.body':
    'Specula habla el idioma de cada servicio: /control/stats para AdGuard, la API de clúster de Proxmox, las estadísticas del NAS. Ves cifras que significan algo, no un punto verde.',

  'features.outage.title': 'Detección de caídas, no alertas por cada hipo',
  'features.outage.body':
    'Hacen falta tres intentos fallidos para marcar un servicio como caído: un wifi inestable no despierta a nadie. Después llegan la notificación, la Live Activity y un muro de estado que guarda treinta días y calcula la disponibilidad real.',

  'features.surfaces.title': 'En todas tus pantallas',
  'features.surfaces.body':
    'Widgets de pantalla de inicio y de bloqueo alimentados por el estado real, acceso desde la barra de menús del Mac, Live Activity durante una caída. Una app nativa, no una página web dentro de una carcasa.',

  'features.demo.title': 'Un modo demo que no te pide nada',
  'features.demo.body':
    'La app arranca en modo demo la primera vez: un homelab completo, métricas creíbles y una caída guionizada. Juzgas la app antes de darle una sola dirección.',

  // — puesta en marcha —
  'surface.home': 'Pantalla de inicio',
  'surface.lock': 'Pantalla bloqueada',
  'surface.menubar': 'Barra de menús',
  'feature.uptime': 'Treinta días de disponibilidad',
  'feature.demo.chip': 'Modo demo',

  'setup.eyebrow': 'Primeros pasos',
  'setup.title': 'Tres maneras de empezar',
  'setup.scan.title': 'Escanear la red',
  'setup.scan.body':
    'Specula escucha el Bonjour de tu red, encuentra lo que se anuncia y adivina el tipo de cada servicio.',
  'setup.yaml.title': 'Importar un services.yaml',
  'setup.yaml.body':
    'El formato de gethomepage.dev, tal cual: grupos, direcciones y widgets. La exportación también existe, en ambos sentidos.',
  'setup.manual.title': 'Escribir una dirección',
  'setup.manual.body':
    'Una URL y, si el servicio la pide, una clave de API. Lo que hace accesible tu homelab desde fuera —VPN, proxy inverso, túnel— se configura debajo de la app, no dentro.',

  // — privacidad —
  'privacy.body':
    'La app habla con tus máquinas y con nada más. Sin registro, sin intermediario por el que pasen tus direcciones, sin rastreadores. Las claves de API viven en el llavero del dispositivo: nunca en una copia de seguridad, nunca en iCloud.',

  // — precio —
  'pricing.eyebrow': 'Precio',
  'pricing.title': 'Cuatro servicios gratis y luego una plaza cada vez',
  'pricing.body':
    'Los cuatro primeros servicios son gratis, sin límite de tiempo y sin cuenta. A partir de ahí, cada plaza extra es una compra única. El precio es estrictamente lineal: sin packs, sin tramos, sin suscripción. Eliges cuántas plazas quieres y pagas una sola vez.',
  'pricing.free.title': 'Gratis pase lo que pase',
  'pricing.free.items': [
    'Todo el modo demo',
    'Todas las integraciones',
    'Las alertas y la detección de caídas',
    'Los widgets y la Live Activity',
    'La importación y exportación de services.yaml',
  ],
  'pricing.quota.title': 'Qué cuenta la cuota',
  'pricing.quota.body':
    'Solo cuántos servicios vigilas a la vez. Borrar un servicio libera su plaza para otro. Existe aparte un desbloqueo ilimitado, para quien quiera apoyar el proyecto.',
  'pricing.note': 'Precio de Francia. La App Store muestra el tuyo, en tu moneda.',

  // — integraciones —
  'integrations.eyebrow': 'Integraciones',
  'integrations.title': 'Los servicios que Specula reconoce',
  'integrations.lede':
    'Cada integración está escrita a mano contra la API del servicio. Esto es lo que Specula lee de cada uno, y lo que no.',
  'integrations.metrics.title': 'Qué lee Specula',
  'integrations.metrics.none':
    'Sin métricas: Specula sigue su disponibilidad y su latencia, nada más.',
  'integrations.endpoints.title': 'Endpoints de la API que llama',
  'integrations.key.title': 'Credencial necesaria',
  'integrations.key.none': 'Ninguna: basta con una dirección.',
  'integrations.key.userPassword': 'Usuario y contraseña',
  'integrations.key.password': 'Contraseña',
  'integrations.key.token': 'Un único token',
  'integrations.missing': '¿No está tu servicio?',
  'integrations.missing.body':
    'Cualquier dirección que responda se sigue como genérica: disponibilidad, latencia e historial. Y siguen llegando integraciones: pide la tuya en GitHub.',
  'integrations.missing.cta': 'Proponer una integración',

  // — páginas legales —
  'legal.updated': 'Última actualización:',
  'legal.notice':
    'Esta página solo existe en inglés y francés. Un texto legal traducido sin revisión vale menos que el mismo texto en un idioma que puedas comprobar.',

  // — novedades —
  'changelog.title': 'Lo que se ha publicado, versión a versión',
  'changelog.description':
    'Todas las versiones de Specula, tal y como las publica el repositorio. Los números y las notas se generan a partir de los propios commits.',
  'changelog.language':
    'Las notas están en francés: proceden de los mensajes de commit, y traducir una copia la desincronizaría en la siguiente versión.',

  // — página de precio —
  'pricing.price.slot': 'por plaza, pago único',
  'pricing.price.unlimited': 'por el desbloqueo ilimitado',
  'pricing.page.title': 'Precio',
  'pricing.how.title': 'Cómo funciona una plaza',
  'pricing.how.body':
    'Una plaza es un servicio vigilado. Empiezas con cuatro. A partir de ahí, cada plaza es una compra única a precio unitario fijo: comprar dos ahora y tres más tarde cuesta exactamente lo mismo que comprar cinco de golpe.',
  'pricing.restore.title': 'Cambiar de dispositivo',
  'pricing.restore.body':
    'El número de plazas que tienes se guarda en tu almacén clave-valor de iCloud, así que un iPhone o un Mac nuevo las recupera. Las compras también se pueden restaurar desde la App Store cuando quieras.',
  'pricing.unlimited.title': 'Desbloqueo ilimitado',
  'pricing.unlimited.body':
    'Una compra única aparte que quita del todo el contador de plazas. Existe para homelabs grandes, y para quien simplemente quiera apoyar el proyecto.',
  'pricing.refund.title': 'Reembolsos',
  'pricing.refund.body':
    'Las compras pasan por la App Store, así que los reembolsos los gestiona Apple según sus condiciones. Specula nunca ve tus datos de pago.',

  // — familias de servicios —
  'family.media': 'Multimedia',
  'family.downloads': 'Descargas y bibliotecas',
  'family.network': 'Red',
  'family.infra': 'Máquinas y almacenamiento',
  'family.home': 'Domótica',
  'family.monitoring': 'Monitorización',
  'family.tools': 'Herramientas',

  // — página de una integración —
  'integration.heading': '{service} en tu iPhone, iPad y Mac',
  'integration.lede':
    'Specula lee {service} por su propia API y muestra {metrics}, en la pantalla de inicio, en un widget y en la barra de menús del Mac. Sin cuenta, sin agente que instalar, sin intermediarios.',
  'integration.lede.plain':
    'Specula vigila {service}: si responde, a qué velocidad y treinta días de historial de disponibilidad, en tu iPhone, iPad y Mac. Sin cuenta, sin agente que instalar, sin intermediarios.',
  'integration.back': 'Todas las integraciones',
  'integration.official': 'Sitio oficial',
  'integration.setup': 'Añadirlo lleva un minuto',
  'integration.setup.body':
    'Escanea tu red por Bonjour, importa tu services.yaml o escribe la dirección. Specula adivina el tipo por su cuenta.',
  'integration.cta': 'Probarlo con {service}',

  // — preguntas —
  'faq.eyebrow': 'Preguntas',
  'faq.title': 'Lo que más se pregunta',
  'faq.remote.q': '¿Y si mi homelab no está expuesto a internet?',
  'faq.remote.a':
    'Specula pide una sola dirección por servicio y nunca intenta atravesar tu red. Lo que hace accesible tu homelab desde fuera —VPN, proxy inverso, túnel— se configura debajo de la app. En tu propia red no hay nada que hacer.',
  'faq.away.q': '¿Cómo lo consulto fuera de casa?',
  'faq.away.a':
    'Una sola dirección por servicio: la que funciona desde ambos lados. Con una red mallada como Tailscale, escribe el nombre MagicDNS —jellyfin.tu-tailnet.ts.net—: resuelve en casa y fuera, y el tráfico sigue yendo directo por tu red local cuando estás en ella. Un proxy inverso o un túnel hacen lo mismo. Specula no crea ninguna ruta: sigue la tuya, y mantiene la aceptación del certificado autofirmado de tu servicio en el rango de direcciones del tailnet.',
  'faq.selfhost.q': '¿Tengo que alojar algo?',
  'faq.selfhost.a':
    'No. Ningún agente que instalar, ningún contenedor que arrancar, ninguna cuenta que crear. La app consulta las API que tus servicios ya exponen.',
  'faq.versions.q': '¿Por qué solo iOS 26 y macOS 26?',
  'faq.versions.a':
    'La app está escrita contra las API de esa generación. No se admite ninguna versión anterior.',
  'faq.homepage.q': 'Ya uso gethomepage. ¿Tengo que reescribirlo todo?',
  'faq.homepage.a':
    'No. Specula importa tu services.yaml tal cual —grupos, direcciones y widgets— y sabe volver a exportarlo.',

  // — cierre —
    'cta.store': 'Descargar en la App Store',
  'cta.title.live': 'Specula ya está en la App Store',
  'cta.body.live': 'Una sola app para iPhone, iPad y Mac. El modo demo arranca sin configurar nada.',
  'cta.price': 'Gratis hasta cuatro servicios, luego {price} por plaza',
'cta.title': 'La beta está abierta',
  'cta.body':
    'Un solo enlace de TestFlight para iPhone, iPad y Mac. El modo demo arranca sin configurar nada.',

  // — pie —
  'footer.support': 'Soporte',
  'footer.privacy': 'Privacidad',
  'footer.changelog': 'Novedades',
  'footer.license': 'GPL-3.0 © nysia. Tipografía Archivo bajo SIL Open Font License 1.1.',
  'footer.language': 'Idioma',
} as const;
