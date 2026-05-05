# 本地功能运行模拟验证

- 日期：2026-05-05
- 基线：`origin/main` @ `0826d970`
- Worktree：`/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-local-feature-sim-20260505`
- 设备：Android Emulator `Jive_Staging_API35` / `emulator-5554`
- 构建：`devDebug`

## 范围

本轮目标是本地模拟主线功能是否可以启动、通过核心 SaaS/同步回归、完成 onboarding 到访客首页，并验证不会触发 Flutter/Android fatal crash。

本轮不连接真实生产 Supabase，不写入 GitHub secrets，不做正式签名发布。

## 发现与修复

`scripts/run_release_regression_suite.sh` 在当前 `main` 上引用了已删除的测试文件：

- `test/backup_restore_stale_session_regression_test.dart`
- `test/auth_stale_session_release_gate_test.dart`

这两个文件已在历史提交 `5f94de0` 中作为孤立测试删除，但 release regression 脚本未同步更新。本轮已移除 stale 路径，并补齐 `test/account_book_import_sync_conflict_report_service_test.dart`，覆盖账本导入同步冲突报告服务的 ready / review / block / export 行为。

## 命令与结果

### Release Candidate Dry Run

```bash
scripts/init_saas_production_env.sh \
  --env-file "$tmp_env" \
  --supabase-url https://jive-prod-review.supabase.co \
  --supabase-anon-key header.payload.signature \
  --admob-app-id 'ca-app-pub-1234567890123456~1234567890' \
  --admob-banner-id 'ca-app-pub-1234567890123456/1234567890' \
  --admin-origins https://admin.jive.example

PRODUCTION_ENV_FILE="$tmp_env" \
JIVE_RELEASE_CANDIDATE_DRY_RUN=true \
bash scripts/build_release_candidate.sh
```

结果：通过。

- `failures=0`
- `warnings=1`
- 唯一 warning：未配置 Android release signing，本地模拟预期允许
- `dryRun=true`
- `dartDefinesConfigured=true`

### Release Regression Suite

```bash
bash scripts/run_release_regression_suite.sh
```

结果：通过。

- `flutter analyze`：No issues found
- `flutter test`：40 tests passed

### SaaS UI / Service Smoke

```bash
flutter test \
  test/auth_screen_test.dart \
  test/auth_service_test.dart \
  test/entitlement_service_test.dart \
  test/feature_gate_test.dart \
  test/subscription_screen_test.dart \
  test/subscription_status_service_test.dart \
  test/sync_settings_screen_test.dart \
  test/ad_service_test.dart
```

结果：通过。

- 66 tests passed

### Android Emulator Build / Install / Runtime

```bash
flutter build apk --debug --flavor dev \
  --dart-define=SUPABASE_URL=https://jive-prod-review.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=header.payload.signature \
  --dart-define=ADMOB_BANNER_ID='ca-app-pub-1234567890123456/1234567890'
```

结果：通过。

- APK：`build/app/outputs/flutter-apk/app-dev-debug.apk`
- 安装：通过
- 启动：通过，进程 pid 可获取
- crash buffer：0 bytes

## 手工模拟路径

1. 冷启动 app。
2. 欢迎页可见，包含“跳过”和“下一步”。
3. 点击“跳过”进入“记一笔”步骤。
4. 分类网格可见，包含“餐饮、宠物、出差、服饰、公司、购物、护肤、家庭、交通”等。
5. 点击“餐饮”后点击“下一步”，成功进入“设分类”步骤。
6. 连续跳过剩余 onboarding。
7. 登录页底部点击“跳过，以游客身份使用”。
8. 二次确认“进入游客模式”。
9. 成功进入访客首页。

首页可见：

- `晚上好,`
- `访客`
- `净资产`
- `¥0.00`
- `收入 / 支出 / 转账 / 汇率`
- `最近交易`
- `还没有交易记录`
- `记一笔`
- 底部 `Home / Stats / Assets`

## 备注

- 本地第一次点击登录页底部坐标时误触 Google/Apple 第三方登录入口，验证中已返回 Jive 并通过滚动找到游客入口。
- Android logcat 中出现的 `AndroidRuntime` 行来自 `uiautomator` / `monkey` 命令进程，不是 Jive app crash；Jive crash buffer 始终为 0 bytes。
- 模拟使用的是假 Supabase/AdMob 参数，只验证本地启动和配置注入路径，不代表生产后端连通。

## 结论

本地功能运行模拟通过。当前 `main` 在本地可完成 release dry-run、核心同步/备份/会话回归、SaaS UI smoke、Android devDebug 构建安装、onboarding 到访客首页冷启动验证。
