# Jive v1.1.0 合并后开发及验证方案

> 日期: 2026-03-25
> 版本: `1.1.0+3`
> 分支: `codex/post-merge-verify`
> PR: #64

---

## 一、当前进度总览

### 已完成 ✅

| 里程碑 | 完成日期 | PR/Commit |
|--------|---------|-----------|
| Jive Voice 5 阶段合并（34 新文件 + 8 修改） | 2026-03-24 | MERGE_FINAL_REPORT.md |
| 48 处 `withOpacity` → `withValues(alpha:)` 修复 | 2026-03-25 | d1247cd |
| 7 个文件 `use_build_context_synchronously` lint 修复 | 2026-03-25 | d1247cd |
| 多账本 UI 联动（首页切换器 + bookId 过滤） | 2026-03-25 | d1247cd |
| WebDAV DataBackupService 桥接实现 | 2026-03-25 | d1247cd |
| PR #64 创建并推送 | 2026-03-25 | PR #64 |

### 搁置 ⏸️

| 项目 | 原因 | 解除条件 |
|------|------|---------|
| 百度语音配置 | 需要 API Key + build.gradle BuildConfig | 获取百度 AI 开放平台密钥 |
| 讯飞语音配置 | 需要 IFLYTEK_APP_ID/API_KEY/API_SECRET 环境变量 | 获取讯飞控制台密钥 |

### 待完成 🔲

| 项目 | 优先级 | 预计工作量 |
|------|--------|-----------|
| 设备编译验证 | P0 | 0.5 天 |
| 多账本深度联动 | P1 | 2 天 |
| 现有功能页面 bookId 适配 | P1 | 1 天 |
| 剩余 lint 清理 (~100 info) | P3 | 1 天 |
| FEATURE_DEVELOPMENT_PLAN 中未完成功能 | P2 | 持续 |

---

## 二、下一阶段开发计划

### 阶段 A：编译验证及回归测试（P0）

**目标**: 确保 PR #64 所有改动在真机上编译通过、功能正常。

| 步骤 | 命令/操作 | 预期结果 |
|------|----------|---------|
| 1. 依赖安装 | `flutter pub get` | 成功，0 错误 |
| 2. 代码生成 | `flutter pub run build_runner build --delete-conflicting-outputs` | 所有 .g.dart 生成成功 |
| 3. 静态分析 | `flutter analyze` | 0 error, ≤5 warning |
| 4. 编译 APK | `flutter build apk --debug --flavor prod` | APK 生成成功 |
| 5. 安装测试 | `adb install build/app/outputs/flutter-apk/app-prod-debug.apk` | Success |
| 6. 启动验证 | 手动打开应用 | 首页正常加载 |

#### 回归测试清单

| # | 测试项 | 验证方法 | 预期结果 |
|---|--------|---------|---------|
| 1 | 首页净资产显示 | 观察首页 | 金额正确显示 |
| 2 | 账本切换器 | 创建第二个账本后观察首页 | 出现切换器，切换后交易列表过滤正确 |
| 3 | 新建交易 | FAB → 输入 → 保存 | 交易保存成功，关联当前 bookId |
| 4 | 语音麦克风 | 交易页 AppBar 麦克风图标 | 可见，点击提示，长按触发 |
| 5 | AI 助手入口 | 菜单 → AI 助手 | 页面打开正常 |
| 6 | 商户记忆入口 | 菜单 → 商户记忆 | 页面打开正常 |
| 7 | 账本管理入口 | 菜单 → 账本管理 | 可创建/编辑/归档账本 |
| 8 | 分期管理入口 | 菜单 → 分期管理 | 可创建分期 |
| 9 | AA 分账入口 | 菜单 → AA 分账 | 可创建分账 |
| 10 | 储蓄目标入口 | 菜单 → 储蓄目标 | 可创建目标 |
| 11 | 账单关联入口 | 菜单 → 账单关联 | 可创建关联 |
| 12 | 应用锁 | 菜单 → 应用锁 → 设置 PIN | PIN 设置/验证流程正常 |
| 13 | 主题设置 | 设置 → 主题设置 | 颜色/字体/暗色模式切换正常 |
| 14 | 统计页面 | 底部导航 Stats | 图表正常显示 |
| 15 | 资产页面 | 底部导航 Assets | 账户余额正确 |
| 16 | 全局搜索 | 首页搜索图标 | 搜索结果正确 |
| 17 | 原有交易历史 | 滚动首页交易列表 | 历史数据完整 |

---

### 阶段 B：多账本深度联动（P1）

**目标**: 将 bookId 过滤扩展到统计、预算、导出等模块。

#### B.1 服务层适配

