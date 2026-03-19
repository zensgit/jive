# Phase429 Design

## Background
- Phase428 已经把 transfer import 的字段穿过了 `ImportCenter -> AutoDraftService` 主链路，但确认导入前仍缺少一层面向转账语义的 submit gate。
- 参考 `/Users/huazhou/Downloads/Github/Jive/references/yimu_apk_6_2_5_jadx`，转账导入至少要守住“目标账户存在”和“不能同账户互转”这类最小业务约束。
- 当前 Jive 的 confirm flow 是 `ImportCenter -> ImportService.importPreparedRecords() -> AutoDraftService.ingestCapture()`，因此最稳的插入点是在 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart` 的 `_confirmImportPrepared()` 之前。

## Design
- 新增 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_transfer_confirm_service.dart`
  - 输入 `ImportParsedRecord` 列表和当前有效账户名集合。
  - 只处理 `transfer` 记录。
  - 输出 `ImportTransferConfirmResult`，包含：
    - `selectedCount`
    - `transferCount`
    - `readyCount`
    - `reviewCount`
    - `blockCount`
    - `issues`
  - issue 分两级：
    - `block`
    - `review`
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
  - 在 `_confirmImportPrepared()` 先调用 transfer confirm gate。
  - 阻断项存在时，仅允许“返回检查”。
  - 待确认项存在时，允许“继续导入”。
  - 无 transfer 或全部 ready 时，保持原确认导入行为。
- 新增 host / Android 验证
  - `/Users/huazhou/Downloads/Github/Jive/app/test/import_transfer_confirm_service_test.dart`
  - `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_guard_flow_test.dart`
  - Android 侧覆盖“缺少转入账户时弹阻断框且不生成 draft”。

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_transfer_confirm_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_transfer_confirm_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_guard_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_transfer_confirm_gate_mvp.md`

## Tradeoff
- 本轮没有把 transfer confirm gate 深入到最终 transaction commit 层，因为当前真实提交仍在 auto draft confirm 阶段，先把 import submit gate 做稳更低风险。
- review 级别问题允许继续导入，这是刻意保留人工兜底，而不是把所有可疑数据一刀切阻断。
- Android 用例优先覆盖最关键的 block 场景；更复杂的 unknown account / fee ratio 组合，先放在 host service test 里做完整枚举。
