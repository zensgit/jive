# Yimu auto rules mapping (seed)

This is a seed mapping extracted from the yimu auto action classes. It lists the
app/origin names we can map directly to Jive brand categories, plus a small set
of candidate keywords that likely indicate transfer or special flows.

## Mapped origins -> Jive brand categories
- 阿里巴巴 -> 品牌/阿里巴巴
- 阿里1688 -> 品牌/阿里1688
- 淘宝 -> 品牌/淘宝
- 拼多多 -> 品牌/拼多多
- 京东金融 / 京东支付 -> 品牌/京东
- 美团 -> 品牌/美团
- 饿了么 -> 品牌/饿了么
- 盒马 -> 品牌/盒马鲜生
- 闲鱼 -> 品牌/闲鱼
- 抖音 / 抖音支付 / 抖音月付 -> 品牌/抖音
- 快手 -> 品牌/快手
- 云闪付 -> 品牌/银联
- 华为支付 -> 品牌/华为
- 建行生活 -> 品牌/建设银行
- 微信 -> 品牌/微信
- 支付宝 -> 品牌/支付宝

## Candidate keywords (source-scoped, needs sample validation)
WeChat:
- 转入零钱通
- 零钱通转出
- 信用卡还款
- 微信转账

Alipay:
- 提现说明
- 转出说明
- 余额转入
- 余额宝-单次转入
- 余额宝-转出到余额
- 网商银行转账
- 还款成功

UnionPay:
- 转账成功
- 转出成功
- 信用卡还款

Notes:
- These candidates are not yet merged into `app/assets/auto_rules.json` to avoid
  false positives. We should validate with real notification samples first.
