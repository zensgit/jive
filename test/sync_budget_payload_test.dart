import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/sync/sync_budget_payload.dart';

void main() {
  group('syncBudgetCategoryKeys', () {
    test('returns empty array for null or blank category key', () {
      expect(syncBudgetCategoryKeys(null), isEmpty);
      expect(syncBudgetCategoryKeys(''), isEmpty);
      expect(syncBudgetCategoryKeys('   '), isEmpty);
    });

    test('returns a single normalized category key array', () {
      expect(syncBudgetCategoryKeys('cat_food'), ['cat_food']);
      expect(syncBudgetCategoryKeys('  cat_food  '), ['cat_food']);
    });
  });
}
