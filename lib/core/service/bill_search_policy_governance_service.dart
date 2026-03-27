import 'dart:convert';

class BillSearchPolicyGovernanceInput {
  const BillSearchPolicyGovernanceInput({
    required this.query,
    required this.historyEnabled,
    required this.historyCount,
    required this.filterEnabled,
    required this.selectedFilterCount,
    required this.sortMode,
    required this.estimatedResultCount,
    required this.tagSuggestionEnabled,
    required this.actionSuggestionEnabled,
    required this.searchWindowDays,
  });

  final String query;
  final bool historyEnabled;
  final int historyCount;
  final bool filterEnabled;
  final int selectedFilterCount;
  final String sortMode;
  final int estimatedResultCount;
  final bool tagSuggestionEnabled;
  final bool actionSuggestionEnabled;
  final int searchWindowDays;

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'historyEnabled': historyEnabled,
      'historyCount': historyCount,
      'filterEnabled': filterEnabled,
      'selectedFilterCount': selectedFilterCount,
      'sortMode': sortMode,
      'estimatedResultCount': estimatedResultCount,
      'tagSuggestionEnabled': tagSuggestionEnabled,
      'actionSuggestionEnabled': actionSuggestionEnabled,
      'searchWindowDays': searchWindowDays,
    };
  }
}

class BillSearchPolicyGovernanceResult {
  const BillSearchPolicyGovernanceResult({
    required this.input,
    required this.status,
    required this.governanceMode,
    required this.reason,
    required this.action,
    required this.recommendation,
  });

  final BillSearchPolicyGovernanceInput input;
  final String status;
  final String governanceMode;
  final String reason;
  final String action;
  final String recommendation;

  Map<String, dynamic> toJson() {
    return {
      'input': input.toJson(),
      'status': status,
      'governanceMode': governanceMode,
      'reason': reason,
      'action': action,
      'recommendation': recommendation,
    };
  }
}

class BillSearchPolicyGovernanceService {
  const BillSearchPolicyGovernanceService();

  static const Set<String> _supportedSortModes = <String>{
    'time',
    'amount',
    'relevance',
  };

  BillSearchPolicyGovernanceResult evaluate({
    required String query,
    required bool historyEnabled,
    required int historyCount,
    required bool filterEnabled,
    required int selectedFilterCount,
    required String sortMode,
    required int estimatedResultCount,
    required bool tagSuggestionEnabled,
    required bool actionSuggestionEnabled,
    required int searchWindowDays,
  }) {
    final normalizedQuery = query.trim();
    final normalizedSortMode = sortMode.trim().toLowerCase();
    final safeHistoryCount = historyCount < 0 ? 0 : historyCount;
    final safeSelectedFilterCount = selectedFilterCount < 0
        ? 0
        : selectedFilterCount;
    final safeEstimatedResultCount = estimatedResultCount < 0
        ? 0
        : estimatedResultCount;
    final safeSearchWindowDays = searchWindowDays < 0 ? 0 : searchWindowDays;

    final input = BillSearchPolicyGovernanceInput(
      query: normalizedQuery,
      historyEnabled: historyEnabled,
      historyCount: safeHistoryCount,
      filterEnabled: filterEnabled,
      selectedFilterCount: safeSelectedFilterCount,
      sortMode: normalizedSortMode,
      estimatedResultCount: safeEstimatedResultCount,
      tagSuggestionEnabled: tagSuggestionEnabled,
      actionSuggestionEnabled: actionSuggestionEnabled,
      searchWindowDays: safeSearchWindowDays,
    );

    if (normalizedQuery.isEmpty || normalizedQuery.length < 2) {
      return BillSearchPolicyGovernanceResult(
        input: input,
        status: 'block',
        governanceMode: 'empty_query_block',
        reason: '搜索关键词过短，无法建立有效搜索动作',
        action: '补全至少 2 个字符的关键词',
        recommendation: '建议默认提示最近搜索与推荐动作。',
      );
    }

    if (normalizedQuery.length > 80) {
      return BillSearchPolicyGovernanceResult(
        input: input,
        status: 'block',
        governanceMode: 'query_too_long_block',
        reason: '搜索关键词过长，存在性能与误匹配风险',
        action: '缩短关键词并分段执行搜索',
        recommendation: '建议关键词长度不超过 80 字符。',
      );
    }

    if (!_supportedSortModes.contains(normalizedSortMode)) {
      return BillSearchPolicyGovernanceResult(
        input: input,
        status: 'block',
        governanceMode: 'invalid_sort_mode_block',
        reason: '排序模式不受支持',
        action: '切换为 time/amount/relevance 之一',
        recommendation: '建议默认使用 time 排序。',
      );
    }

    if (safeEstimatedResultCount > 5000 || safeSearchWindowDays > 3650) {
      return BillSearchPolicyGovernanceResult(
        input: input,
        status: 'review',
        governanceMode: 'result_overload_review',
        reason: '搜索结果规模或时间窗口过大',
        action: '缩小时间范围并增加过滤条件',
        recommendation: '建议在结果过载时自动引导筛选。',
      );
    }

    if (!historyEnabled || safeHistoryCount == 0) {
      return BillSearchPolicyGovernanceResult(
        input: input,
        status: 'review',
        governanceMode: 'history_bootstrap_review',
        reason: '搜索历史功能未启用或暂无历史记录',
        action: '启用历史并沉淀常用搜索语句',
        recommendation: '建议保留至少 5 条历史记录。',
      );
    }

    if (!filterEnabled || safeSelectedFilterCount == 0) {
      return BillSearchPolicyGovernanceResult(
        input: input,
        status: 'review',
        governanceMode: 'filter_coverage_review',
        reason: '搜索筛选覆盖不足，结果噪声较高',
        action: '至少配置一个筛选条件',
        recommendation: '建议默认挂载账本或时间过滤器。',
      );
    }

    if (!tagSuggestionEnabled || !actionSuggestionEnabled) {
      return BillSearchPolicyGovernanceResult(
        input: input,
        status: 'review',
        governanceMode: 'suggestion_readiness_review',
        reason: '标签建议或动作建议能力未就绪',
        action: '启用搜索建议引擎后重试',
        recommendation: '建议联动标签高亮与快捷搜索动作。',
      );
    }

    return BillSearchPolicyGovernanceResult(
      input: input,
      status: 'ready',
      governanceMode: 'bill_search_policy_ready',
      reason: '账单搜索策略治理检查通过',
      action: '允许执行搜索并记录动作审计',
      recommendation: '建议持续优化高频词与过滤模板。',
    );
  }

