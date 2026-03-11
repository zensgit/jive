# 邮箱注销治理（MVP）

## 背景
- 对标 yimu `EmailDeleteUserActivity`，补齐验证码核验、清理前置、冷静期与会话治理门禁。

## 输入
- `accountId/email/currentSessionValid`
- `emailVerified/verificationCodeSent/verificationCodeValidMinutes`
- `clearDataReady/backupConfirmed/confirmTextMatched`
- `deletionCooldownHours/highRiskOperation/pendingSharedBookCount`

## 输出
- `status`: `ready/review/block`
- `governanceMode`
- `reason/action/recommendation`

## 导出
- `exportJson(...)`
- `exportMarkdown(...)`
- `exportCsv(...)`

## 页面
- `EmailDeleteUserGovernanceScreen`