| 服务 | 修改内容 | 文件 |
|------|---------|------|
| StatsAggregationService | 所有统计方法追加 `int? bookId` 参数 | `lib/core/service/stats_aggregation_service.dart` |
| BudgetService | 预算列表/计算按 bookId 隔离 | `lib/core/service/budget_service.dart` |
| RecurringService | 周期交易关联 bookId | `lib/core/service/recurring_service.dart` |
| CsvExportService | 导出数据按 bookId 过滤 | `lib/core/service/csv_export_service.dart` |
| AutoDraftService | 草稿关联当前活动 bookId | `lib/core/service/auto_draft_service.dart` |
| TemplateService | 模板可选关联 bookId | `lib/feature/template/template_service.dart` |

#### B.2 UI 层适配

| 页面 | 修改内容 |
|------|---------|
| StatsHomeScreen | 接收并传递当前 bookId |
| AccountsScreen | 按 bookId 过滤账户列表 |
| BudgetManagerScreen | 按 bookId 显示预算 |
| GlobalSearchScreen | 可选按 bookId 搜索 |
| CsvExportScreen | 导出限定当前账本 |
| RecurringRuleListScreen | 显示当前账本的周期规则 |

#### B.3 验证

- [ ] 切换账本后统计数据正确隔离
- [ ] 切换账本后预算独立计算
- [ ] 新建交易/草稿自动关联当前 bookId
- [ ] 导出数据仅包含当前账本

---

### 阶段 C：功能完善及优化（P2）

#### C.1 WebDAV 同步 UI

当前 WebDAV 桥接已实现，但缺少用户配置界面。

| 任务 | 说明 |
|------|------|
| 新建 `webdav_settings_screen.dart` | WebDAV 服务器地址、用户名、密码配置界面 |
| 连接测试按钮 | 调用 `WebDavSyncService.testConnection()` |
| 手动备份/恢复按钮 | 调用 `uploadBackup()` / `downloadAndRestore()` |
| 自动备份开关 | 配置每日/每周自动备份 |
| 入口集成 | 设置页面 → 数据备份 → WebDAV 同步 |

#### C.2 引导页优化

| 任务 | 说明 |
|------|------|
| 首次启动检测 | SharedPreferences 标记，仅新用户展示 |
| 引导步骤 | 欢迎 → 基础币种 → 默认账户 → 完成 |
| 跳过按钮 | 允许跳过，进入主界面 |

#### C.3 商户记忆增强

| 任务 | 说明 |
|------|------|
| 自动学习 | 保存交易时自动更新商户记忆 |
| 交易页集成 | 备注输入时防抖查询 → 显示分类建议 Banner |
| 批量学习 | 从历史交易批量导入商户记忆 |

---

### 阶段 D：DEVELOPMENT_ROADMAP 对照（长期）

根据 `DEVELOPMENT_ROADMAP.md` 的 5 阶段规划，当前完成状况：

| 阶段 | 规划内容 | 当前状态 |
|------|---------|---------|
| Phase 1: 核心基础 | Isar 数据模型、TransactionService、MerchantService | ✅ 已完成 |
| Phase 2: 中国本地化 | 报销系统、分期管理、借贷 | ⚠️ 分期管理已有基础 UI，报销=账单关联，借贷=待开发 |
| Phase 3: 自动记账 | AccessibilityService、规则引擎、Overlay | ✅ 已完成（语音额外增强） |
| Phase 4: 投资追踪 | 证券、持仓、估值引擎、净值图表 | 🔲 未开始 |
| Phase 5: 迁移与打磨 | 数据导入、Dashboard、图表、暗色模式 | ⚠️ CSV 导入已完成，主题设置已有 |

根据 `FEATURE_DEVELOPMENT_PLAN.md`：

| 功能 | 状态 | 备注 |
|------|------|------|
| 模板功能 | ✅ 已完成 | `feature/template/` 已存在 |
| 标签系统 | ✅ 已完成 | `feature/tag/` 完整实现 |
| 项目追踪 | ✅ 已完成 | `feature/project/` 完整实现 |

#### 下一步可开发的新功能

| 功能 | 优先级 | 预计工作量 | 说明 |
|------|--------|-----------|------|
| **投资追踪模块** | P2 | 5-8 天 | 证券模型、持仓、估值引擎 |
| **借贷管理** | P2 | 3 天 | 借入/借出、还款追踪 |
| **通知提醒** | P2 | 2 天 | 周期交易到期、预算超限提醒 |
| **数据可视化增强** | P3 | 3 天 | 净值走势图、资产配置饼图 |
| **暗色模式完善** | P3 | 2 天 | 全部页面暗色适配 |
| **国际化 i18n** | P3 | 3 天 | 英文/中文切换 |

---

## 三、技术债务清理

| 项目 | 优先级 | 数量 | 说明 |
|------|--------|------|------|
| `use_build_context_synchronously` (现有文件) | P2 | ~60 处 | 非新增文件中的 lint |
| 其他 info lint | P3 | ~100 处 | `unnecessary_import`, `prefer_const_constructors` 等 |
| stub 服务文件 | P2 | 3 个 | `account_book_switch_sync_governance_service` 等需完善 |
| deprecated API | P3 | 已修复 | `withOpacity` 全部迁移完成 |

