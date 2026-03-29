# Jive 当前可执行开发路线图

> 日期: 2026-03-29
> 基线: `main` @ `2ce62cc`（PR #72 合并后）
> 目的: 将一份已部分过时的开发报告，重写为当前仓库可执行版本

---

## 一、结论先行

原始报告可以作为思路素材，但不能按原样执行。

原因有三类：

1. 部分任务已经在 `main` 落地
2. 部分“待合并分支”在当前仓库视图里已不可直接作为执行对象
3. 部分任务的复杂度被低估，或在执行中已被提前消化

因此，当前更合理的做法不是“照单 merge”，而是先做一次去过时化，再按稳定性、迁移风险、功能增量三个层次重新排期。

---

## 二、与当前代码不一致的地方

### 1. 已完成，不应再作为待办

| 报告项 | 当前状态 | 依据 |
|---|---|---|
| 合并 Import Center | 已在 `main` | `lib/feature/import/import_center_screen.dart`、`lib/core/database/import_job_model.dart`、多组 `test/import_*` 与 `integration_test/import_*` |
| 新增 `flutter_ci.yml` | 已存在 | `.github/workflows/flutter_ci.yml` 已包含 `analyze_and_test` 与 `android_integration_test` |
| 投资模块新增 `latestPrice/priceUpdatedAt` | 已存在 | `lib/core/database/investment_model.dart` |
| 投资模块手动价格更新 | 已存在 | `lib/core/service/investment_service.dart` 的 `updatePrice()` |
| `installment/instalment` 双栈收敛 | 已由 PR #71 完成 | 英式拼写孤立模块已删除，保留 `installment` 作为唯一实现 |

### 2. 仍然成立，但需要重估工作量

| 报告项 | 当前判断 | 原因 |
|---|---|---|
| `main.dart` 拆分 | 真实技术债 | 当前文件约 2776 行，路由、初始化、Provider 配置混在一起 |
| 空 `catch` 清理 | 值得优先做 | 当前仍有多处空 `catch`/吞异常 |
| 空 `setState(() {})` 清理 | 值得优先做 | 当前仍有多处空刷新 |
| 语音 API 配置 UI | 可以做 | 语音引擎和偏好设置已有基础设施，但缺更完整配置入口 |

## 三、当前仓库的真实优先级

### P0：先恢复工程基线

这一步不是最“显眼”，但最值钱。

如果 `flutter analyze` 基线长期不稳，后续每个 PR 都会重复背锅，评审和 CI 成本会持续放大。

#### 建议任务

1. 清理当前 analyzer/CI 的主干红灯
2. 修复一批高价值空 `catch`
3. 修复一批高价值空 `setState(() {})`
4. 为这些修复补最小回归测试

#### 建议范围

- `lib/core/service/auto_permission_service.dart`
- `lib/core/service/currency_service.dart`
- `lib/core/service/webdav_sync_service.dart`
- `lib/feature/installment/installment_form_screen.dart`
- `lib/feature/transactions/add_transaction_screen.dart`
- `lib/feature/settings/webdav_settings_screen.dart`
- `lib/feature/merchant/merchant_memory_screen.dart`

#### 预估

- 1 到 2 天

#### 验收

- `flutter analyze` 主干问题显著收敛
- `rg "setState\\(\\s*\\(\\)\\s*\\{\\s*\\}\\s*\\)" lib` 结果明显下降
- 明确列出的空 `catch` 变成带日志或带注释的可解释处理

---

## 四、建议的新执行阶段

### Phase A：稳定性基线清理（P0，1-2 天）— 代码改动已合并，待 analyze 验证

#### 目标

把”每次开发都会遇到的噪音”先压下去，让后续功能开发变便宜。

#### 任务与完成状态

1. ✅ 修复高优先级空 `catch` — PR #70 (merged), 本次选中的 13 处已替换为 debugPrint；仓库中仍有其他 catch 块，属正常错误处理而非空吞
2. ✅ 修复高优先级空 `setState` — PR #70 (merged), 本次选中的 22 处已消除
3. ✅ 校正 CI 文档与现状表述 — PR #72 (merged), 69 个本地重复 docs 已清理，roadmap 已入库并同步修正
4. ✅ 梳理当前 `flutter analyze` 的真实 blocker — PR #70 (merged), 修复 .g.dart 重复 case + schema 重复条目
5. ✅ 额外完成: 删除孤立 instalment 模块 — PR #71 (merged), -1678 行

