# 分类图标：默认彩色 + 支持按分类强制单色（2026-02-12）

## 需求

- 全局默认 **彩色**（保留 `assets/category_icons/*` PNG 原始颜色）
- 允许对某个分类单独设置为 **单色（跟随分类颜色）**
  - 即使全局处于 `彩色` 或 `混合`，该分类也可以强制单色

## 实现

### 1) 数据字段（持久化）

- `lib/core/database/category_model.dart`
  - `JiveCategory.iconForceTinted`：`bool`，默认 `false`
    - `false`：跟随全局图标风格
    - `true`：该分类图标强制单色渲染（tinted）

备注：本字段直接存储在 `JiveCategory` 上，系统分类和自定义分类都可用。

### 2) 渲染逻辑（优先级）

- `lib/core/service/category_service.dart`
  - `CategoryService.buildIcon(...)` 增加参数 `forceTinted`
  - 当图标来自 `assets/category_icons/*` 时：
    - 若 `forceTinted == true`：**始终单色**
    - 否则：按全局 `CategoryIconStyleConfig.current`（彩色/单色/混合）决定是否单色

优先级（高到低）：

1. 分类级别：`forceTinted`
2. 全局级别：`CategoryIconStyleConfig.current`

### 3) UI：编辑分类开关

- `lib/feature/category/category_edit_dialog.dart`
  - 新增开关：`图标强制单色`
  - 文案：即使在彩色模式下也显示为单色（跟随分类颜色）
  - 保存时调用 `CategoryService.updateCategory(..., iconForceTinted: ...)`
  - 进入“选择图标”页时，将 `forceTinted` 透传给选择器用于预览

### 4) 关键页面传参补齐

为确保该分类在各处展示一致，分类图标渲染点都传入：

- `isSystemCategory: cat.isSystem`
- `forceTinted: cat.iconForceTinted`

覆盖页面（部分）：

- `lib/feature/transactions/add_transaction_screen.dart`
- `lib/feature/transactions/widgets/transaction_hero_section.dart`
- `lib/feature/category/category_manager_screen.dart`
- `lib/feature/category/category_search_delegate.dart`
- `lib/feature/category/category_transactions_screen.dart`

另外：记一笔的子分类选中态 UI 也改为按“每个分类是否会单色”计算，而不是依赖全局布尔值。

## 验证

### 自动化

- `flutter analyze`：通过
- `flutter test`：通过

### 真机脚本（ADB）

- `scripts/verify_dev_flow.sh`：通过
- 本次产物目录：
  - `/tmp/jive-verify-20260213-002347`

## 手动验证建议

1. 进入：分类管理 → 任意分类 → 编辑
2. 打开 `图标强制单色`
3. 返回“记一笔/分类管理/交易详情”等页面确认该分类图标为单色；关闭开关后恢复按全局风格显示。

