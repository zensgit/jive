# Jive SaaS 运营配置清单

> 日期: 2026-03-31
> 代码基线: main（PR #86-#98 全部合并）
> 状态: 代码就绪，待运营配置

---

## 一、Supabase（云同步后端）

### 已完成
- [x] 创建项目: `evnluvzvbqmsmypbchym`
- [x] 运行 SQL 迁移: `001_create_transactions.sql`
- [x] RLS 策略 + 索引已创建

### 待完成
- [ ] **开启 Auth Providers**
  - Dashboard → Authentication → Providers
  - 开启: Email, Phone (SMS)
  - 国内: 配置短信服务商（阿里云 SMS / 腾讯云 SMS）
  - 海外: 默认 Supabase 内置即可
- [ ] **开启 OAuth Providers**（可选，Phase 2）
  - Google: 需 Google Cloud Console OAuth client ID
  - Apple: 需 Apple Developer 的 Service ID + Key
  - 微信: 需微信开放平台应用审核通过
- [ ] **配置自定义 SMTP**（可选）
  - 用于发送验证邮件和密码重置
  - Dashboard → Settings → Auth → SMTP Settings
- [ ] **国内部署**（长期）
  - 自托管 Supabase 到阿里云 / 腾讯云
  - 目的: 国内用户访问速度 + 数据合规

### 凭据位置
| 凭据 | 用途 | 当前值 |
|---|---|---|
| SUPABASE_URL | 构建时注入 `--dart-define` | `https://evnluvzvbqmsmypbchym.supabase.co` |
| SUPABASE_ANON_KEY | 构建时注入 `--dart-define` | `eyJhbG...pa1_h...` (anon public) |
| service_role key | 仅服务端/管理用，不要写入客户端 | Dashboard → Settings → API |

### 构建命令
```bash
flutter build apk --release --flavor prod \
  --dart-define=SUPABASE_URL=https://evnluvzvbqmsmypbchym.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=你的anon_key
```

---

## 二、Google Play Console（支付 + 分发）

### 待完成
- [ ] **创建应用**
  - 包名: `com.jivemoney.app`
  - 上传签名 AAB 到内部测试轨道
- [ ] **创建应用内商品**（In-app products）
  - 一次性商品: `jive_paid_unlock` — ¥30 / $3.99（专业版解锁）
- [ ] **创建订阅**（Subscriptions）
  - `jive_subscriber_monthly` — ¥8 / $0.99/月
  - `jive_subscriber_yearly` — ¥68 / $8.99/年
- [ ] **设置测试账号**
  - Play Console → 设置 → 许可测试 → 添加 Gmail 测试账号
  - 测试账号购买不会真实扣款
- [ ] **内部测试**
  - 创建内部测试轨道 → 上传 AAB → 邀请测试者
  - 验证: 购买 → tier 更新 → 功能解锁 → 广告消失
- [ ] **上架审核**
  - 填写商店列表（截图、描述、隐私政策）
  - 提交审核

### 签名 AAB 构建
```bash
scripts/build_release_candidate.sh
```

GitHub Actions 推荐入口：`SaaS Release Candidate` workflow。

首次建议先用 `build_appbundle=false` 跑 dry-run，确认生产 Supabase、AdMob、支付 runtime flag 与签名策略都能通过门禁；准备上传商店时再使用 `build_appbundle=true` + `strict_signing=true`。

---

## 三、AdMob（广告变现）

### 待完成
- [ ] **注册 AdMob 账号**: https://admob.google.com
- [ ] **创建应用**
  - 平台: Android
  - 包名: `com.jivemoney.app`
- [ ] **创建广告单元**
  - Banner 广告单元 → 拿到真实 ad unit ID
- [ ] **替换测试 ID**
  - GitHub Actions Secret: `PRODUCTION_ADMOB_APP_ID`
  - GitHub Actions Secret: `PRODUCTION_ADMOB_BANNER_ID`
  - 本地 release candidate：写入 `/tmp/jive-saas-production.env`
  - debug/dev 构建默认保留 Google 测试 ID
- [ ] **验证**
  - debug 模式使用测试 ID（当前默认就是）
  - release 模式使用真实 ID

### 当前测试 ID（不要用于上架）
```
App ID:    ca-app-pub-3940256099942544~3347511713
Banner ID: ca-app-pub-3940256099942544/6300978111
```

---

## 四、国内分发渠道（Phase 2）

### 待完成
- [ ] **微信支付**
  - 注册微信开放平台 → 创建移动应用 → 申请微信支付
  - 需要: 营业执照 + 企业银行账户
  - 代码: 新增 `WechatPaymentService implements PaymentService`
- [ ] **国内广告 SDK**
  - 穿山甲（字节跳动）或优量汇（腾讯）
  - 需要: 企业资质认证
  - 代码: 新增 `ChinaAdService implements AdService` 抽象
- [ ] **应用商店上架**
  - 华为应用市场、小米应用商店、OPPO/vivo 等
  - 每个渠道需单独审核
- [ ] **iOS 上架**
  - App Store Connect → 创建应用
  - StoreKit 2 订阅配置
  - Apple 审核（内购 + 隐私政策要求严格）