  String exportJson(
    BillSearchPolicyGovernanceResult result, {
    bool pretty = true,
  }) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(result.toJson());
    }
    return jsonEncode(result.toJson());
  }

  String exportMarkdown(BillSearchPolicyGovernanceResult result) {
    return [
      '# 账单搜索策略治理报告',
      '',
      '- status: ${result.status}',
      '- governanceMode: ${result.governanceMode}',
      '- reason: ${result.reason}',
      '- action: ${result.action}',
      '- recommendation: ${result.recommendation}',
      '',
      '| field | value |',
      '| --- | --- |',
      '| query | ${result.input.query} |',
      '| historyEnabled | ${result.input.historyEnabled} |',
      '| historyCount | ${result.input.historyCount} |',
      '| filterEnabled | ${result.input.filterEnabled} |',
      '| selectedFilterCount | ${result.input.selectedFilterCount} |',
      '| sortMode | ${result.input.sortMode} |',
      '| estimatedResultCount | ${result.input.estimatedResultCount} |',
      '| tagSuggestionEnabled | ${result.input.tagSuggestionEnabled} |',
      '| actionSuggestionEnabled | ${result.input.actionSuggestionEnabled} |',
      '| searchWindowDays | ${result.input.searchWindowDays} |',
    ].join('\n');
  }

  String exportCsv(BillSearchPolicyGovernanceResult result) {
    final values = <String>[
      _csvEscape(result.input.query),
      result.input.historyEnabled ? '1' : '0',
      '${result.input.historyCount}',
      result.input.filterEnabled ? '1' : '0',
      '${result.input.selectedFilterCount}',
      result.input.sortMode,
      '${result.input.estimatedResultCount}',
      result.input.tagSuggestionEnabled ? '1' : '0',
      result.input.actionSuggestionEnabled ? '1' : '0',
      '${result.input.searchWindowDays}',
      result.status,
      result.governanceMode,
      _csvEscape(result.reason),
      _csvEscape(result.action),
      _csvEscape(result.recommendation),
    ];
    return [
      'query,history_enabled,history_count,filter_enabled,selected_filter_count,sort_mode,estimated_result_count,tag_suggestion_enabled,action_suggestion_enabled,search_window_days,status,governance_mode,reason,action,recommendation',
      values.join(','),
    ].join('\n');
  }
}

String _csvEscape(String value) {
  if (!value.contains(',') && !value.contains('"') && !value.contains('\n')) {
    return value;
  }
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
