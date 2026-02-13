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

- 全局 `彩色（默认）`：全部分类图标保持 PNG 原始彩色
- 全局 `单色（全部跟随分类颜色）`：全部分类图标转单色，并跟随分类颜色
- 全局 `混合（系统单色/自定义彩色）`：
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

## 本轮补充（2026-02-13，交互增强）

在不改变“默认彩色、可按分类强制单色”逻辑的前提下，补了两项可见性增强：

1. 创建/编辑分类页新增“图标强制单色”效果预览  
   - 位置：`图标强制单色` 开关下方
   - 内容：并排展示 `跟随全局` 与 `强制单色` 两种图标效果
   - 会显示当前全局风格文案（彩色/单色/混合），降低理解成本

2. 分类管理列表新增“单色”状态标记  
   - 一级分类行：名称右侧展示 `单色` 徽标（当 `iconForceTinted == true`）
   - 二级分类 chip：右上角展示紧凑 `单色` 徽标
   - 目的：不用点进编辑页，也能快速识别哪些分类启用了强制单色

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

- 全局：`lib/feature/settings/settings_screen.dart`
  - 入口：主页右上角菜单 → `设置` → `分类图标风格`
- 分类级：`lib/feature/category/category_edit_dialog.dart`
  - 新增开关：`图标强制单色（即使在彩色模式下也显示为单色）`
  - 保存时持久化：`CategoryService.updateCategory(..., iconForceTinted: ...)`
  - 进入图标选择器时透传 `forceTinted`，预览与实际一致
- 创建分类：`lib/feature/category/category_create_screen.dart`
  - 新增开关：`图标强制单色`
  - 创建时直接写入 `iconForceTinted`，避免创建后再编辑
  - 开关下新增“效果预览”，直观看到开/关差异

- 编辑分类：`lib/feature/category/category_edit_dialog.dart`
  - 开关下新增“效果预览”，与创建页保持一致

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

并补充状态可视化：

- `lib/feature/category/category_manager_screen.dart`
  - 一级分类行：`单色` 徽标
  - 二级分类 chip：右上角紧凑 `单色` 徽标

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

脚本覆盖（节选）：

- 打开 `设置`，校验“分类图标风格”弹窗包含 `彩色/单色/混合` 并可切换
- 打开 `分类管理`，校验“创建一级分类/创建子类/编辑分类”均包含 `图标强制单色`
- 继续验证：周期记账、预算页加载不应一直转圈

最新一次验证通过（PASS），产物目录：

- `/tmp/jive-verify-20260213-015925`

本轮交互增强后的最新一次验证同样通过（PASS），产物目录：

- `/tmp/jive-verify-20260213-113652`

## 本轮新增（2026-02-13，交互/验证增强）

1. 设置页“分类图标风格”由 `AlertDialog` 改为 **从底部弹出的 BottomSheet**，更符合移动端习惯。
2. 为 `单色/已隐藏` 徽标补了 `Semantics(label=...)`，使 ADB/uiautomator dump 可稳定识别文本节点，避免脚本断言抖动。
3. `scripts/verify_dev_flow.sh` 对“强制单色”校验逻辑增强：
   - 更稳健地解析 switch `checked` 状态
   - 当无法直接在列表 dump 中找到徽标时，会回到编辑页做二次确认（兜底）

最新一次验证通过（PASS），产物目录：

- `/tmp/jive-verify-20260213-123606`

### 3) 备份/恢复兼容

- `JiveDataBackupService` 的分类导入/导出已包含 `iconForceTinted` 字段（未包含时默认 `false`），用于保证“按分类强制单色”在备份恢复后不丢失。

## 如何验收（建议手动走一遍）

1. 主页右上角菜单 → `设置` → `分类图标风格` 选 `彩色`
2. 进入 `分类管理`：
   - 自定义分类图标应保持彩色（PNG 原色）
3. 编辑任意分类：
   - 打开 `图标强制单色`
   - 回到“记一笔/分类管理/交易详情”等页面确认该分类图标已变为单色并跟随分类色
4. 创建任意分类（或子类）：
   - 勾选 `图标强制单色` 后创建
   - 确认新分类图标为单色并跟随分类色
5. 将全局切到 `混合`：
   - 系统分类应为单色
   - 自定义分类应保持彩色
6. 将全局切到 `单色`：
   - 所有分类应为单色

## 过程记录（可选参考）

- `docs/continue_progress_validation_2026-02-12_category_icon_style_hybrid.md`
- `docs/continue_progress_validation_2026-02-12_category_icon_per_category_tinted.md`
