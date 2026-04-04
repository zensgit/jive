import 'package:isar/isar.dart';

part 'user_auto_rule_model.g.dart';

/// User-defined auto-categorization rule, stored in Isar.
/// These supplement the built-in rules from auto_rules.json.
@collection
class JiveUserAutoRule {
  Id id = Isar.autoIncrement;

  /// Rule display name
  String name = '';

  /// Comma-separated keywords to match against transaction text
  String keywords = '';

  /// Optional source filter (e.g., "微信支付", "支付宝")
  String? source;

  /// Parent category key to assign
  String? parentCategoryKey;

  /// Sub-category key to assign
  String? subCategoryKey;

  /// Transaction type: expense, income, transfer
  String type = 'expense';

  /// Comma-separated tag keys to auto-assign
  String? tagKeys;

  /// Priority: lower = higher priority (checked before built-in rules)
  int priority = 0;

  bool isEnabled = true;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
