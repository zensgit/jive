# Analyzer 清理推进与验证报告（2026-02-12）

## 1. 目标
- 继续降低全仓库 analyzer 噪音，优先清理会导致 `flutter analyze` 失败的 warning/error。
- 保持行为不变（只做静态检查/兼容性/空安全类低风险修改）。
- 保持测试绿灯。

## 2. 基线与结果
### 2.1 基线（origin/main）
- 命令：`flutter analyze --no-fatal-infos`
- 结果：`239 issues found`（其中 `65` 条为 `warning`）
- 典型问题：`unused_import`、`unused_element`、`unreachable_switch_default`、`unnecessary_non_null_assertion`、`unnecessary_null_comparison` 等。

### 2.2 本轮结果（本分支）
- 命令：`flutter analyze --no-fatal-infos --no-fatal-warnings`
- 结果：`171 issues found`（`warning/error` 已清零，仅剩 `info`）
- 剩余主要类型（按数量）：
  - `deprecated_member_use`
  - `use_build_context_synchronously`
  - 少量 `curly_braces_in_flow_control_structures`、`unnecessary_to_list_in_spreads` 等

## 3. 本轮改动概览
### 3.1 全局 warning 清理
- 移除未使用 import（多个 screen/service）。
- 移除未引用的私有方法/字段（避免死代码堆积）。
- 修复 switch default 覆盖导致的 `unreachable_switch_default`。
- 修复冗余 `!` / 恒真判空等。

### 3.2 关键修复点（避免新引入空安全问题）
- `AccountsScreen` 图标选择逻辑：将可空变量在 async/closure 前复制到 `final` 局部变量，避免 analyzer 的 `unchecked_use_of_nullable_value`。

## 4. 涉及文件（摘要）
- `lib/main.dart`
- `lib/core/service/*`
- `lib/feature/accounts/*`
- `lib/feature/category/*`
- `lib/feature/currency/*`
- `lib/feature/project/*`
- `lib/feature/settings/*`
- `lib/feature/stats/*`
- `lib/feature/template/*`

## 5. 验证
- `flutter test`：通过（`All tests passed!`）

## 6. 后续建议
1. 继续按“类型分批”清理剩余 `info`：
   - 批量迁移 `withOpacity(...) -> withValues(alpha: ...)`
   - 处理 `use_build_context_synchronously`（补齐 `context.mounted`/`mounted` 守卫）
   - 清理 `curly_braces_in_flow_control_structures`、`unnecessary_to_list_in_spreads`
2. 目标收口：让 `flutter analyze`（默认参数）返回 `No issues found!`。
