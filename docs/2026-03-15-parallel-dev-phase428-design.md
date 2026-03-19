# Phase428 Design

## Background
- Phase427 已经补齐了结构化字段和 repair fan-out，但 transfer import 仍然只有基础 `type` 语义。
- 对标 `/Users/huazhou/Downloads/Github/Jive/references/yimu_apk_6_2_5_jadx` 可见，yimu 至少在 transfer import 里保留了转出账户、转入账户、金额、手续费、备注这些最小闭环字段。
- 当前 Jive 已有 `ImportCenter -> AutoDraftService` 真实导入链路，因此本轮优先把 transfer 字段接进现有主线，而不是新开一条高风险的 transfer 专用 flow。

## Design
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
  - 为 `ImportParsedRecord` 增加 `toAccountName`、`serviceCharge`。
  - 在 CSV header alias 解析、header 检测、warning 和 transfer type 推断中纳入这两个字段。
  - prepared import 时把 transfer 字段透传给 `AutoCapture`。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`
  - 列映射新增 `toAssetColumnIndex`、`serviceChargeColumnIndex`。
  - 列映射预览修复支持显式选择 `转入账户列`、`手续费列`。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`
  - `AutoCapture` 新增 transfer 字段。
  - draft metadata 持久化 `transferToAccountName`、`transferServiceCharge`。
  - confirm draft 时把 metadata 回填到 transaction transfer fields。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart`
  - fan-out 同步传播转入账户和手续费。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
  - 记录编辑新增 `转入账户`、`手续费`。
  - 预览 chips 展示 transfer 结构化字段。
  - review checklist CSV 增加 transfer 列。
- 新增 Android 集成用例
  - `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_preview_flow_test.dart`
  - 覆盖 `ImportCenter` 预览、确认导入、draft metadata 验证。
- 补稳定导航 selector
  - `/Users/huazhou/Downloads/Github/Jive/app/lib/main.dart` 为 Home 页 `View All` 增加固定 key。
  - `/Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart` 与 `/Users/huazhou/Downloads/Github/Jive/app/integration_test/calendar_date_picker_flow_test.dart` 改走 key-first 选择器，避免被英文文案或渲染时序影响。

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/main.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_csv_mapping_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_center_screen_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_record_repair_fanout_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/calendar_date_picker_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_preview_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_transfer_preview_pipeline_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_transfer_metadata_bridge_mvp.md`

## Tradeoff
- 本轮只补最小 transfer import 语义，没有强行引入 yimu 的 repayment 特判、费用分拆单据或独立 transfer editor 页面。
- review checklist 的 transfer CSV 验证主要依赖 service 测试和 Android 集成测试，没有继续硬撑一条脆弱 widget 导出用例。
- 先把 transfer 字段稳定穿过现有 pipeline，再决定是否拆新的 production transfer flow，风险更低。
