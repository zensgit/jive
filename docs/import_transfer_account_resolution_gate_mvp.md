# Import Transfer Account Resolution Gate MVP

## Scope
- 在 `ImportCenter` 的 transfer confirm gate 中，把“真实账户解析”纳入判定，而不是只看字段是否为空。
- 保持现有 `ImportCenter -> ImportService -> AutoDraftService` 链路不变，不新开 transfer-only 页面。

## Rules
1. 阻断
   - 缺少转入账户
   - 转入账户无法命中当前有效账户
   - 转出账户与转入账户解析到同一账户
   - 金额无效
2. 待确认
   - 未显式提供转出账户
   - 转出账户未命中当前有效账户，但仍可回退到自动识别
   - 手续费大于等于转账金额

## Matching
- 账户解析规则与 `AutoDraftService` 保持一致：
  - 先精确匹配
  - 再做包含关系匹配
- 这样 `微信零钱 -> 微信` 这种输入不会被误判成未知账户。

## Result
- transfer import 会在进入 `AutoDraftService` 前先拦下“未知转入账户”。
- gate 与真实落草稿时的账户解析逻辑对齐，减少“预览能过、草稿再失败”的分叉。
