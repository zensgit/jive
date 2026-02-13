# 分类图标风格：混合模式 + 彩色降噪 + 设备验证（2026-02-12）

## 目标/结论

本轮在“分类图标风格”里新增第三种模式 **混合**，并完善彩色模式的“选中/未选中”视觉降噪，同时补齐一轮真机验证脚本。

最终效果（对 `assets/category_icons/*` 生效）：

- `彩色`：全部分类图标按 PNG 原始颜色显示
- `单色 (跟随分类颜色)`：全部分类图标转为单色，并随分类色变化
- `混合 (系统单色/自定义彩色)`：
  - **系统分类**（`JiveCategory.isSystem == true`）显示为单色并跟随分类颜色
  - **自定义分类**（`isSystem == false`）保留 PNG 原始彩色

并在彩色/混合(自定义彩色)场景下，对“未选中”的彩色图标做 **弱化(muted)**，降低视觉噪声。

## 主要改动

### 1) 新增混合模式枚举与持久化

- `lib/core/service/category_icon_style.dart`
  - `CategoryIconStyle` 增加 `hybrid`
  - label 增加 `混合 (系统单色/自定义彩色)`
  - `CategoryIconStyleStore` 支持读写 `hybrid`
  - 新增辅助逻辑：`CategoryIconStyleBehavior.shouldTintForCategory(isSystemCategory: ...)`

### 2) 分类图标渲染：按“系统/自定义”分流 + 彩色未选中降噪

- `lib/core/service/category_service.dart`
  - `CategoryService.buildIcon(...)` 新增参数：`bool? isSystemCategory`
  - 当图标来自 `assets/category_icons/` 时：
    - `tinted`：始终走原有“灰度+对比度+modulate tint”
    - `colored`：始终保留原图
    - `hybrid`：根据 `isSystemCategory` 决定是否 tint
  - 新增彩色“降噪”：
    - 当 **彩色渲染** 且调用方传入的 `color` 是中性灰（且非接近白色）时，认为是“未选中/弱化态”，对原图应用：
      - 轻度去饱和（`ColorFilter.matrix`）
      - 降低不透明度（`Opacity`）

说明：这里沿用已有的 `color` 入参作为“状态信号”，避免为所有调用点额外引入 `muted/isSelected` 参数，且不影响单色模式（单色模式仍按 `color` 进行 tint）。

### 3) UI 调整：混合模式下按分类来源决定“彩色/单色”

关键点：之前的 UI 逻辑多以 `CategoryIconStyleConfig.current == colored` 作为全局布尔开关，但混合模式需要 **同一屏内不同分类呈现不同风格**。

- `lib/feature/transactions/add_transaction_screen.dart`
  - 子分类网格：改为按每个 `cat.isSystem` 决定当前图标是否会被 tint
  - 彩色态时：未选中传入 `inactiveColor` 以触发“彩色弱化”，选中传 `null` 保持原彩
  - 并补齐 `isSystemCategory: cat.isSystem`

- 其它分类相关页面（统一补齐 `isSystemCategory`）：
  - `lib/feature/transactions/widgets/transaction_hero_section.dart`
  - `lib/feature/category/category_manager_screen.dart`
  - `lib/feature/category/category_edit_dialog.dart`
  - `lib/feature/category/category_search_delegate.dart`
  - `lib/feature/category/category_transactions_screen.dart`

### 4) 图标选择页：混合模式下预览与编辑对象一致

- `lib/feature/category/category_icon_source_picker.dart`
  - `pickCategoryIcon(...)` 增加 `forSystemCategory` 参数
- `lib/feature/category/category_icon_picker_screen.dart`
  - `CategoryIconPickerScreen` 增加 `forSystemCategory`
  - 系统图标网格预览时传入 `isSystemCategory: widget.forSystemCategory`
- `lib/feature/category/category_edit_dialog.dart`
  - 编辑分类时调用 `pickCategoryIcon(... forSystemCategory: widget.category.isSystem)`

### 5) Debug 菜单：增加混合模式选项

- `lib/main.dart`
  - “分类图标风格”弹窗新增第三项：`混合 (系统单色/自定义彩色)`

## 验证

### 1) 自动化检查

- `flutter analyze`：通过
- `flutter test`：通过

### 2) 真机验证脚本（ADB）

- `scripts/verify_dev_flow.sh`
  - 启动后若出现“自动记账权限未开启”弹窗，脚本会自动点“稍后/关闭”
  - 校验“分类图标风格”弹窗包含 `彩色/单色/混合` 并可切到 `混合`
  - 继续验证：
    - 打开“周期记账”列表与新建规则页
    - 打开“预算管理”，等待后不应一直显示 loading
  - 对 bottom sheet 里的条目搜索，新增了 `tap_text_with_scroll_small`，避免大幅滑动导致跳过临界条目

运行方式（示例）：

```bash
cd app

# 构建并安装 dev debug 到设备（确保包含本地最新代码）
flutter build apk --flavor dev --debug
adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk

# 跑自动化真机验证
bash scripts/verify_dev_flow.sh com.jivemoney.app.dev
```

本次脚本验证通过，产物目录：

- `/tmp/jive-verify-20260212-231916`

## 备注/边界

- `hybrid` 判断依据是 `JiveCategory.isSystem`：
  - 系统分类：单色
  - 自定义分类：彩色
  - 即使自定义分类使用了 `assets/category_icons/*` 的图标文件，在混合模式下也会保持彩色（符合“自定义彩色”的预期）。

