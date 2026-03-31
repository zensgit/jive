# Phase B：功能打磨与 UI 优化开发计划

> 日期: 2026-04-01
> 基线: main @ PR #101
> 目标: 上架前的功能完善与体验打磨

---

## 一、UI 打磨（B1，1-2 周）

### B1-1：首页个性化（2-3h）
- [ ] 问候语按时段切换：早上好/下午好/晚上好
- [ ] 读取登录用户名显示，游客显示"访客"
- [ ] 问候语支持暗色模式颜色适配
- **文件**: `home_top_bar.dart`, `auth_service.dart`
- **PR**: 1 个

### B1-2：暗色模式全面适配（4-6h）
- [ ] 登录页 `auth_screen.dart` 暗色适配
- [ ] 订阅对比页 `subscription_screen.dart` 暗色适配
- [ ] 同步设置页 `sync_settings_screen.dart` 暗色适配
- [ ] 语音设置页 `speech_settings_screen.dart` 暗色适配
- [ ] 菜单 sheet `home_menu_sheet.dart` 暗色适配
- [ ] 升级提示弹窗 `feature_gate.dart` 暗色适配
- [ ] GatedListTile 锁 icon 暗色颜色
- **原则**: 用 `Theme.of(context).colorScheme` 替代硬编码颜色
- **PR**: 2-3 个（按页面分批）

### B1-3：空状态美化（2-3h）
- [ ] 首页无交易：引导性文案 + "记第一笔"按钮
- [ ] 统计页无数据：提示文案
- [ ] 资产页无账户：引导创建
- **文件**: `home_recent_transactions_section.dart`, stats/accounts 相关
- **PR**: 1 个

### B1-4：交易列表按日期分组（4-6h）
- [ ] Recent Transactions 按日期分组显示
- [ ] 每日分组头显示日期 + 日支出/收入小计
- [ ] 今天/昨天/前天使用友好文案
- [ ] 保持 `home_view_all_transactions_button` key
- **文件**: `home_recent_transactions_section.dart`
- **PR**: 1 个

### B1-5：金额显示优化（2-3h）
- [ ] 净资产数字加载时淡入动画
- [ ] 大金额自动缩放（万/亿单位）
- [ ] 负资产红色显示
- **文件**: `home_asset_card.dart`
- **PR**: 1 个

### B1-6：记账页体验优化（3-4h）
- [ ] 分类选择后自动聚焦金额键盘
- [ ] 常用分类置顶/最近使用排序
- [ ] 保存成功后轻微触觉反馈
- [ ] 金额输入支持计算器（已有 +/- 按钮，确认可用性）
- **文件**: `add_transaction_screen.dart`
- **PR**: 1-2 个

---

## 二、云同步完善（B2，1 周）

### B2-1：多表同步（6-8h）
- [ ] 新增 Supabase 表: accounts, categories, tags, budgets
- [ ] SQL 迁移文件: `002_create_sync_tables.sql`
- [ ] SyncEngine 扩展: 支持多表 push/pull
- [ ] 每张表独立同步游标
- **PR**: 2 个（SQL + 代码）

### B2-2：同步冲突 UI（3-4h）
- [ ] 冲突时显示本地 vs 远程对比
- [ ] 用户选择保留哪个版本
- [ ] 或自动 last-write-wins + 日志记录
- **文件**: `sync_engine.dart`, 新建 `sync_conflict_sheet.dart`
- **PR**: 1 个

### B2-3：自动同步触发（2-3h）
- [ ] 数据变更后自动触发同步（debounce 30s）
- [ ] App 回到前台时自动同步
- [ ] 同步进度指示器（首页或状态栏）
- **文件**: `sync_engine.dart`, `main_screen_controller.dart`
- **PR**: 1 个

### B2-4：离线队列（3-4h）
- [ ] 离线时本地操作进入队列
- [ ] 恢复网络后自动 flush
- [ ] 队列持久化（防 app 被杀）
- **文件**: 新建 `sync_queue.dart`
- **PR**: 1 个

---

## 三、iOS 适配（B3，1-2 周）

### B3-1：基础 iOS 构建（2-3h）
- [ ] 确认 `flutter build ios` 可编译
- [ ] 修复 iOS 特有的 platform channel 问题
- [ ] CocoaPods 依赖解析
- **需要**: macOS + Xcode + Apple Developer 账号

### B3-2：iOS 支付（4-6h）
- [ ] StoreKit 2 配置
- [ ] App Store Connect 创建订阅商品
- [ ] `AppStorePaymentService implements PaymentService`
- **PR**: 1 个

### B3-3：iOS 特有适配（3-4h）
- [ ] 推送通知权限（iOS 需要单独请求）
- [ ] Face ID / Touch ID 适配（已有 local_auth）
- [ ] App Store 审核要求（恢复购买按钮位置等）
- **PR**: 1-2 个

### B3-4：iOS 上架（2-3h）
- [ ] App Store Connect 创建应用
- [ ] 截图（6.7" + 5.5"）
- [ ] 隐私政策 + 审核描述
- [ ] 提交审核

---

## 四、国内广告 SDK（B4，3-5 天）

### B4-1：穿山甲 SDK 集成（4-6h）
- [ ] 注册穿山甲开放平台 + 创建应用
- [ ] 添加 `pangolin_flutter` 或原生 channel
- [ ] `ChinaAdService implements AdService`
- [ ] 按地区自动选择 AdMob / 穿山甲
- **PR**: 2 个

### B4-2：广告位优化（2-3h）
- [ ] 交易列表内穿插原生广告（每 10 条一个）
- [ ] 升级提示页底部插屏广告
- [ ] 广告加载失败时静默降级
- **PR**: 1 个

---

## 五、其他功能完善（B5，持续）

### B5-1：通知系统（3-4h）
- [ ] 预算超支通知
- [ ] 周期记账到期提醒
- [ ] 每日/每周记账提醒（可配置）
- **文件**: `reminder_service.dart`, Android notification channel

### B5-2：数据导出增强（2-3h）
- [ ] PDF 年度报告（订阅功能）
- [ ] Excel 导出（.xlsx）
- [ ] 导出时间范围可选

### B5-3：统计页增强（4-6h）
- [ ] 月度对比趋势图
- [ ] 分类占比饼图下钻
- [ ] 支出热力图（按星期/小时）

### B5-4：搜索增强（2-3h）
- [ ] 全局搜索支持金额范围
- [ ] 搜索历史记录
- [ ] 搜索结果高亮关键词

---

## 六、执行节奏建议

| 周次 | 内容 | PRs |
|---|---|---|
| **Week 1** | B1-1 首页个性化 + B1-2 暗色模式 + B1-3 空状态 | 4-5 |
| **Week 2** | B1-4 日期分组 + B1-5 金额优化 + B1-6 记账体验 | 3-4 |
| **Week 3** | B2-1 多表同步 + B2-3 自动同步 | 3 |
| **Week 4** | B2-2 冲突 UI + B2-4 离线队列 + B3-1 iOS 基础 | 3-4 |
| **Week 5-6** | B3 iOS 完整适配 + B4 国内广告 | 5-6 |
| **持续** | B5 按优先级推进 | — |

---

## 七、验收标准

每个 PR 必须：
- [ ] `flutter analyze` 0 errors, 0 warnings
- [ ] 相关 `flutter test` 通过
- [ ] 真机截图验证（如涉及 UI）
- [ ] 暗色模式下截图验证（如涉及 UI）
- [ ] 不破坏现有 key（`home_view_all_transactions_button` 等）
