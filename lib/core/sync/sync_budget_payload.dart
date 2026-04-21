List<String> syncBudgetCategoryKeys(String? categoryKey) {
  final normalized = categoryKey?.trim();
  if (normalized == null || normalized.isEmpty) {
    return const <String>[];
  }
  return <String>[normalized];
}
