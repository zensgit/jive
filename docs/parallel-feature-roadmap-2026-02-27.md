# 并行功能开发路线图（基于 Yimu + Qianji 参考）

更新时间：2026-02-27  
仓库：`/Users/huazhou/Downloads/Github/Jive/app-next-batch`  
当前分支：`codex/next-batch-stability-core-v3`  
最近提交：`c513c99`（预算跨月复制：合并/覆盖）

## 1. 参考能力证据（高价值功能）

### 1.1 预算体系（Qianji）
- 复制其它月份预算：`budget_copy_from`、`budget_copy_rule_3`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:481`
- 自动复制与删除规则：`budget_copy_rule_1`、`budget_copy_rule_2`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:482`
- 年度预算/月度预算切换：`budget_annual`、`budget_monthly`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:479`

### 1.2 报销与退款链路（Qianji）
- 多次报销、多币种、支持退款：`baoxiao_upgrade_msg2`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:343`
- 报销管理页与入账规则：`title_baoxiao_manage`、`baoxiao_asset_account`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:2025`
- 退款收入/退款支出语义：`refund_income`、`refund_spend`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:1587`

### 1.3 分期 + 债务 + 信用卡（Qianji）
- 分期管理入口与全流程：`title_installment_manage`、`installment_plan`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:2146`
- 分期计入信用卡欠款/利息规则：`installment_incount_title`、`installment_fee_type_*`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:1191`
- 债务结束日期与资产负债联动：`asset_record_tips_debtloan_no_finish_date`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:173`

### 1.4 资产分组/资产趋势/资产负债表（Qianji）
- 资产分组管理：`asset_group_manage`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:130`
- 资产趋势：`asset_line_title`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:156`
- 资产负债表与负债率：`balance_sheet_title`、`balance_sheet_liability_ratio`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:315`

### 1.5 小组件矩阵 + 免息期（Qianji）
- 预算小组件、热力图、月汇总：`app_widget_desc_widget2x2`、`app_widget_desc_hotmap2x2`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:88`
- 免息期入口与算法文案：`grace_period_*`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:1013`

### 1.6 自动记账稳定性（Yimu/Qianji）
- 无障碍 + 通知 + 悬浮窗 + 保活策略  
  参考（Yimu）：`/Users/huazhou/Downloads/Github/Jive/references/yimu_apk_6_2_5_jadx/resources/res/values/strings.xml:30`  
  参考（Qianji）：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:224`
- Deep link 记账接口：`qianji://publicapi/addbill`  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:275`

### 1.7 共享账本权限（Qianji）
- Owner/User 权限分层  
  参考：`/Users/huazhou/Downloads/Github/Jive/references/qianji/qianji_decompiled/resources/res/values/strings.xml:456`

## 2. 与当前代码的缺口量化（关键词对比）

统计范围：`/Users/huazhou/Downloads/Github/Jive/app-next-batch/lib` 与参考代码。  

- `installment`：当前 `0`，参考 `1065`
- `debtloan`：当前 `0`，参考 `39`
- `baoxiao`：当前 `0`，参考 `509`
- `refund`：当前 `0`，参考 `243`
- `grace_period`：当前 `0`，参考 `144`
- `balance_sheet`：当前 `0`，参考 `145`
- `asset_group`：当前 `0`，参考 `128`
- `book_member`：当前 `0`，参考 `65`

结论：预算模块已经补齐关键一步（跨月复制），但“分期/债务、报销退款、资产负债、共享权限、小组件矩阵”仍是主要差距区。

## 3. 可并行开发轨道（建议直接并发）

## 轨道 A：分期与债务（高价值，核心竞争力）
- 目标：上线“信用卡分期 + 债务生命周期”MVP。
- 并行任务：
  1. 数据层：新增 `installment` / `debt` 模型、状态机、Isar migration。  
  2. 规则层：分期摊销算法（均分/首期/尾期/取整），提前还款结算。  
  3. UI 层：分期创建向导、分期详情、债务列表与结束日期修复提示。  
  4. 自动任务：月度入账执行器（幂等 + 重复保护）。
