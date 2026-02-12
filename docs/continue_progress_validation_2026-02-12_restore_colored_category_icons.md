# 恢复彩色分类图标 + 单色/彩色切换（2026-02-12）

## 背景

你之前替换过 `app/assets/category_icons/`（一套彩色 PNG 分类图标）。

但当时（以及 `origin/main`）存在两个问题：

1. `origin/main` 仍然是旧的黑白小图资源，并没有合入你那套彩色资源。
2. 即使资源文件本身是彩色的，`CategoryService.buildIcon()` 会对 **所有** PNG/SVG 走灰度+对比度+`BlendMode.modulate` 的 tint 处理，导致彩色资源最终显示成“单色图标”。

本次改动目标：

- 把你那套彩色 `assets/category_icons` 恢复回来。
- 让系统分类图标既能“彩色显示”，也能选择“单色（跟随分类颜色）”。
- 避免把无关文件/超大 PNG 打进 app bundle，控制包体与内存风险。

## 改动内容

### 1) 资源：恢复彩色图标并做必要的资产清理/优化

- 恢复：从 `origin/feature/next` 取回 `assets/category_icons/`（你的彩色图标版本）。
- 清理：移除目录中不应作为 Flutter asset 的文件：
  - `assets/category_icons/归档.zip`
  - `assets/category_icons/brand_icons_report.txt`（实际是 PNG，但命名是报告文件，且未被引用）
- 优化：将 62 张尺寸为 1024/2048 的大图统一缩放到 128x128 并压缩，避免包体暴涨。

资源现状（优化后）：

- `assets/category_icons/` 总大小约 `23MB`
- 所有 PNG 尺寸最大为 `128x128`

### 2) 代码：分类图标显示风格（彩色/单色）可切换

新增：

- `lib/core/service/category_icon_style.dart`
  - `CategoryIconStyle`：`colored` / `tinted`
  - `CategoryIconStyleStore`：使用 `SharedPreferences` 持久化
  - `CategoryIconStyleConfig`：内存配置（`ValueNotifier`）

接入：

- `lib/main.dart`
  - App 启动时加载 `CategoryIconStyleStore.load()`，写入 `CategoryIconStyleConfig.current`
  - `JiveApp` 使用 `ValueListenableBuilder` 监听样式变化以触发 UI 刷新
  - 头像菜单（底部弹层）新增“分类图标风格”入口，可选择：
    - `彩色`
    - `单色 (跟随分类颜色)`

渲染逻辑：

- `lib/core/service/category_service.dart`
  - 对 `assets/category_icons/` 下的 PNG/SVG：
    - `colored`：直接返回原图（保留 PNG 原始颜色）
    - `tinted`：沿用之前的灰度+对比度+modulate tint（单色图标）

### 3) UI：记一笔子分类选中态兼容彩色图标

- `lib/feature/transactions/add_transaction_screen.dart`
  - 当风格为 `colored` 时，子分类圆形图标背景不再使用“实心分类色 + 白色图标”，改为更适合彩色图标的样式（浅色背景）。
  - 当风格为 `tinted` 时，保持原来的 UI 行为不变。

### 4) 修复一致性：交易详情顶部图标走统一入口

- `lib/feature/transactions/widgets/transaction_hero_section.dart`
  - 从直接 `Image.asset('assets/category_icons/...')` 改为 `CategoryService.buildIcon(...)`，确保彩色/单色切换在该处同样生效。

## 验证

自动化：

- `flutter analyze`：通过
- `flutter test`：通过

手动建议：

1. 打开 App，点击首页右上角头像打开菜单
2. 进入“分类图标风格”，切换 `彩色` / `单色`
3. 进入“分类管理”与“记一笔”页面，确认：
   - 彩色模式：系统分类 PNG 保留自身颜色
   - 单色模式：系统分类 PNG 为单色，并跟随分类颜色/状态色

