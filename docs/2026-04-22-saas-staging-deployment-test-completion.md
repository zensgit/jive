# SaaS Staging 部署测试完成报告

日期：2026-04-22
基线：`main` @ `cede4903a649288373d1359e93ced0e3208c6666`

## 结论

SaaS staging 部署测试按本轮口径已完成。

- GitHub Actions `Main Flutter CI` 在目标提交上保持 green。
- `SaaS Core Staging` 的 dry-run、migration apply、Functions deploy + smoke、core sync smoke、dev debug APK build 均成功。
- Staging debug APK 已下载、校验 SHA-256、安装到 Android emulator，并完成冷启动与最小业务 smoke。
- App 侧验证覆盖首页、设置页、订阅页、免费用户云同步门控、订阅测试态云同步入口、邮箱注册登录、手动新增交易与 logcat fatal 扫描。
- 本轮未进入正式商业上线范围，生产支付、Apple 真验票、国内支付生产链路、admin dashboard、通知外发、E2EE 仍属于后续阶段。

## GitHub Actions

| 验证项 | Workflow run | 结果 | 备注 |
|---|---:|---|---|
| Main Flutter CI | `24786058708` | PASS | `cede490` 对应 CI green |
| SaaS Core Staging dry-run | `24786684182` | PASS | `apply_migrations=false`、`deploy_functions=false`、`run_sync_smoke=false`、`build_apk=false` |
| Staging migration apply | `24786733056` | PASS | `apply_migrations=true`，其余 destructive/optional 项关闭 |
| Functions deploy + smoke | `24786787918` | PASS | `analytics`、`send-notification`、`admin` deploy；function smoke 全部 PASS |
| Core sync smoke | `24786855136` | PASS | accounts / transactions / budgets push-pull-tombstone 全部 PASS |
| Staging dev debug APK build | `24786990813` | PASS | artifact guard 通过，APK build metadata 完整 |

## Backend Smoke 明细

Functions smoke 覆盖：

- `analytics` 缺 admin token 返回 `401`。
- `analytics` summary 携带 admin token 返回 `200`。
- `admin` 缺 admin token 返回 `401`。
- `admin` summary 携带 admin token 返回 `200`。
- `send-notification` dry-run 携带 notification token 返回 `200`。

Core sync smoke artifact：

- Artifact：`saas-staging-reports-24786855136`
- Artifact ID：`6581901985`
- Artifact digest：`91e45f57fd8bd3a1b25e4a4a5878bb0247661d8f36b1c810600aa944fe0b0995`
- Local artifact path：`/tmp/jive-saas-sync-run-24786855136/saas-staging-reports-24786855136/reports/saas-staging/sync-smoke-20260422-152441`
- Summary：`status PASS`
- Secret scan：clean

Core sync smoke 覆盖：

- admin user create
- anon email sign-in session 1 / session 2
- account insert + second session pull by `sync_key`
- transaction insert + second session pull by `sync_key`
- transaction `account_sync_key` round trip
- budget insert + second session pull by `sync_key`
- transaction tombstone update
- budget tombstone update
- cleanup complete

## APK Artifact

APK build run：`24786990813`

- Artifact：`saas-staging-reports-24786990813`
- Artifact ID：`6582162780`
- Artifact digest：`79b1b8e5bb6bed5e53110c2336e6c1794bfbdfd21ffc90c7f20636ddc7297ef6`
- APK local path：`/tmp/jive-saas-apk-run-24786990813/saas-staging-reports-24786990813/saas-staging/20260422-152735-dev-debug/app-dev-debug.apk`
- APK bytes：`253776681`
- APK SHA-256：`16aff55dbed7b1cffa9b83467f67930359e4f1fb8746195fdde3d26b4dcecad9`
- Build metadata：`/tmp/jive-saas-apk-run-24786990813/saas-staging-reports-24786990813/reports/saas-staging/saas-staging-build.json`
- Latest summary：`/tmp/jive-saas-apk-run-24786990813/saas-staging-reports-24786990813/reports/saas-staging/latest.md`
- `supabaseUrlConfigured=true`
- `supabaseAnonKeyConfigured=true`
- `serviceRolePassedToClient=false`

## Android Device Smoke

设备：

- Emulator：`Jive_Staging_API35`
- Serial：`emulator-5554`
- Model：`sdk_gphone64_arm64`
- Android：15
- Resolution：`1080x2400`

安装与启动：

- 首次安装命中旧签名包冲突，脚本按显式参数完成旧数据备份后卸载重装。
- Backup path：`/tmp/jive-saas-device-smoke-24786990813/backups/com.jivemoney.app.dev-appdata-20260422-233944.tar`
- Installed package：`com.jivemoney.app.dev`
- versionCode：`2109614529`
- versionName：`1.1.0-20260422-1529`
- 首次 12 秒检测仍停留在 splash，重试 45 秒等待后 PASS。
- Device smoke summary：`/tmp/jive-saas-device-smoke-24786990813-retry45/summary.md`
- Detected screen：`home`
- Fatal log scan：clean

App 最小业务 smoke：

- 首页可打开，识别到 `净资产`、`最近交易`、`记一笔`。
- 设置页可打开，识别到 `账户与订阅`、`云同步设置`、`分类图标风格`。
- 订阅页可打开，识别到 `当前方案 免费版`、`专业版`。
- 免费用户点击 `云同步设置` 被 FeatureGate 拦截，展示 `此功能需要订阅版`。
- 本地订阅测试态可进入 `云同步设置`，页面展示 `请先登录`、`同步状态`、`同步控制`，说明 subscriber gate 已放行且登录前置提示正确。
- Auth 入口可打开，识别到邮箱/手机号登录、Google/Apple 登录、游客模式说明。
- 随机 staging 邮箱注册后进入首页，顶部显示注册账号名，说明邮箱注册/登录链路可用。
- 手动新增一笔 `¥12.00` 支出后，首页最近交易显示 `表情 未分类 • 04-22 23:43 - ¥12.00`。
- 最终 logcat fatal scan：clean。

本机 smoke artifacts：

- App smoke root：`/tmp/jive-saas-app-smoke-24786990813`
- Home screenshot：`/tmp/jive-saas-app-smoke-24786990813/01-home.png`
- Sync gate screenshot：`/tmp/jive-saas-app-smoke-24786990813/05-sync-gate.png`
- Transaction result screenshot：`/tmp/jive-saas-app-smoke-24786990813/09-after-save.png`
- Auth entrance screenshot：`/tmp/jive-saas-app-smoke-24786990813/11-auth-entrance-after45.png`
- Subscriber sync settings screenshot：`/tmp/jive-saas-app-smoke-24786990813/18-subscriber-sync-settings.png`

## 跳过或不阻塞项

- 实体机 `531cb562` 当前为 `unauthorized`，本轮使用 emulator 完成安装与交互验证；这符合“emulator 或实体机”的验收口径。
- 本轮未做生产支付、Apple 生产收据验证、微信/支付宝生产链路、正式发版材料、admin dashboard、通知外发、E2EE。
- 本轮未做双实体设备同步 UI 验证；跨会话云同步能力已由 `run_sync_smoke=true` 的 backend smoke 覆盖。

## 后续建议

- 将 fresh debug build 首次冷启动检测等待从 12 秒提高到 45 秒，或在 smoke 脚本里轮询 UI 文案，避免 splash 阶段误判。
- 后续如要进入正式上线，应单独开生产发布计划，重点补齐真实支付验票、隐私合规、Crash/Analytics、生产 Supabase 项目和发布物料。
