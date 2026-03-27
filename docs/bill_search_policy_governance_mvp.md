# 账单搜索策略治理（MVP）

## 背景
- 对标 yimu `BillSearchActivity`，补齐关键词质量、排序策略、历史上下文、建议能力与查询延迟门禁。

## 输入
- `query/historyEnabled/historyCount`
- `filterEnabled/selectedFilterCount/sortMode`
- `estimatedResultCount/searchWindowDays`
- `tagSuggestionEnabled/actionSuggestionEnabled`

## 输出
- `status`: `ready/review/block`
- `governanceMode`
- `reason/action/recommendation`

## 导出
- `exportJson(...)`
- `exportMarkdown(...)`
- `exportCsv(...)`

## 页面
- `BillSearchPolicyGovernanceScreen`