---

## 四、执行优先级排序

```
P0  阶段 A: 编译验证 + 回归测试
     │   确保当前代码在设备上可用
     ▼
P1  阶段 B: 多账本深度联动
     │   统计/预算/导出按 bookId 隔离
     ▼
P2  阶段 C: 功能完善
     │   WebDAV UI、引导页、商户记忆增强
     ▼
P2  技术债务清理
     │   lint 修复、stub 完善
     ▼
P2  新功能开发 (按需)
     │   投资追踪、借贷管理、通知提醒
     ▼
P3  长期优化
        暗色模式、国际化、数据可视化
```

---

## 五、风险评估

| 风险 | 等级 | 缓解措施 |
|------|------|---------|
| 多账本 bookId 全局过滤遗漏 | 高 | 逐服务审计，编写集成测试验证隔离性 |
| WebDAV 备份数据完整性 | 中 | 恢复后校验交易数量与账户余额 |
| Isar schema 变更后旧数据兼容 | 中 | 新字段全部 nullable，null = 默认账本 |
| 语音服务无 API Key 无法使用 | 低 | 已搁置，不影响其他功能；降级为提示用户配置 |
| 主线 merge 冲突 | 中 | PR #64 尽早合入 main |

---

## 六、文件变更追踪

### PR #64 包含的变更（66 文件）

#### 新增文件（45）

**模型层（12）**
```
lib/core/database/bill_relation_model.dart (+.g.dart)
lib/core/database/bill_split_model.dart (+.g.dart)
lib/core/database/book_model.dart (+.g.dart)
lib/core/database/installment_model.dart (+.g.dart)
lib/core/database/merchant_memory_model.dart (+.g.dart)
lib/core/database/savings_goal_model.dart (+.g.dart)
```

**服务层（16）**
```
lib/core/service/speech_service.dart
lib/core/service/iflytek_speech_service.dart
lib/core/service/speech_intent_parser.dart
lib/core/service/speech_capture_service.dart
lib/core/service/voice_quota_service.dart
lib/core/service/speech_settings.dart
lib/core/service/smart_input_service.dart
lib/core/service/merchant_memory_service.dart
lib/core/service/ai_assistant_service.dart
lib/core/service/app_lock_service.dart
lib/core/service/webdav_sync_service.dart
lib/core/service/book_service.dart
lib/core/service/csv_export_service.dart
lib/core/service/account_book_switch_sync_governance_service.dart
lib/core/service/account_book_delete_transfer_policy_service.dart
lib/core/service/import_edit_reconciliation_governance_service.dart
```

**功能页面（15）**
```
lib/feature/assistant/assistant_screen.dart
lib/feature/ai/nlp_input_sheet.dart
lib/feature/merchant/merchant_memory_screen.dart
lib/feature/security/lock_gate.dart
lib/feature/security/lock_screen.dart
lib/feature/security/pin_setup_screen.dart
lib/feature/onboarding/onboarding_screen.dart
lib/feature/installment/installment_list_screen.dart
lib/feature/installment/installment_form_screen.dart
lib/feature/split/bill_split_screen.dart
lib/feature/savings/savings_goal_screen.dart
lib/feature/bill_relation/bill_relation_screen.dart
lib/feature/books/book_manager_screen.dart
lib/feature/settings/theme_settings_screen.dart
lib/feature/settings/csv_export_screen.dart
```

#### 修改文件（21）
```
pubspec.yaml                           (+8 deps, version 1.1.0+3)
pubspec.lock
lib/main.dart                          (+账本切换器, +9 导航入口, +LockGate)
lib/feature/transactions/add_transaction_screen.dart (+语音 UI, +商户记忆, +bookId)
lib/core/database/transaction_model.dart (+bookId, +attachmentPaths)
lib/core/database/transaction_model.g.dart
lib/core/database/account_model.dart   (+bookId)
lib/core/database/account_model.g.dart
lib/core/model/transaction_query_spec.dart (+bookId)
lib/core/service/account_service.dart  (+bookId 过滤)
lib/core/service/database_service.dart (+7 schemas)
lib/core/service/transaction_query_service.dart (+bookId 过滤)
lib/feature/settings/settings_screen.dart (+主题设置入口)
lib/feature/stats/monthly_overview_screen.dart (withValues 修复)
lib/feature/stats/trend_chart_screen.dart (withValues 修复)
android/app/src/main/kotlin/.../MainActivity.kt (+speech channel)
android/app/src/main/AndroidManifest.xml (+RECORD_AUDIO, +INTERNET)
linux/flutter/generated_plugin_registrant.cc
linux/flutter/generated_plugins.cmake
macos/Flutter/GeneratedPluginRegistrant.swift
windows/flutter/generated_plugin_registrant.cc
```

---

*文档生成时间: 2026-03-25*
*分支: codex/post-merge-verify*
*Co-Authored-By: Claude Opus 4.6 (1M context)*
