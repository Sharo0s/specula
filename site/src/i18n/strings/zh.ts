export const zh = {
  // — 元信息 —
  'site.description':
    '为自托管服务打造的原生仪表板，支持 iPhone、iPad 和 Mac。读取各项指标、发现故障、驱动小组件。无账号、无服务器、无遥测。',

  // — 导航 —
  'nav.integrations': '集成',
  'nav.pricing': '价格',
  'nav.how': '工作原理',
  'nav.faq': '常见问题',
  'nav.privacy': '隐私',
  'nav.changelog': '更新日志',
  'theme.toggle': '切换主题',
  'nav.cta': '加入测试版',
  'nav.menu': '菜单',

  // — 首屏 —
  'hero.title': '你的 homelab，从此无忧。',
  'hero.title.accent': '从此无忧',
  'hero.lede':
    'Specula 尽收眼底：实时指标、逐一守护每个服务、即时告警。',
  'hero.cta.primary': '加入 TestFlight 测试版',

  // — 截图 —
  'shot.ios.alt':
    'iPhone 上的 Specula：按分组列出的服务及各自延迟，顶部为系统状态条，Komga 标记为离线。',

  // — 集成跑马灯 —
  'marquee.label': '自动识别 — 通过各自的 API 读取',
  'marquee.more': '还有 {count} 个',
  'marquee.browse': '浏览全部 {count} 个集成',

  // — 问题所在 —
  'watch.eyebrow': '问题所在',
  'watch.title': '你的 homelab 在运转。谁在盯着它？',
  'watch.title.accent': '谁在盯着它？',
  'watch.p1':
    '大多数仪表板只是一排链接。一切正常时很好看，出问题时却一声不吭——最后是某个用户来告诉你 Jellyfin 挂了。',
  'watch.p2':
    'Specula 通过每个服务自己的 API 读取指标。连续三次读取失败，服务即被判定离线：通知、实时活动，状态墙留下记录。',
  'stat.fail.b': '3',
  'stat.fail.text': '次尝试失败即判定服务离线——一次也不多',
  'stat.history.b': '30 天',
  'stat.history.text': '的状态历史，并计算真实可用率',
  'stat.zero.b': '0',
  'stat.zero.text': '账号、中转服务器或遥测——应用只与你的机器通信，别无其他',

  // — 功能 —
  'features.eyebrow': '功能',
  'features.title': '站岗放哨，样样俱全。',
  'features.sub': '不是一排链接，而是会读取、会核实、会报警的仪表板。',
  'features.detect.title': '故障检测',
  'features.detect.body':
    '连续三次尝试失败即判定服务离线，随之而来的是通知和实时活动。恢复上线也会通知。',
  'features.screens.title': '出现在你的每块屏幕上',
  'features.screens.body':
    '主屏幕小组件，Mac 菜单栏随时可查。真实状态，无需打开应用。',
  'features.private.title': '数据不出家门',
  'features.private.body':
    '无账号、无遥测。API 密钥保存在钥匙串中——不会进入备份，也不会上传 iCloud。',

  // — 工作原理 —
  'how.eyebrow': '工作原理',
  'how.title': '三步之内，从零到全面监控。',
  'how.step': '步骤',
  'how.scan.title': '扫描你的网络',
  'how.scan.b1': 'Specula 监听本地网络，自动识别网络中运行的服务',
  'how.scan.b2': 'gethomepage.dev 格式的 services.yaml 可以原样导入',
  'how.scan.b3': '地址也永远可以手动输入',
  'how.scan.demo': '扫描进行中',
  'how.recognized': '已识别',
  'how.scan.found': '找到 12 个服务',
  'how.read.title': '读取真实指标',
  'how.read.b1': '每个集成都使用服务的原生 API',
  'how.read.b2': 'API 密钥进入钥匙串，而不是某个文件',
  'how.read.b3': '小组件显示的正是这些数字，不是缓存',
  'how.read.demo': '实时读取',
  'how.jellyfin.movies': '412 部电影',
  'how.jellyfin.shows': '87 部剧集',
  'how.alert.title': '不放过任何故障',
  'how.alert.b1': '三次失败，服务即离线——立刻通知',
  'how.alert.b2': '实时活动全程跟进，直到恢复',
  'how.alert.b3': '状态墙保留三十天并计算真实可用率',
  'how.alert.demo': '检测到故障',
  'how.alert.notif': 'Home Assistant 已离线',
  'how.alert.notifBody': '192.168.1.56 上三次尝试失败。',
  'how.tl.down': '离线 · 03:12',
  'how.tl.up': '在线 · 03:34',
  'how.tl.note': '22 分钟的中断，已记入历史',

  // — 隐私 —
  'privacy.body':
    '应用只与你的机器通信，不与任何其他方通信。无需注册，没有中转你地址的中间人，没有跟踪器。API 密钥保存在设备钥匙串中——不会进入备份，也不会上传 iCloud。',

  // — 价格 —
  'pricing.eyebrow': '价格',
  'pricing.title': '四个服务免费，之后按位购买',
  'pricing.body':
    '前四个服务免费，没有时间限制，也不需要账号。之后每增加一个服务位为一次性购买。价格严格线性：没有套餐、没有档位、没有订阅。你决定要几个位，一次付清。',
  'pricing.free.title': '始终免费的部分',
  'pricing.free.items': [
    '完整的演示模式',
    '全部集成',
    '警报与故障检测',
    '小组件与实时活动',
    'services.yaml 的导入与导出',
  ],
  'pricing.quota.title': '配额计算什么',
  'pricing.quota.body':
    '只计算同时监控的服务数量。删除一个服务就会释放它的位置。此外另有一个「无限解锁」，供想支持这个项目的人选择。',
  'pricing.note': '法国区价格。App Store 会按你所在地区的货币显示。',

  // — 集成 —
  'integrations.eyebrow': '集成',
  'integrations.title': 'Specula 能识别的服务',
  'integrations.lede':
    '每个集成都是针对该服务的 API 手写的。下面列出 Specula 从每个服务读取什么——以及不读取什么。',
  'integrations.metrics.title': 'Specula 读取的内容',
  'integrations.metrics.none': '没有指标：Specula 只跟踪它的可用性和延迟。',
  'integrations.endpoints.title': '调用的 API 端点',
  'integrations.key.chip': 'API 密钥',
  'integrations.key.title': '需要的凭据',
  'integrations.key.none': '不需要——一个地址就够了。',
  'integrations.key.userPassword': '用户名和密码',
  'integrations.key.password': '密码',
  'integrations.key.token': '单个令牌',
  'integrations.missing': '没有你用的服务？',
  'integrations.missing.body':
    '任何能响应的地址都会作为通用服务被跟踪——可用性、延迟和历史记录。集成也在持续增加：欢迎到 GitHub 提出需求。',
  'integrations.missing.cta': '提交集成需求',

  // — 法律页面 —
  'legal.updated': '最后更新：',
  'legal.notice':
    '本页仅提供英文和法文版本。未经校对的法律译文，价值低于一份你能亲自核对的原文。',

  // — 更新日志 —
  'changelog.title': '有什么变化',
  'changelog.description': 'Specula 每次更新带来的变化。',
  'changelog.language':
    '说明为法文：它们来自提交信息，翻译副本会在下一个版本就与原文脱节。',

  // — 价格页 —
  'pricing.price.slot': '每个服务位，一次性购买',
  'pricing.price.unlimited': '无限解锁',
  'pricing.page.title': '价格',
  'pricing.how.title': '一个服务位是怎么回事',
  'pricing.how.body':
    '一个位对应一个被监控的服务。你从四个开始。之后每个位都是一次性购买，单价固定——现在买两个、以后再买三个，与一次买五个价格完全相同。',
  'pricing.restore.title': '更换设备',
  'pricing.restore.body':
    '你拥有的位数保存在 iCloud 键值存储中，新的 iPhone 或 Mac 会重新找回它们。购买记录也可以随时从 App Store 恢复。',
  'pricing.unlimited.title': '无限解锁',
  'pricing.unlimited.body':
    '一次性购买，彻底取消服务位上限。它为规模较大的 homelab 而设，也为想支持这个项目的人而设。',
  'pricing.refund.title': '退款',
  'pricing.refund.body':
    '购买通过 App Store 完成，因此退款由 Apple 按其条款处理。Specula 从不接触你的支付信息。',

  // — 服务分类 —
  'family.media': '影音',
  'family.downloads': '下载与媒体库',
  'family.network': '网络',
  'family.infra': '主机与存储',
  'family.home': '智能家居',
  'family.monitoring': '监控',
  'family.tools': '工具',

  // — 集成详情页 —
  'integration.heading': '在 iPhone、iPad 和 Mac 上使用 {service}',
  'integration.lede':
    'Specula 通过 {service} 自己的 API 读取数据，并显示{metrics}——在主屏幕上、在小组件里，以及 Mac 的菜单栏中。无账号、无需安装代理程序、无中间人。',
  'integration.lede.plain':
    'Specula 跟踪 {service}：是否响应、响应有多快，以及三十天的可用性历史——在 iPhone、iPad 和 Mac 上。无账号、无需安装代理程序、无中间人。',
  'integration.back': '全部集成',
  'integration.official': '官方网站',
  'integration.setup': '添加只需一分钟',
  'integration.setup.body':
    '用 Bonjour 扫描网络、导入现有的 services.yaml，或者直接输入地址。Specula 会自行识别类型。',
  'integration.cta': '用 {service} 试试',

  // — 常见问题 —
  'faq.eyebrow': '常见问题',
  'faq.title': '常见问题',
  'faq.vpn.q': '我的 homelab 只能通过 VPN 访问，能用吗？',
  'faq.vpn.a':
    '能。每个服务只填一个地址：让 homelab 能从外部访问的方式——VPN、反向代理、隧道——属于应用之下的一层，而不是应用内部。只要你的设备能连上服务，Specula 就能。',
  'faq.egress.q': '到底有什么会离开我的网络？',
  'faq.egress.a':
    '几乎没有，而且每一项都有名有姓。已购服务位的数量写入你的 iCloud 键值存储——只是一个整数，不含你的服务、地址或密钥。图标来自公共 CDN dashboard-icons；一个开关即可关闭，应用会退回到字母图标。',
  'faq.homepage.q': '我已经在用 Homepage，要从头再来吗？',
  'faq.homepage.a':
    '不用：按 gethomepage.dev 格式导入你的 services.yaml——分组、地址和小组件原样保留。只有存放在 {{HOMEPAGE_VAR_…}} 变量里的密钥需要输入一次：它们在 Homepage 的 .env 里，Specula 无法访问。',
  'faq.generic.q': '我的服务不在这 65 个集成里？',
  'faq.generic.a':
    '任何能响应的地址都会作为通用服务被跟踪——可用性、延迟和三十天历史。集成也在持续增加：到 GitHub 提出需求，只需服务名称和它的 API 文档链接。',
  'faq.more': '还有其他问题？',
  'faq.more.link': '支持页面有答案',

  // — 结尾 —
  'cta.store': '在 App Store 下载',
  'cta.eyebrow': 'Specula，拉丁语「瞭望塔」',
  'cta.title.live': '准备好站岗了吗？',
  'cta.title.accent': '站岗',
  'cta.body.live': '免费、无需账号，含四个服务。同一个应用覆盖 iPhone、iPad 和 Mac。',
  'cta.price': '四个服务以内免费，之后每个服务位 {price}',
  'cta.title': '测试版已开放',
  'cta.body': '一个 TestFlight 链接，覆盖 iPhone、iPad 和 Mac。演示模式无需任何配置即可运行。',

  // — vitrine défilante de l'accueil —
  'journey.read': '读取',
  'journey.alert': '提醒',
  'journey.status': '状态',
  'journey.settings': '设置',
  'journey.adguard.reqs': '每日 31 402 次请求',
  'journey.adguard.blocked': '22% 已拦截',
  'journey.proxmox.nodes': '3 个节点',
  'journey.proxmox.cpu': 'CPU 12%',
  'journey.down.title': 'Komga 没有响应',
  'journey.down.body': '三次尝试失败。',
  'journey.down.time': '03:12',
  'journey.up.title': 'Komga 已恢复',
  'journey.up.body': '中断 22 分钟。',
  'journey.up.time': '03:34',
  'journey.incident.title': '故障 — Komga',
  'journey.incident.date': '8 月 12 日 · 22 分钟',
  'journey.incident.body': '连接被拒绝，已于 03:12 通知。',
  'journey.uptime.title': '平均可用性',
  'journey.uptime.value': '99.9%',
  'journey.uptime.body': '三十天的历史，按每个服务三次读取计算。',
  'journey.pinned.title': '置顶',
  'journey.pinned.body': '四个服务显示在小组件和 Mac 菜单栏中。',
  'journey.theme.title': '主题与语言',
  'journey.theme.body': '跟随系统、浅色或深色 — 还有五种语言，包括阿拉伯语和中文。',
  'journey.alert.alt': '故障详情：Komga 离线，延迟曲线归零，容器日志。',
  'journey.status.alt': '可用性墙：每个服务一行三十天，故障标红。',
  'journey.settings.alt': '设置：图标、分组与置顶服务。',

  // — 页脚 —
  'support.title': '有问必答。',
  'support.lede': '一个邮箱、一个公开仓库，以及常见问题的答案。',
  'footer.support': '支持',
  'footer.privacy': '隐私',
  'footer.changelog': '更新日志',
  'footer.license': 'Archivo 字体采用 SIL Open Font License 1.1。',
  'footer.language': '语言',
} as const;
