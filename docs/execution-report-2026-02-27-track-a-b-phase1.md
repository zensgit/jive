# 执行报告：轨道 A+B 第一期（分期骨架 + 报销退款骨架）

时间：2026-02-27  
分支：`codex/next-batch-stability-core-v3`

## 本次完成内容

## 1) 分期能力骨架（轨道 A）
- 新增模型：`/Users/huazhou/Downloads/Github/Jive/app-next-batch/lib/core/database/installment_model.dart`
  - `JiveInstallment`（分期主表）
  - 分期枚举：`InstallmentFeeType` / `InstallmentRemainderType` / `InstallmentStatus` / `InstallmentCommitMode`
  - 计划行结构：`InstallmentPlanItem`
- 新增服务：`/Users/huazhou/Downloads/Github/Jive/app-next-batch/lib/core/service/installment_service.dart`
  - `createInstallment`：账户与参数校验、默认字段落盘
  - `buildPlanPreview`：本金/利息拆分（均分、首尾、取整/四舍五入余数归位）
  - `processDueInstallments`：按 `nextDueAt` 执行，支持 `draft`（写入 `JiveAutoDraft`）或 `commit`（写入 `JiveTransaction`）
  - 幂等去重：`dedupKey/recurringKey`

## 2) 报销/退款能力骨架（轨道 B）
- 新增模型：`/Users/huazhou/Downloads/Github/Jive/app-next-batch/lib/core/database/bill_relation_model.dart`
  - `JiveBillRelation`（原账单与报销/退款记录关联）
  - 枚举：`BillRelationType`
  - 汇总结构：`BillSettlementSummary`
- 新增服务：`/Users/huazhou/Downloads/Github/Jive/app-next-batch/lib/core/service/reimbursement_service.dart`
  - `createReimbursement`：生成关联入账记录
  - `createRefund`：生成退款记录，含单笔账单最多 25 次退款限制
  - `getSettlementSummary`：报销/退款数量与金额汇总
  - `getRelationsForSource` / `deleteRelation`

## 3) 数据库 schema 接入
- 更新：`/Users/huazhou/Downloads/Github/Jive/app-next-batch/lib/core/service/database_service.dart`
  - 新增注册 `JiveInstallmentSchema`
  - 新增注册 `JiveBillRelationSchema`
- 生成代码：
  - ` /Users/huazhou/Downloads/Github/Jive/app-next-batch/lib/core/database/installment_model.g.dart`
  - ` /Users/huazhou/Downloads/Github/Jive/app-next-batch/lib/core/database/bill_relation_model.g.dart`

## 4) 测试
- 新增测试文件：`/Users/huazhou/Downloads/Github/Jive/app-next-batch/test/installment_reimbursement_service_test.dart`
  - 覆盖分期计划拆分
  - 覆盖分期执行幂等（draft）
  - 覆盖分期执行并完成（commit）
  - 覆盖报销/退款链路与汇总
  - 覆盖退款次数上限（25）

已执行验证：
1. `flutter test test/installment_reimbursement_service_test.dart` -> Passed  
2. `flutter test test/budget_service_test.dart` -> Passed

## 下一步（建议）

1. 轨道 A 第二期：分期 UI（创建向导/详情页）与提前还款规则。  
2. 轨道 B 第二期：交易详情页展示“关联报销/退款”时间线与操作入口。  
3. 口径联动：统计页新增“支出（含退款）/报销净额”指标。  

