import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/bill_search_policy_governance_service.dart';

void main() {
  const service = BillSearchPolicyGovernanceService();

  test('returns block for invalid query', () {
    final result = service.evaluate(
      query: 'a',
      historyEnabled: true,
      historyCount: 10,
      filterEnabled: true,
      selectedFilterCount: 1,
      sortMode: 'time',
      estimatedResultCount: 100,
      tagSuggestionEnabled: true,
      actionSuggestionEnabled: true,
      searchWindowDays: 30,
    );

    expect(result.status, 'block');
    expect(result.governanceMode, 'empty_query_block');
  });

  test('returns review for overloaded result set', () {
    final result = service.evaluate(
      query: '午餐',
      historyEnabled: true,
      historyCount: 10,
      filterEnabled: true,
      selectedFilterCount: 1,
      sortMode: 'time',
      estimatedResultCount: 8000,
      tagSuggestionEnabled: true,
      actionSuggestionEnabled: true,
      searchWindowDays: 30,
    );

    expect(result.status, 'review');
    expect(result.governanceMode, 'result_overload_review');
  });

  test('returns ready for stable search strategy', () {
    final result = service.evaluate(
      query: '午餐 #通勤',
      historyEnabled: true,
      historyCount: 12,
      filterEnabled: true,
      selectedFilterCount: 2,
      sortMode: 'relevance',
      estimatedResultCount: 200,
      tagSuggestionEnabled: true,
      actionSuggestionEnabled: true,
      searchWindowDays: 90,
    );

    expect(result.status, 'ready');
    expect(result.governanceMode, 'bill_search_policy_ready');
  });

  test('exports json/markdown/csv contain key fields', () {
    final result = service.evaluate(
      query: '咖啡',
      historyEnabled: true,
      historyCount: 8,
      filterEnabled: true,
      selectedFilterCount: 2,
      sortMode: 'amount',
      estimatedResultCount: 80,
      tagSuggestionEnabled: true,
      actionSuggestionEnabled: true,
      searchWindowDays: 30,
    );
    final jsonText = service.exportJson(result);
    final markdown = service.exportMarkdown(result);
    final csv = service.exportCsv(result);
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;

    expect(decoded['status'], 'ready');
    expect(markdown, contains('# 账单搜索策略治理报告'));
    expect(csv, contains('query,history_enabled,history_count,filter_enabled'));
  });
}
