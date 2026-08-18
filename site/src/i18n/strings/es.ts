export const es = {
  // — meta —
  'site.description':
    'Panel nativo para tus servicios autoalojados, en iPhone, iPad y Mac. Lee sus métricas, detecta las caídas y alimenta los widgets. Sin cuenta, sin servidor, sin telemetría.',

  // — navegación —
  'nav.integrations': 'Integraciones',
  'nav.pricing': 'Precio',
  'nav.how': 'Funcionamiento',
  'nav.faq': 'FAQ',
  'nav.privacy': 'Privacidad',
  'nav.changelog': 'Novedades',
  'theme.toggle': 'Cambiar de tema',
  'nav.cta': 'Unirse a la beta',
  'nav.menu': 'Menú',

  // — portada —
  'hero.title': 'Tu homelab, sin preocupaciones.',
  'hero.title.accent': 'sin preocupaciones.',
  'hero.lede':
    'Specula lo ve todo: métricas en directo, cada servicio vigilado, alerta inmediata.',
  'hero.cta.primary': 'Unirse a la beta de TestFlight',

  // — capturas —
  'shot.ios.alt':
    'Specula en iPhone: la lista de servicios por grupo con la latencia de cada uno, la banda de sistema arriba y Komga marcado fuera de línea.',

  // — marquesina de integraciones —
  'marquee.label': 'Reconocidos automáticamente — leídos por su propia API',
  'marquee.more': '+ {count} más',
  'marquee.browse': 'Ver las {count} integraciones',

  // — el problema —
  'watch.eyebrow': 'El problema',
  'watch.title': 'Tu homelab funciona. ¿Quién lo vigila?',
  'watch.title.accent': '¿Quién lo vigila?',
  'watch.p1':
    'La mayoría de los paneles muestran enlaces. Bonitos cuando todo va bien, mudos cuando algo se rompe — y acaba siendo un usuario quien te avisa de que Jellyfin se ha caído.',
  'watch.p2':
    'Specula lee las métricas de cada servicio por su propia API. Tres lecturas fallidas, y el servicio pasa a fuera de línea: notificación, Live Activity, y el muro de estado guarda el registro.',
  'stat.fail.b': '3',
  'stat.fail.text': 'intentos fallidos y el servicio se declara caído — ni uno más',
  'stat.history.b': '30 d',
  'stat.history.text': 'de historial de estado, con la disponibilidad real calculada',
  'stat.zero.b': '0',
  'stat.zero.text': 'cuentas, servidores intermediarios o telemetría — la app habla con tus máquinas y con nada más',

  // — funciones —
  'features.eyebrow': 'Funciones',
  'features.title': 'Todo para montar guardia.',
  'features.sub': 'No un muro de enlaces: un panel que lee, comprueba y alerta.',
  'features.detect.title': 'Detección de caídas',
  'features.detect.body':
    'Tres intentos fallidos marcan un servicio como caído, con notificación y Live Activity. La vuelta también se notifica.',
  'features.screens.title': 'En todas tus pantallas',
  'features.screens.body':
    'Widgets en la pantalla de inicio, acceso desde la barra de menús del Mac. El estado real, sin abrir la app.',
  'features.private.title': 'Nada sale de tu casa',
  'features.private.body':
    'Sin cuenta, sin telemetría. Las claves de API viven en el llavero: nunca en una copia de seguridad, nunca en iCloud.',

  // — cómo funciona —
  'how.eyebrow': 'Cómo funciona',
  'how.title': 'De cero a vigilado en tres gestos.',
  'how.step': 'Paso',
  'how.scan.title': 'Escanea tu red',
  'how.scan.b1': 'Specula escucha tu red local y reconoce por sí solo lo que corre en ella',
  'how.scan.b2': 'Un services.yaml en formato gethomepage.dev se importa tal cual',
  'how.scan.b3': 'Y una dirección siempre se puede escribir a mano',
  'how.scan.demo': 'Escaneo en curso',
  'how.recognized': 'reconocido',
  'how.scan.found': '12 servicios encontrados',
  'how.read.title': 'Lee las métricas reales',
  'how.read.b1': 'Cada integración habla la API nativa del servicio',
  'how.read.b2': 'Las claves de API entran en el llavero, no en un archivo',
  'how.read.b3': 'Los widgets muestran esas cifras, no una caché',
  'how.read.demo': 'Lectura en directo',
  'how.jellyfin.movies': '412 películas',
  'how.jellyfin.shows': '87 series',
  'how.alert.title': 'No se pierde ninguna caída',
  'how.alert.b1': 'Tres fallos, y el servicio pasa a fuera de línea — notificación inmediata',
  'how.alert.b2': 'Una Live Activity sigue la caída hasta la vuelta',
  'how.alert.b3': 'El muro de estado guarda treinta días y calcula la disponibilidad real',
  'how.alert.demo': 'Caída detectada',
  'how.alert.notif': 'Home Assistant está fuera de línea',
  'how.alert.notifBody': 'tres intentos fallidos en 192.168.1.56.',
  'how.tl.down': 'fuera de línea · 3:12',
  'how.tl.up': 'en línea · 3:34',
  'how.tl.note': '22 min de interrupción, guardados en el historial',

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
  'integrations.key.chip': 'clave API',
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
  'changelog.title': 'Lo que cambia',
  'changelog.description': 'Lo que ha cambiado en Specula en cada actualización.',
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
    'Escanea tu red por Bonjour, importa tu services.yaml o escribe la dirección. Specula reconoce el tipo por su cuenta.',
  'integration.cta': 'Probarlo con {service}',

  // — preguntas —
  'faq.eyebrow': 'FAQ',
  'faq.title': 'Preguntas frecuentes',
  'faq.vpn.q': 'Mi homelab solo es accesible por VPN. ¿Funciona?',
  'faq.vpn.a':
    'Sí. Una sola URL por servicio: lo que hace accesible un homelab desde fuera —VPN, proxy inverso, túnel— se configura debajo de la app, no dentro. Si tu dispositivo llega al servicio, Specula también.',
  'faq.egress.q': '¿Qué sale de mi red, exactamente?',
  'faq.egress.a':
    'Casi nada, y todo tiene nombre. El número de plazas compradas se escribe en tu almacén clave-valor de iCloud: un entero, no tus servicios, ni sus direcciones, ni tus claves. Y los logotipos vienen del CDN público dashboard-icons; un interruptor lo corta y la app recurre a los monogramas.',
  'faq.homepage.q': 'Ya uso Homepage. ¿Empiezo de cero?',
  'faq.homepage.a':
    'No: importa tu services.yaml en formato gethomepage.dev —grupos, direcciones y widgets se recuperan tal cual—. Solo las claves en variables {{HOMEPAGE_VAR_…}} hay que escribirlas una vez: viven en el .env de Homepage, al que Specula no tiene acceso.',
  'faq.generic.q': '¿Mi servicio no está entre las 65 integraciones?',
  'faq.generic.a':
    'Cualquier dirección que responda se sigue como genérica: disponibilidad, latencia y treinta días de historial. Y siguen llegando integraciones: pide la tuya en GitHub, bastan el nombre del servicio y un enlace a la documentación de su API.',
  'faq.more': '¿Otra pregunta?',
  'faq.more.link': 'El soporte responde',

  // — cierre —
  'cta.store': 'Descargar en la App Store',
  'cta.eyebrow': 'Specula, «atalaya» en latín',
  'cta.title.live': '¿Listo para montar guardia?',
  'cta.title.accent': 'montar guardia?',
  'cta.body.live':
    'Gratis, sin cuenta, con cuatro servicios incluidos. La misma app en iPhone, iPad y Mac.',
  'cta.price': 'Gratis hasta cuatro servicios, luego {price} por plaza',
  'cta.title': 'La beta está abierta',
  'cta.body':
    'Un solo enlace de TestFlight para iPhone, iPad y Mac. El modo demo arranca sin configurar nada.',

  // — vitrine défilante de l'accueil —
  'journey.read': 'Leer',
  'journey.alert': 'Alertar',
  'journey.status': 'Estado',
  'journey.settings': 'Ajustes',
  'journey.adguard.reqs': '31 402 pet./día',
  'journey.adguard.blocked': '22 % bloqueadas',
  'journey.proxmox.nodes': '3 nodos',
  'journey.proxmox.cpu': 'CPU 12 %',
  'journey.down.title': 'Komga no responde',
  'journey.down.body': 'tres intentos fallidos.',
  'journey.down.time': '3:12',
  'journey.up.title': 'Komga ha vuelto',
  'journey.up.body': '22 min de interrupción.',
  'journey.up.time': '3:34',
  'journey.incident.title': 'Incidente — Komga',
  'journey.incident.date': '12 ago · 22 min',
  'journey.incident.body': 'conexión rechazada, notificada a las 3:12.',
  'journey.uptime.title': 'Disponibilidad media',
  'journey.uptime.value': '99,9 %',
  'journey.uptime.body': 'Treinta días de historial, calculados con tres lecturas por servicio.',
  'journey.pinned.title': 'Fijados',
  'journey.pinned.body': 'Cuatro servicios en el widget y en la barra de menús del Mac.',
  'journey.theme.title': 'Tema e idiomas',
  'journey.theme.body': 'Sistema, claro u oscuro — y cinco idiomas, árabe y chino incluidos.',
  'journey.alert.alt': 'El detalle de una caída: Komga fuera de línea, latencia plana, registro del contenedor.',
  'journey.status.alt': 'El muro de disponibilidad: una fila de treinta días por servicio, incidentes en rojo.',
  'journey.settings.alt': 'Los ajustes: iconos, grupos y servicios fijados.',

  // — pie —
  'support.title': 'Respondemos.',
  'support.lede': 'Un correo, un repositorio público y respuestas a las preguntas que se repiten.',
  'footer.support': 'Soporte',
  'footer.privacy': 'Privacidad',
  'footer.changelog': 'Novedades',
  'footer.license': 'Tipografía Archivo bajo SIL Open Font License 1.1.',
  'footer.language': 'Idioma',
} as const;