- 依赖：无外部依赖，可完全独立并行推进。
- 建议 owner：1 人数据/算法 + 1 人 UI/交互。

## 轨道 B：报销/退款链路（高频使用，回本快）
- 目标：支持“原账单 -> 报销记录 -> 退款记录”关联链。
- 并行任务：
  1. 数据结构：交易关联字段（sourceBillId、relationType、relationGroupKey）。  
  2. 服务逻辑：多次报销、部分退款、上限校验、跨币种限制。  
  3. 列表/详情：报销管理页、退款入口、原账单保护（限制改类型）。  
  4. 统计口径：新增“支出含退款/报销净额”指标。
- 依赖：仅依赖现有交易表，和轨道 A 解耦。
- 建议 owner：1 人服务层 + 1 人 UI/统计。

## 轨道 C：资产负债与趋势（差异化展示）
- 目标：上线资产趋势曲线 + 月度资产负债表 + 负债率。
- 并行任务：
  1. 资产快照计算器（月末快照、回溯纠偏、手动校准）。  
  2. Balance Sheet 聚合器（资产/短债/长债分组）。  
  3. 页面：资产趋势页、资产负债页、风险提示卡片。  
  4. 资产分组（可后置）：分组管理 + 排序。
- 依赖：需要账户类型语义稳定（当前已有 account type 基础）。
- 建议 owner：1 人计算引擎 + 1 人 UI 图表。

## 轨道 D：小组件矩阵（快速感知，提升留存）
- 目标：从“汇率组件”扩展到“预算/今日汇总/免息期”组件。
- 并行任务：
  1. 通用 Widget 数据通道抽象（复用现有 `rate_widget_service` 设计）。  
  2. 预算小组件（剩余额、超支预警）。  
  3. 今日/本月汇总小组件（收支卡片）。  
  4. 免息期小组件（依赖轨道 E 的免息期计算）。
- 依赖：Android 端 widget pipeline；iOS 可后续补。
- 建议 owner：1 人 Flutter 侧 + 1 人平台层。

## 轨道 E：信用卡免息期（中等投入，高感知）
- 目标：给信用卡账户增加账单日/还款日，计算“今日免息/最长免息”。
- 并行任务：
  1. 账户字段扩展（statementDay、repaymentDay）。  
  2. 免息期计算服务（按消费日输出天数）。  
  3. 资产页入口与最佳卡推荐。  
  4. 与轨道 D 联动：免息期组件。
- 依赖：只依赖账户模型，和 A/B/C 解耦。
- 建议 owner：1 人可独立完成 MVP。

## 轨道 F：共享账本权限（长期护城河）
- 目标：账本成员 + 角色权限（Owner/Member）。
- 并行任务：
  1. 账本与成员模型（book/member/role）。  
  2. 权限守卫（分类、预算、周期记账、邀请权限）。  
  3. 同步协议与冲突策略（若后端未就绪，可先做本地模拟层）。
- 依赖：需要后端协同，适合并行预研 + 本地接口抽象。
- 建议 owner：1 人客户端架构 + 1 人后端接口对齐。

## 4. 优先级与排期建议（并行）

第一批（立即开工）：
1. 轨道 A（分期/债务）  
2. 轨道 B（报销/退款）  
3. 轨道 E（免息期）  

第二批（A/B/E 基础稳定后）：
1. 轨道 C（资产负债）  
2. 轨道 D（小组件矩阵）  

第三批（中长期）：
1. 轨道 F（共享账本权限）

## 5. 验收标准（每条轨道最低要求）

统一标准：
1. 模型迁移可回滚，老数据不丢失。  
2. 新增服务层具备单测（关键算法 + 边界输入）。  
3. UI 有至少 1 条集成测试（核心路径）。  
4. 关键口径在文档中明确（统计口径、预算口径、退款口径）。  

## 6. 下一步执行建议

建议马上按并行方式进入开发：
1. 我先开 `轨道 A + 轨道 B` 的数据模型与服务层骨架（可最快形成可运行增量）。  
2. 同时你的另一窗口可开 `轨道 E`（免息期）UI 与账户字段扩展。  
3. 骨架合并后，再由我继续补测试与验收文档。