---

## 五、上线前检查清单

- [ ] `SaaS Release Candidate` workflow dry-run 通过
- [ ] `scripts/check_saas_production_readiness.sh --profile full --store android --strict --require-release-signing --env-file /tmp/jive-saas-production.env` 通过
- [ ] GitHub Actions production secrets 已配置：Supabase、AdMob、Android 签名
- [ ] 所有测试 ID 替换为真实配置（AdMob 通过 production secrets / env 注入，Supabase 使用生产项目）
- [ ] 隐私政策页面上线（URL 填入 Play Console）
- [ ] 用户协议页面上线
- [ ] `flutter analyze` 0 errors
- [ ] `flutter test` 全部通过
- [ ] release APK/AAB 在真机验证一轮
- [ ] 购买流程端到端验证（测试账号）
- [ ] 广告在 release 模式正常展示
- [ ] Supabase Auth 注册/登录流程验证
- [ ] 云同步 push/pull 验证
- [ ] 订阅到期 → 降级验证
- [ ] 崩溃监控接入（Firebase Crashlytics 或 Sentry）

---

## 六、生产 Release Candidate Workflow

入口：GitHub Actions → `SaaS Release Candidate` → `Run workflow`

### 必需 Secrets

| Secret | 用途 |
|---|---|
| `PRODUCTION_SUPABASE_URL` | 生产 Supabase 客户端 URL |
| `PRODUCTION_SUPABASE_ANON_KEY` | 生产 Supabase anon key |
| `PRODUCTION_ADMOB_APP_ID` | Android Manifest AdMob App ID |
| `PRODUCTION_ADMOB_BANNER_ID` | Dart AdMob Banner unit ID |

### 可选 Secrets

| Secret | 用途 |
|---|---|
| `PRODUCTION_ADMIN_API_ALLOWED_ORIGINS` | full readiness / 管理端 origin 约束 |
| `PRODUCTION_PAYMENT_CHANNEL` | 默认可留空，workflow 会使用 `google_play` |

### 严格签名 Secrets

`strict_signing=true` 或准备上传商店时必须配置：

| Secret | 用途 |
|---|---|
| `ANDROID_RELEASE_KEYSTORE_BASE64` | release keystore 的 base64 内容 |
| `ANDROID_RELEASE_STORE_PASSWORD` | keystore password |
| `ANDROID_RELEASE_KEY_ALIAS` | key alias |
| `ANDROID_RELEASE_KEY_PASSWORD` | key password |

### 推荐执行顺序

1. `build_appbundle=false`、`strict_signing=false`：只跑生产配置门禁和 release report。
2. `build_appbundle=false`、`strict_signing=true`：确认签名 secrets 可用。
3. `build_appbundle=true`、`strict_signing=true`：生成可用于内部测试/商店上传的 prod AAB。

### Secrets 检查与上传

初始化本地生产 release env 文件：

```bash
scripts/init_saas_production_env.sh --env-file /tmp/jive-saas-production.env
```

可通过环境变量或参数填入生产 Supabase 与 AdMob 值；脚本会生成缺失的服务端运维 token，但不会打印 secret 值。

仅检查生产 release candidate 最小 secrets：

```bash
scripts/check_saas_github_secrets.sh --profile production-release --repo zensgit/jive
```

检查包含 Android 签名的完整 release secrets：

```bash
scripts/check_saas_github_secrets.sh --profile production-release --include-signing --repo zensgit/jive
```

从 `/tmp/jive-saas-production.env` 上传最小 release secrets：

```bash
scripts/push_saas_github_secrets.sh --profile production-release --repo zensgit/jive --env-file /tmp/jive-saas-production.env --apply
```

如果要同时上传可选 admin/payment 和 Android 签名 secrets：

```bash
scripts/push_saas_github_secrets.sh --profile production-release --include-optional --include-signing --repo zensgit/jive --env-file /tmp/jive-saas-production.env --apply
```

产物：

- `build/reports/release-candidate/latest.md`
- `build/reports/release-candidate/release-candidate.json`
- `build/release-candidate/.../*.aab`（仅 `build_appbundle=true`）

artifact guard 会阻止 `.env`、`.key`、credential、secret、dart-defines 等敏感文件进入上传产物。

---

## 七、SaaS 代码架构速查

```
lib/core/auth/          # 认证（GuestAuthService → 未来真实 provider）
lib/core/entitlement/   # 功能分级（UserTier, FeatureGate, GatedListTile）
lib/core/payment/       # 支付（PlayStorePaymentService, SubscriptionStatusService）
lib/core/ads/           # 广告（AdService, BannerAdWidget）
lib/core/sync/          # 云同步（SyncEngine, SyncConfig）

lib/feature/auth/       # 登录页壳
lib/feature/subscription/ # 订阅对比页
```

### 关键 Provider 注册（main.dart）
```dart
MultiProvider(
  providers: [
    ThemeProvider,
    AuthService,          // 当前: GuestAuthService
    EntitlementService,   // 三级门控
    PaymentService,       // Google Play IAP
    AdService,            // AdMob
    SyncEngine,           // Supabase 增量同步
  ],
)
```
