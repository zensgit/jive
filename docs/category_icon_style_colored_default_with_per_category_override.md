# 分类图标：默认彩色 + 全局风格切换 + 按分类强制单色（最终说明，2026-02-13）

## 背景

你在 `assets/category_icons/` 放入了一套 **彩色 PNG 分类图标**。本轮的目标是：

- **默认按 PNG 原色显示（彩色）**
- 仍然支持“单色(跟随分类颜色)”的渲染方式
- 额外支持：**某个分类单独强制单色**（即使全局为彩色）
- 同时满足“系统分类图标可单色、自定义分类图标可彩色”的混合诉求

说明：本轮没有去替换/回滚你的 `assets/category_icons/` 资源文件，只是调整了“渲染逻辑”和“配置入口”。

## 需求与最终行为

对 `assets/category_icons/*` 生效：

- 全局 `彩色`：全部分类图标保持 PNG 原始彩色
- 全局 `单色 (跟随分类颜色)`：全部分类图标转单色，并跟随分类颜色
- 全局 `混合 (系统单色/自定义彩色)`：
  - 系统分类（`JiveCategory.isSystem == true`）：单色 + 跟随分类色
  - 自定义分类（`isSystem == false`）：保持 PNG 原始彩色

并新增分类级覆盖（优先级更高）：

- **图标强制单色**（`iconForceTinted == true`）：该分类永远单色渲染（即使全局是 `彩色/混合`）。

优先级（高 -> 低）：

1. 分类级：`JiveCategory.iconForceTinted` / `forceTinted`
2. 全局级：`CategoryIconStyleConfig.current`

## 开发计划（已执行）

1. 增加全局枚举与持久化（彩色/单色/混合），并在 App 启动时加载生效
2. 统一分类图标渲染入口：仅对 `assets/category_icons/*` 做“彩色 or 单色”分流
3. 混合模式：按 `isSystemCategory` 决定是否 tint（系统单色/自定义彩色）
4. 增加分类级别开关：编辑分类时可强制单色，且覆盖全局风格
5. 补齐各页面传参，保证图标表现一致（列表、搜索、记一笔、详情等）
6. 自动化验证：`flutter analyze`、`flutter test`
7. 真机脚本验证：`scripts/verify_dev_flow.sh`
8. 输出文档（本文件 + 两份过程记录）

## 实现要点（关键改动点）

### 1) 数据库字段（Isar）

- `lib/core/database/category_model.dart`
  - `bool iconForceTinted = false;`

已执行代码生成（更新 schema）：

- `lib/core/database/category_model.g.dart`

### 2) 图标渲染（统一入口）

- `lib/core/service/category_service.dart`
  - `CategoryService.buildIcon(...)` 新增参数：
    - `bool? isSystemCategory`
    - `bool forceTinted = false`
  - 当图标来自 `assets/category_icons/*`：
    - `forceTinted == true`：永远单色
    - 否则：按全局风格（彩色/单色/混合）决定是否单色

### 3) 全局风格枚举 + 持久化

- `lib/core/service/category_icon_style.dart`
  - `CategoryIconStyle`: `colored | tinted | hybrid`
  - `CategoryIconStyleStore`：SharedPreferences 读写
  - `CategoryIconStyleConfig`：内存 `ValueNotifier`，触发全 App 刷新

- `lib/main.dart`
  - 启动加载 `CategoryIconStyleStore.load()` 并写入 `CategoryIconStyleConfig.current`
  - 用 `ValueListenableBuilder` 包住 `MaterialApp`，保证切换后即时刷新 UI

### 4) UI 入口

- 全局：`lib/main.dart` 的 Debug Sheet 增加“分类图标风格”选项
- 分类级：`lib/feature/category/category_edit_dialog.dart`
  - 新增开关：`图标强制单色（即使在彩色模式下也显示为单色）`
  - 保存时持久化：`CategoryService.updateCategory(..., iconForceTinted: ...)`
  - 进入图标选择器时透传 `forceTinted`，预览与实际一致

### 5) 关键页面透传（保证一致性）

这些页面的分类 icon 渲染点补齐：

- `isSystemCategory: cat.isSystem`
- `forceTinted: cat.iconForceTinted`

涉及文件（节选）：

- `lib/feature/transactions/add_transaction_screen.dart`
- `lib/feature/transactions/widgets/transaction_hero_section.dart`
- `lib/feature/category/category_manager_screen.dart`
- `lib/feature/category/category_search_delegate.dart`
- `lib/feature/category/category_transactions_screen.dart`
- `lib/feature/category/category_edit_dialog.dart`

## 验证结果

### 1) 自动化

- `flutter analyze`：通过
- `flutter test`：通过

### 2) 真机脚本（ADB）

运行：

```bash
cd app
bash scripts/verify_dev_flow.sh com.jivemoney.app.dev
```

最新一次验证通过（PASS），产物目录：

- `/tmp/jive-verify-20260213-004700`

### 3) 备份/恢复兼容

- `JiveDataBackupService` 的分类导入/导出已包含 `iconForceTinted` 字段（未包含时默认 `false`），用于保证“按分类强制单色”在备份恢复后不丢失。

## 如何验收（建议手动走一遍）

1. 打开 Debug Sheet -> `分类图标风格` 选 `彩色`
2. 进入 `分类管理`：
   - 自定义分类图标应保持彩色（PNG 原色）
3. 编辑任意分类：
   - 打开 `图标强制单色`
   - 回到“记一笔/分类管理/交易详情”等页面确认该分类图标已变为单色并跟随分类色
4. 将全局切到 `混合`：
   - 系统分类应为单色
   - 自定义分类应保持彩色
5. 将全局切到 `单色`：
   - 所有分类应为单色

## 过程记录（可选参考）

- `docs/continue_progress_validation_2026-02-12_category_icon_style_hybrid.md`
- `docs/continue_progress_validation_2026-02-12_category_icon_per_category_tinted.md`
