# yimu 参考：搜索筛选「不计入预算 / 仅计入预算」

## 背景
yimu 的 `SearchFilterManager` 提供筛选项：
- `不计入预算`
- `仅计入预算`

Jive 已支持：
- 账单维度：`JiveTransaction.excludeFromBudget`
- 分类维度：`JiveCategory.excludeFromBudget`

本次补齐在「查找账单（按条件）」里对这两类“不计入预算”进行筛选，便于排查预算口径。

## 实现
### 1) TransactionFilterSheet 增加可选预算筛选项
`TransactionFilterSheet` 新增可选参数（不影响现有调用方）：
- `initialBudgetFilter`（默认 `BudgetInclusionFilter.all`）
- `onBudgetFilterChanged`（传入后显示预算筛选下拉）

筛选项：
- `全部`
- `不计入预算`
- `仅计入预算`

### 2) CategoryTransactionsScreen（含首页 View All）接入预算筛选
在 `CategoryTransactionsScreen` 的筛选面板中开启预算筛选，并在 `_applySearch` 中生效：
- 当筛选为「不计入预算 / 仅计入预算」时，仅对 **支出交易** 生效
- “预算是否排除”的判定规则：
  - `tx.excludeFromBudget == true` 或
  - `tx.categoryKey / tx.subCategoryKey` 对应分类的 `excludeFromBudget == true`

## 相关代码位置
- 组件与枚举：`app/lib/core/widgets/transaction_filter_sheet.dart`
- 接入与过滤：`app/lib/feature/category/category_transactions_screen.dart`

