class AutoAppDefinition {
  final String packageName;
  final String name;
  final String description;
  final bool defaultEnabled;
  final List<String> aliases;

  const AutoAppDefinition({
    required this.packageName,
    required this.name,
    required this.description,
    this.defaultEnabled = true,
    this.aliases = const [],
  });

  bool matchesSource(String? source) {
    if (source == null) return false;
    final trimmed = source.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed == name) return true;
    for (final alias in aliases) {
      if (trimmed == alias) return true;
    }
    return false;
  }
}

class AutoAppRegistry {
  static const apps = <AutoAppDefinition>[
    AutoAppDefinition(
      packageName: 'com.eg.android.AlipayGphone',
      name: '支付宝',
      description: '扫码付款、转账、红包、提现、账单详情',
      aliases: ['Alipay'],
    ),
    AutoAppDefinition(
      packageName: 'com.tencent.mm',
      name: '微信',
      description: '扫码付款、转账、红包、提现、账单详情',
      aliases: ['WeChat'],
    ),
    AutoAppDefinition(
      packageName: 'com.unionpay',
      name: '云闪付',
      description: '扫码付款、转账、账单详情',
      aliases: ['UnionPay'],
    ),
    AutoAppDefinition(
      packageName: 'com.jd.jrapp',
      name: '京东金融',
      description: '扫码付款、我的账单-账单详情',
    ),
    AutoAppDefinition(
      packageName: 'com.jingdong.app.mall',
      name: '京东商城',
      description: '购物、我的钱包-账单详情',
    ),
    AutoAppDefinition(
      packageName: 'com.xunmeng.pinduoduo',
      name: '拼多多',
      description: '购物',
    ),
    AutoAppDefinition(
      packageName: 'com.sankuai.meituan',
      name: '美团',
      description: '团购、点外卖',
    ),
    AutoAppDefinition(
      packageName: 'com.dianping.v1',
      name: '大众点评',
      description: '团购、点外卖',
    ),
    AutoAppDefinition(
      packageName: 'com.sankuai.meituan.takeoutnew',
      name: '美团外卖',
      description: '点外卖',
    ),
    AutoAppDefinition(
      packageName: 'com.ss.android.ugc.aweme',
      name: '抖音',
      description: '直播购物',
    ),
    AutoAppDefinition(
      packageName: 'com.ss.android.ugc.livelite',
      name: '抖音商城',
      description: '购物',
    ),
    AutoAppDefinition(
      packageName: 'com.ss.android.ugc.aweme.lite',
      name: '抖音极速版',
      description: '直播购物',
    ),
    AutoAppDefinition(
      packageName: 'com.ss.android.yumme.video',
      name: '抖音精选',
      description: '直播购物',
    ),
    AutoAppDefinition(
      packageName: 'com.taobao.taobao',
      name: '淘宝',
      description: '购物（官方限制，无法完整使用）',
    ),
    AutoAppDefinition(
      packageName: 'com.alibaba.wireless',
      name: '阿里巴巴',
      description: '购物',
    ),
    AutoAppDefinition(
      packageName: 'com.taobao.idlefish',
      name: '闲鱼',
      description: '购物',
    ),
    AutoAppDefinition(
      packageName: 'com.wudaokou.hippo',
      name: '盒马',
      description: '付款码付款',
    ),
    AutoAppDefinition(
      packageName: 'me.ele',
      name: '饿了么',
      description: '点外卖',
    ),
    AutoAppDefinition(
      packageName: 'com.huawei.wallet',
      name: '华为钱包',
      description: '付款、账单详情',
    ),
    AutoAppDefinition(
      packageName: 'com.ccb.longjiLife',
      name: '建行生活',
      description: '付款、钱包-支付记录',
    ),
    AutoAppDefinition(
      packageName: 'com.smile.gifmaker',
      name: '快手',
      description: '直播购物',
    ),
    AutoAppDefinition(
      packageName: 'com.kuaishou.nebula',
      name: '快手极速版',
      description: '直播购物',
    ),
  ];

  static AutoAppDefinition? findByPackage(String? packageName) {
    if (packageName == null) return null;
    for (final app in apps) {
      if (app.packageName == packageName) return app;
    }
    return null;
  }

  static String? resolvePackage(String? source) {
    if (source == null) return null;
    for (final app in apps) {
      if (app.matchesSource(source)) return app.packageName;
    }
    return null;
  }

  static bool isSupported(String? packageName) {
    return findByPackage(packageName) != null;
  }
}
