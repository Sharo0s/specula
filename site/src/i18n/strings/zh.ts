export const zh = {
  // — 元信息 —
  'site.tagline': '你的 homelab 原生仪表板',
  'site.description':
    '为自托管服务打造的原生仪表板，支持 iPhone、iPad 和 Mac。读取真实指标、发现故障、驱动小组件。无账号、无服务器、无遥测。',

  // — 导航 —
  'nav.integrations': '集成',
  'nav.pricing': '价格',
  'nav.privacy': '隐私',
  'nav.changelog': '更新日志',
  'theme.toggle': '切换主题',
  'nav.cta': '加入测试版',
  'nav.cta.live': '下载',

  // — 首屏 —
  'hero.title': '掌中的 homelab',
  'hero.title.accent': '掌中的',
  'hero.lede':
    '早上一眼就全知道：哪些在跑、哪些在卡、哪些昨夜掉线。iPhone、iPad 和 Mac 上都看得到。',
  'hero.proof.privacy': '无账号、无服务器、无遥测。',
  'hero.proof.platforms': 'iPhone、iPad 和 Mac，全部原生。',
  'hero.cta.primary': '加入 TestFlight 测试版',
  'hero.cta.secondary': '查看集成',

  // — 截图 —
  'shot.macos.alt':
    'macOS 上的 Specula：一侧是数据源和分组，中间是带指标的服务卡片，旁边是某个服务的详情。',
  'shot.ios.alt':
    'iPhone 上的 Specula：按分组列出的服务及各自延迟，顶部为系统状态条，Komga 标记为离线。',
  'shot.ipados.alt':
    'iPad 上的 Specula：按分组排列的服务网格，每个都显示通过其 API 读取的指标。',

  // — 功能 —
  'features.eyebrow': '它能做什么',
  'features.title': 'Ping 只说「有响应」，Specula 告诉你响应了什么。',

  'features.metrics.title': '通过每个服务自己的 API 读取真实指标',
  'features.metrics.body':
    'Specula 用每个服务自己的语言对话：AdGuard 用 /control/stats，Proxmox 用集群 API，NAS 用它自己的统计接口。你看到的是有意义的数字，而不是一个绿点。',

  'features.outage.title': '识别真正的故障，而不是为每次抖动报警',
  'features.outage.body':
    '连续三次请求失败才会判定服务下线——Wi-Fi 抖一下不会吵醒任何人。随后是通知、实时活动，以及保留三十天并计算真实可用率的状态墙。',

  'features.surfaces.title': '出现在你的每块屏幕上',
  'features.surfaces.body':
    '主屏幕和锁定屏幕小组件由真实状态驱动，Mac 菜单栏随时可查，故障期间还有实时活动。这是一个原生应用，不是套壳网页。',

  'features.demo.title': '不向你索取任何东西的演示模式',
  'features.demo.body':
    '首次启动即进入演示模式：一整套 homelab、可信的指标和一场编排好的故障。你可以先评估这个应用，再交给它任何一个地址。',

  // — 上手 —
  'surface.home': '主屏幕',
  'surface.lock': '锁定屏幕',
  'surface.menubar': '菜单栏',
  'feature.uptime': '三十天可用性',
  'feature.demo.chip': '演示模式',

  'setup.eyebrow': '开始使用',
  'setup.title': '三种上手方式',
  'setup.scan.title': '扫描网络',
  'setup.scan.body':
    'Specula 监听网络中的 Bonjour 广播，找到主动通告自己的服务并推断其类型。',
  'setup.yaml.title': '导入 services.yaml',
  'setup.yaml.body':
    '直接沿用 gethomepage.dev 的格式：分组、地址和小组件原样导入。导出同样支持，双向可用。',
  'setup.manual.title': '手动输入地址',
  'setup.manual.body':
    '一个 URL，必要时加一个 API 密钥。让 homelab 能从外网访问的方式——VPN、反向代理、隧道——属于应用之下的一层，而不是应用内部。',

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
  'changelog.title': '逐个版本的发布记录',
  'changelog.description':
    'Specula 的全部版本，直接来自代码仓库。版本号和说明均由提交记录生成。',
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
    '用 Bonjour 扫描网络、导入现有的 services.yaml，或者直接输入地址。Specula 会自行判断类型。',
  'integration.cta': '用 {service} 试试',

  // — 常见问题 —
  'faq.eyebrow': '问题',
  'faq.title': '大家问得最多的',
  'faq.remote.q': '如果我的 homelab 没有暴露在公网上呢？',
  'faq.remote.a':
    'Specula 每个服务只要一个地址，也从不尝试穿透你的网络。让 homelab 能从外部访问的方式——VPN、反向代理、隧道——属于应用之下的一层。在自己的网络里，什么都不用做。',
  'faq.away.q': '不在家时怎么查看？',
  'faq.away.a':
    '每个服务只填一个地址：在家和在外都能用的那个。若使用 Tailscale 这类网状网络，填 MagicDNS 名称（jellyfin.你的-tailnet.ts.net）：在家在外都能解析，而当你在同一局域网时流量仍走直连。反向代理或隧道同样可行。Specula 不会自行构建线路，它只沿用你已经搭好的那条，并且在 tailnet 地址段内依然接受服务的自签名证书。',
  'faq.selfhost.q': '需要额外部署什么吗？',
  'faq.selfhost.a':
    '不需要。没有代理程序要装，没有容器要跑，也没有账号要注册。应用直接调用你的服务已经暴露的 API。',
  'faq.versions.q': '为什么只支持 iOS 26 和 macOS 26？',
  'faq.versions.a': '应用是针对该代系统的 API 编写的，不支持更早的版本。',
  'faq.homepage.q': '我已经在用 gethomepage，需要全部重新录入吗？',
  'faq.homepage.a':
    '不需要。Specula 会原样导入你的 services.yaml——分组、地址和小组件——也可以再导出。',

  // — 结尾 —
    'cta.store': '在 App Store 下载',
  'cta.title.live': 'Specula 已上架 App Store',
  'cta.body.live': '一个应用覆盖 iPhone、iPad 和 Mac。演示模式无需任何配置即可运行。',
  'cta.price': '四个服务以内免费，之后每个服务位 {price}',
'cta.title': '测试版已开放',
  'cta.body': '一个 TestFlight 链接，覆盖 iPhone、iPad 和 Mac。演示模式无需任何配置即可运行。',

  // — 页脚 —
  'footer.support': '支持',
  'footer.privacy': '隐私',
  'footer.changelog': '更新日志',
  'footer.license': 'GPL-3.0 © nysia。Archivo 字体采用 SIL Open Font License 1.1。',
  'footer.language': '语言',
} as const;