#### 待验证

- `flutter analyze` 尚未在有 Flutter SDK 的环境实际运行，需补跑确认无新增 error

---

### Phase B：分期双栈收敛方案 — ✅ 已提前完成，跳过

#### 原定目标

先把 `installment` 与 `instalment` 的边界讲清楚，再决定怎么迁移。

#### 实际结果

PR #71 (merged) 已完成收敛：

- 孤立的 `instalment`（British）模块已整体删除（model/service/screen/schema，-1678 行）
- 保留 `installment`（American）作为唯一实现（24 字段 model、435 行 service、3 个 screen）
- `instalment` 从未接入 main.dart 路由，无生产数据风险
- `grep -ri instalment lib/` 结果为零

原定的 5 项子任务（引用图、依赖确认、迁移策略、兼容期、迁移文档）因实际情况简单而一步到位：旧栈是死代码，直接删除即可，无需数据迁移。

---

### Phase C：已有能力补齐，而非重复建设（P1，2-3 天）

#### 目标

在现有基础设施上补洞，不重复造轮子。

#### 建议任务

1. 语音配置入口完善
2. 语音服务商选择和偏好展示
3. 如果需要，再扩展 API Key 配置存储方案

#### 当前基础

- `lib/core/service/speech_service.dart`
- `lib/core/service/speech_settings.dart`
- 交易页已有语音引擎选择路径

#### 注意

先确认百度/讯飞的实际接入策略，再决定 UI 字段设计，不要只按旧报告里的字段名机械落地。

---

### Phase D：主入口拆分（P2，3-5 天）

#### 目标

拆分 `main.dart`，降低改动半径。

#### 建议拆分方向

- `lib/main.dart`
- `lib/app/jive_app.dart`
- `lib/app/app_router.dart`
- `lib/app/app_providers.dart`
- `lib/app/app_initializer.dart`

#### 前置条件

- Phase A 完成
- 当前主干 analyze 基本稳定

#### 原因

在基线不稳时做大拆分，会让问题定位成本成倍上升。

---

### Phase E：重新定义“功能完善”清单（P2，持续）

这一步不建议直接沿用旧报告。

应该先基于当前 `main` 重新做一次功能 gap audit，再决定是否继续推进：

1. 投资模块剩余缺口
2. 统计页能力不足
3. 全局搜索入口与深度搜索体验
4. 导出与报表
5. 语音记账闭环

其中“投资模块完善”要改成下面这种问法，而不是沿用旧任务名：

- 当前投资模块还缺什么用户可见能力
- 哪些是体验缺口，哪些是模型缺口
- 哪些可以在不改 schema 的前提下先补上

---

## 五、建议删除或暂停的旧任务

以下内容不建议继续按原文执行：

1. “合并 Import Center”
2. “新增 flutter_ci.yml”
3. “投资模块新增 `priceUpdatedAt` / 手动价格更新”
4. “按旧报告中的分支名逐个 cherry-pick”

原因不是方向错，而是当前主干状态已经变化。

---

## 六、建议保留的执行原则

1. 小步提交，小 PR，避免超大合并包
2. 先稳定性，后迁移，再做新功能
3. 对所有“看起来像待办”的项目先做主干存在性核对
4. 高风险迁移先出文档再改代码

---

## 七、我给出的实际排期建议

### 本周建议

1. 完成 Phase A
2. 在有 Flutter SDK 的环境补跑 `flutter analyze`
3. 如 analyze 无新增 error，直接进入 Phase C

### 不建议本周做的事

1. 直接拆 `main.dart`
2. 在未补跑 analyze 前启动大规模架构拆分
3. 继续按旧分支名单做 cherry-pick

---

## 八、下一步最值得做的事

如果只选一个下一步，我建议：

**先在有 Flutter SDK 的环境补跑 `flutter analyze`，确认 Phase A 的代码修复已完全收口。**

确认无新增 error 后，直接进入 Phase C。
