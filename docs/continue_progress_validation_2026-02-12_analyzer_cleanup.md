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

### 2.2 中间结果（清零 warning/error）
- 命令：`flutter analyze --no-fatal-infos --no-fatal-warnings`
- 结果：`171 issues found`（`warning/error` 已清零，仅剩 `info`）
- 剩余主要类型（按数量）：
  - `deprecated_member_use`
  - `use_build_context_synchronously`
  - 少量 `curly_braces_in_flow_control_structures`、`unnecessary_to_list_in_spreads` 等

### 2.3 最终结果（info 清零）
- 命令：`flutter analyze`
- 结果：`No issues found!`

## 3. 本轮改动概览
### 3.1 全局 warning 清理
- 移除未使用 import（多个 screen/service）。
- 移除未引用的私有方法/字段（避免死代码堆积）。
- 修复 switch default 覆盖导致的 `unreachable_switch_default`。
- 修复冗余 `!` / 恒真判空等。

### 3.2 关键修复点（避免新引入空安全问题）
- `AccountsScreen` 图标选择逻辑：将可空变量在 async/closure 前复制到 `final` 局部变量，避免 analyzer 的 `unchecked_use_of_nullable_value`。

### 3.3 info 清理（deprecated + async context + 小型重构）
- `use_build_context_synchronously`：补齐 `mounted`/`context.mounted` 守卫，避免在 `await` 之后直接使用 `context` 调用 `Navigator`/`ScaffoldMessenger` 等。
- `deprecated_member_use`：`WillPopScope` -> `PopScope`
- `deprecated_member_use`：`DragTarget.onWillAccept/onAccept` -> `onWillAcceptWithDetails/onAcceptWithDetails`
- `deprecated_member_use`：`Switch.activeColor` -> `activeThumbColor`
- `deprecated_member_use`：`MediaQuery.textScaleFactorOf` -> `MediaQuery.textScalerOf(context).scale(x) / x`
- `deprecated_member_use`：`Color.value` -> `Color.toARGB32()`
- `deprecated_member_use`：`Share.shareXFiles`/`Share` -> `SharePlus.instance.share(ShareParams(...))`
- `unnecessary_to_list_in_spreads` / `unnecessary_brace_in_string_interps`：移除冗余 `.toList()` 与插值花括号。

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
- `flutter analyze`：通过（`No issues found!`）
- `flutter test`：通过（`All tests passed!`）

## 6. 后续建议
1. 将 `flutter analyze` 与 `flutter test` 固化到 CI 或本地 pre-push 流程，防止 analyzer 噪音回归。
2. 后续如要升级 Flutter/Dart 版本，建议先跑 `flutter analyze` 对比新增 deprecation，再分批迁移。
