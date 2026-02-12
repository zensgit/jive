import 'account_constants.dart';

class AccountTypeOption {
  final String id;
  final String label;
  final String type;
  final String group;
  final String icon;
  final String? colorHex;
  final bool requiresBank;
  final bool requiresCreditMeta;
  final String? nameSuffix;

  const AccountTypeOption({
    required this.id,
    required this.label,
    required this.type,
    required this.group,
    required this.icon,
    this.colorHex,
    this.requiresBank = false,
    this.requiresCreditMeta = false,
    this.nameSuffix,
  });
}

class AccountTypeSection {
  final String title;
  final List<AccountTypeOption> options;

  const AccountTypeSection({required this.title, required this.options});
}

class AccountTypeCatalog {
  static const List<AccountTypeSection> sections = [
    AccountTypeSection(
      title: accountGroupAssets,
      options: [
        AccountTypeOption(
          id: 'cash',
          label: '现金',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'payments',
          colorHex: '#43A047',
        ),
        AccountTypeOption(
          id: 'wechat',
          label: '微信',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/wechat.png',
          colorHex: '#2E7D32',
        ),
        AccountTypeOption(
          id: 'wechat_balance',
          label: '微信零钱通',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/wechat_balance.png',
          colorHex: '#2E7D32',
        ),
        AccountTypeOption(
          id: 'alipay',
          label: '支付宝',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/alipay.png',
          colorHex: '#0277BD',
        ),
        AccountTypeOption(
          id: 'yuebao',
          label: '余额宝',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/yuebao.png',
          colorHex: '#26A69A',
        ),
        AccountTypeOption(
          id: 'unionpay',
          label: '云闪付',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/unionpay.png',
          colorHex: '#1565C0',
        ),
        AccountTypeOption(
          id: 'bank',
          label: '银行卡',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/bank.png',
          colorHex: '#1E88E5',
          requiresBank: true,
          nameSuffix: '银行卡',
        ),
        AccountTypeOption(
          id: 'public_fund',
          label: '公积金',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/public_fund.png',
          colorHex: '#7CB342',
        ),
        AccountTypeOption(
          id: 'qq_wallet',
          label: 'QQ钱包',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/qq_wallet.png',
          colorHex: '#5E35B1',
        ),
        AccountTypeOption(
          id: 'jd_finance',
          label: '京东金融',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/jd_finance.png',
          colorHex: '#D32F2F',
        ),
        AccountTypeOption(
          id: 'medical_insurance',
          label: '医保',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'medical_services',
          colorHex: '#EF5350',
        ),
        AccountTypeOption(
          id: 'digital_cny',
          label: '数字人民币',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/digital_cny.png',
          colorHex: '#FF7043',
        ),
        AccountTypeOption(
          id: 'huawei_wallet',
          label: '华为钱包',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/huawei.png',
          colorHex: '#546E7A',
        ),
        AccountTypeOption(
          id: 'pdd_wallet',
          label: '多多钱包',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'account_balance_wallet',
          colorHex: '#E53935',
        ),
        AccountTypeOption(
          id: 'paypal',
          label: 'PayPal',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'brands/paypal.png',
          colorHex: '#1565C0',
        ),
        AccountTypeOption(
          id: 'wallet',
          label: '电子钱包',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'account_balance_wallet',
          colorHex: '#2E7D32',
        ),
        AccountTypeOption(
          id: 'other_asset',
          label: '其他',
          type: accountTypeAsset,
          group: accountGroupAssets,
          icon: 'account_balance_wallet',
          colorHex: '#607D8B',
        ),
      ],
    ),
    AccountTypeSection(
      title: accountGroupCredit,
      options: [
        AccountTypeOption(
          id: 'credit',
          label: '信用卡',
          type: accountTypeLiability,
          group: accountGroupCredit,
          icon: 'credit_card',
          colorHex: '#EF5350',
          requiresBank: true,
          requiresCreditMeta: true,
          nameSuffix: '信用卡',
        ),
        AccountTypeOption(
          id: 'huabei',
          label: '花呗',
          type: accountTypeLiability,
          group: accountGroupCredit,
          icon: 'credit_card',
          colorHex: '#FF7043',
        ),
        AccountTypeOption(
          id: 'jiebei',
          label: '借呗',
          type: accountTypeLiability,
          group: accountGroupCredit,
          icon: 'credit_card',
          colorHex: '#FF7043',
        ),
        AccountTypeOption(
          id: 'baitiao',
          label: '京东白条',
          type: accountTypeLiability,
          group: accountGroupCredit,
          icon: 'brands/baitiao.png',
          colorHex: '#D32F2F',
        ),
        AccountTypeOption(
          id: 'meituan_monthly',
          label: '美团月付',
          type: accountTypeLiability,
          group: accountGroupCredit,
          icon: 'brands/meituan.png',
          colorHex: '#2E7D32',
        ),
        AccountTypeOption(
          id: 'douyin_monthly',
          label: '抖音月付',
          type: accountTypeLiability,
          group: accountGroupCredit,
          icon: 'brands/douyin.png',
          colorHex: '#212121',
        ),
        AccountTypeOption(
          id: 'wechat_paylater',
          label: '微信分付',
          type: accountTypeLiability,
          group: accountGroupCredit,
          icon: 'brands/wechat.png',
          colorHex: '#2E7D32',
        ),
        AccountTypeOption(
          id: 'other_credit',
          label: '其他信用卡',
          type: accountTypeLiability,
          group: accountGroupCredit,
          icon: 'credit_card',
          colorHex: '#90A4AE',
        ),
      ],
    ),
    AccountTypeSection(
      title: accountGroupRecharge,
      options: [
        AccountTypeOption(
          id: 'recharge_phone',
          label: '话费',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'phone_android',
          colorHex: '#26A69A',
        ),
        AccountTypeOption(
          id: 'recharge_utilities',
          label: '水电',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'power',
          colorHex: '#42A5F5',
        ),
        AccountTypeOption(
          id: 'recharge_meal',
          label: '饭卡',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'restaurant',
          colorHex: '#8D6E63',
        ),
        AccountTypeOption(
          id: 'deposit',
          label: '押金',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'lock',
          colorHex: '#8D6E63',
        ),
        AccountTypeOption(
          id: 'transit_card',
          label: '公交卡',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'directions_bus',
          colorHex: '#42A5F5',
        ),
        AccountTypeOption(
          id: 'membership',
          label: '会员卡',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'brands/membership.png',
          colorHex: '#AB47BC',
        ),
        AccountTypeOption(
          id: 'fuel_card',
          label: '加油卡',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'brands/fuel_card.png',
          colorHex: '#FF7043',
        ),
        AccountTypeOption(
          id: 'petro_wallet',
          label: '石化钱包',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'brands/petro_wallet.png',
          colorHex: '#F4511E',
        ),
        AccountTypeOption(
          id: 'apple',
          label: 'Apple',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'brands/apple.png',
          colorHex: '#424242',
        ),
        AccountTypeOption(
          id: 'other_recharge',
          label: '其他充值卡',
          type: accountTypeAsset,
          group: accountGroupRecharge,
          icon: 'battery_charging_full',
          colorHex: '#78909C',
        ),
      ],
    ),
    AccountTypeSection(
      title: accountGroupInvest,
      options: [
        AccountTypeOption(
          id: 'invest_stock',
          label: '股票',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'show_chart',
          colorHex: '#26A69A',
        ),
        AccountTypeOption(
          id: 'invest_fund',
          label: '基金',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'account_balance',
          colorHex: '#42A5F5',
        ),
        AccountTypeOption(
          id: 'invest_gold',
          label: '黄金',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'workspace_premium',
          colorHex: '#FBC02D',
        ),
        AccountTypeOption(
          id: 'invest_forex',
          label: '外汇',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'currency_exchange',
          colorHex: '#8E24AA',
        ),
        AccountTypeOption(
          id: 'invest_futures',
          label: '期货',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'trending_up',
          colorHex: '#5C6BC0',
        ),
        AccountTypeOption(
          id: 'invest_bond',
          label: '债券',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'receipt_long',
          colorHex: '#42A5F5',
        ),
        AccountTypeOption(
          id: 'invest_fixed',
          label: '固定收益',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'savings',
          colorHex: '#26A69A',
        ),
        AccountTypeOption(
          id: 'invest_crypto',
          label: '加密货币',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'currency_bitcoin',
          colorHex: '#F9A825',
        ),
        AccountTypeOption(
          id: 'invest_other',
          label: '其它理财',
          type: accountTypeAsset,
          group: accountGroupInvest,
          icon: 'savings',
          colorHex: '#90A4AE',
        ),
      ],
    ),
    AccountTypeSection(
      title: accountGroupDebt,
      options: [
        AccountTypeOption(
          id: 'lend_out',
          label: '借出',
          type: accountTypeAsset,
          group: accountGroupDebt,
          icon: 'request_page',
          colorHex: '#5C6BC0',
        ),
        AccountTypeOption(
          id: 'loan',
          label: '借入',
          type: accountTypeLiability,
          group: accountGroupDebt,
          icon: 'request_page',
          colorHex: '#FF7043',
        ),
        AccountTypeOption(
          id: 'other_liability',
          label: '其他负债',
          type: accountTypeLiability,
          group: accountGroupDebt,
          icon: 'report',
          colorHex: '#FFB300',
        ),
      ],
    ),
  ];

  static final Map<String, AccountTypeOption> _optionById = {
    for (final section in sections)
      for (final option in section.options) option.id: option,
  };

  static AccountTypeOption? optionFor(String? id) {
    if (id == null) return null;
    return _optionById[id];
  }
}
