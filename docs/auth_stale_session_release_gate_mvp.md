# Auth Stale Session Release Gate MVP

## 目标

把认证成功后的陈旧会话风险收敛为一组可执行的 release gate，用例覆盖：

1. stale callback write 没被 lease gate 阻断
2. stale credential bundle 没有失效清理
3. token rotation 要求存在但改密后未真正更新
4. email/token/credential/user bundle 的健康路径仍可直接放行

## 本轮落地

- 新增回归测试：`/Users/huazhou/Downloads/Github/Jive/app/test/auth_stale_session_release_gate_test.dart`
- 复用既有治理服务：
  - `credential_bundle_lease_governance_service.dart`
  - `credential_bundle_version_reconciliation_governance_service.dart`
  - `password_modify_response_integrity_governance_service.dart`
  - `email_credential_bundle_consistency_governance_service.dart`

## 关键策略

- 不再只看单个治理 service 绿不绿，而是把 4 条结果组合成上线前 release gate
- 任何 stale callback / stale bundle / token rotate 缺口都视为 review，不允许静默放行
- 健康路径要求四类治理同时 ready
