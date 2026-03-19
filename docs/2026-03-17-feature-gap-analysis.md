# Feature Gap Analysis: Jive vs Yimu (一木记账 v6.2.5)

> Generated 2026-03-17. Based on Jive `codex/post-merge-verify` @ `054df1e` vs yimu jadx decompile.

## Legend
- **P0** — 用户核心体验，上线前必须有
- **P1** — 竞争力功能，近期迭代
- **P2** — 差异化/锦上添花，可延后

## Current Jive Coverage

| Jive Module | Status | Notes |
|---|---|---|
| accounts | ✅ 完整 | CRUD + 对账 + 余额 + 多币种 |
| transactions | ✅ 完整 | 手动记账 + 编辑 + 复制 + 删除 |
| auto | ✅ 基础完整 | 通知抓取 + 草稿 + 规则 + 账户映射 |
| budget | ✅ 完整 | 月预算 + 结转 + 节奏分析 |
| category | ✅ 完整 | 系统分类 + 自定义 + 图标 |
| currency | ✅ 完整 | 多币种 + 在线汇率 |
| import | ✅ 完整 | 文件/文本/图片导入 + 预览 + 修复 |
| recurring | ✅ 完整 | 周期记账规则 + 调度 |
| tag | ✅ 完整 | 标签 CRUD + 合并 + 智能打标 |
| template | ✅ 基础 | 交易模板 |
| project | ✅ 基础 | 项目管理 |
| stats | ⚠️ 基础 | 单页面 663 行，有 fl_chart，但功能单薄 |
| settings | ⚠️ 混合 | 正式设置 + 大量治理原型（未接入主导航）|

## Gap Analysis

### P0 — 上线前必备

#### 1. 📊 统计图表增强 (stats)
**yimu**: 收支趋势、分类饼图、月度对比、年度汇总、资产变化曲线、日均消费、Top 分类排行
**Jive**: 只有一个基础统计页
**工作量**: 中 (3-5 天)
**建议**: 拆分成多个子页面：月度总览、分类分析、趋势图、年度报告

#### 2. 🔍 搜索 (search)
**yimu**: 全局搜索交易、分类、标签、备注
**Jive**: 有 `transaction_query_service`，但缺独立搜索入口
**工作量**: 小 (1-2 天)
**建议**: 新增全局搜索页，复用已有 query service

#### 3. 📤 导出 (billExport)
**yimu**: CSV/Excel 导出、自定义时间范围、分类筛选
**Jive**: 有 `data_backup_service`（JSON 备份），但缺用户友好的导出
**工作量**: 小 (1-2 天)
**建议**: 新增 CSV/Excel 导出，支持时间范围和筛选

### P1 — 竞争力功能

#### 4. 📅 日历视图 (calendar)
**yimu**: 日历形式查看每日收支
**Jive**: 无
**工作量**: 中 (2-3 天)
**建议**: 日历 Widget + 日详情列表

#### 5. 📚 多账本 (accountBook)
**yimu**: 多账本隔离（个人/家庭/旅行等）
**Jive**: 无独立账本概念，但有 project 模块可扩展
**工作量**: 大 (5-7 天)
**建议**: 可考虑用 project 概念扩展，或新建 book 模块

#### 6. 💰 分期管理 (instalment)
**yimu**: 信用卡分期、贷款分期追踪
**Jive**: 有 recurring 模块可部分覆盖
**工作量**: 中 (2-3 天)
**建议**: 在 recurring 基础上扩展分期专用字段和视图

#### 7. 🔄 退款管理 (refund)
**yimu**: 退款关联原交易、自动冲销
**Jive**: 无
**工作量**: 小 (1-2 天)
**建议**: 在交易详情里加退款操作，自动生成反向交易

#### 8. 🎨 主题定制 (theme)
**yimu**: 多套主题、自定义配色
**Jive**: 有 design_system 基础，但无用户切换入口
**工作量**: 中 (2-3 天)
**建议**: 新增主题选择页，预设几套配色方案

### P2 — 差异化/可延后

#### 9. 🎯 梦想/存钱目标 (dream)
**yimu**: 设定存钱目标、进度追踪、提醒
**Jive**: 无（settings 里有治理原型）
**工作量**: 中 (3-4 天)

#### 10. 📈 股票/投资 (stock)
**yimu**: 股票持仓、收益追踪
**Jive**: 无
**工作量**: 大 (5-7 天)

#### 11. 🔐 手势密码 (gesture)
**yimu**: 手势锁 + 生物识别
**Jive**: 无
**工作量**: 中 (2-3 天)

#### 12. 📱 桌面小组件 (widget)
**yimu**: Android Widget 显示今日收支
**Jive**: 无
**工作量**: 中 (3-4 天，需平台原生代码)

#### 13. 📝 笔记 (markdown)
**yimu**: Markdown 编辑器、与交易关联笔记
**Jive**: 无
**工作量**: 中 (2-3 天)

#### 14. 👤 登录/账号 (login)
**yimu**: 手机号/微信登录、数据同步
**Jive**: 同步层有本地基础，但无远端协议
**工作量**: 大 (7-10 天)

#### 15. 💎 VIP/会员 (vip)
**yimu**: 付费解锁高级功能
**Jive**: 无
**工作量**: 大 (5-7 天，需 IAP 集成)

## Recommended Development Phases

### Phase 1: 核心体验补齐 (P0, ~1 周)
1. 统计图表增强
2. 全局搜索
3. CSV/Excel 导出

### Phase 2: 竞争力提升 (P1, ~2 周)
4. 日历视图
5. 退款管理
6. 分期管理
7. 主题定制

### Phase 3: 差异化 (P2, ~3-4 周)
8. 多账本
9. 梦想/存钱目标
10. 手势密码
11. 桌面小组件

### Phase 4: 生态 (P2, 长期)
12. 登录/同步
13. 投资追踪
14. VIP/IAP
15. 笔记

## AI-enhanced Category Matching
yimu 使用 LinearSVM + HanLP 做分类推断。Jive 当前用 `tag_rule_service` 做规则匹配。
**建议**: 保持规则匹配为主，但可在 Phase 2 后期引入轻量 ML 模型提升自动分类准确率。
