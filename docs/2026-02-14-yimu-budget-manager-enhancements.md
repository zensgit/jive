# yimu 参考：预算管理增强（分类预算 + 日预算 + 下拉预算排除）

## 目标
在 Jive 已有预算能力基础上，对齐 yimu `BudgetManagerActivity` 的核心体验：
- 创建预算时可选择分类（分类预算）
- 展示日均预算/剩余日预算、超支提示、预警阈值等预算信息
- 在预算页通过“下拉”快捷进入预算排除（BudgetHideActivity 风格）

## 1) 分类预算（Category Budget）
### 创建预算支持选择分类
在 `创建预算` 底部弹窗新增字段 `预算分类`：
- 默认：`全部分类`（总预算）
- 选择后：创建分类预算（支持一级或二级分类）
- 选择分类后若预算名称为空，自动填入 `${分类名}预算`

分类选择页沿用 `CategoryPickerScreen`，并遵循“优先用户分类”的策略：
- 若用户存在支出类的自定义分类，则只显示用户分类（避免系统分类过多）
- 否则显示系统分类

### 统计口径
`BudgetService.calculateBudgetUsage` 中对分类预算支持：
- `tx.categoryKey == budget.categoryKey`（一级分类）
- `tx.subCategoryKey == budget.categoryKey`（二级分类）

备注：
- 账单维度 `excludeFromBudget=true` 仍会被排除（不计入预算）
- “分类维度预算排除（JiveCategory.excludeFromBudget）”仅对 **总预算** 生效，分类预算不应用该过滤（避免用户创建某分类预算后被全局排除导致统计为 0 的意外）

## 2) 预算体验增强
### 剩余天数修正（按天计，包含当天）
之前 `daysRemaining` 用 `endDate.difference(now).inDays`，在“同一天”会显示 0 天。
现在改为按日期（去掉时分秒）计算，并 **包含当天**：
- 同一天：剩余 1 天
- 到期前 N 天：剩余 N+1 天

### 日均预算与剩余日预算
- `日均预算 = 预算金额 / 总天数（含首尾）`
- `剩余日预算 = 剩余金额 / 剩余天数（含当天）`

展示位置：
- 预算卡片：增加“剩余金额”与“日均可用”
- 预算详情：展示 `日均预算` / `剩余日预算`，并在超支/预警时给出提示条

### 查看账单入口
在预算详情页增加 `查看账单` 按钮：
- 总预算：打开全部账单列表
- 分类预算：自动按一级/二级分类过滤打开账单列表

## 3) 下拉进入预算排除
在 `预算管理` 页：
- 保留顶部入口 `预算排除`
- 增加 yimu 风格交互：**下拉**触发打开 `预算排除` 页面
- 同时增加提示卡片：`下拉设置不计入预算的分类`

## 代码位置
- 预算统计：`app/lib/core/service/budget_service.dart`
- 预算管理 UI：`app/lib/feature/budget/budget_list_screen.dart`
- 预算排除页：`app/lib/feature/budget/budget_exclude_screen.dart`

## 验证
- `flutter analyze`
- `flutter test`

