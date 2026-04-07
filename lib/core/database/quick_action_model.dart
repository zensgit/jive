import 'package:isar/isar.dart';

part 'quick_action_model.g.dart';

/// Persistent Isar model for a QuickAction (Stage 2: independent storage).
///
/// Replaces the on-the-fly conversion from [JiveTemplate] with a dedicated
/// collection that supports richer configuration (visibility flags, mode, etc.).
@collection
class JiveQuickAction {
  Id id = Isar.autoIncrement;

  /// Display name.
  @Index()
  late String name;

  /// Material icon name, e.g. `restaurant`.
  String? iconName;

  /// Hex color, e.g. `#FF5722`.
  String? colorHex;

  /// `expense`, `income`, or `transfer`.
  late String transactionType;

  /// Associated book id (optional).
  int? bookId;

  /// Source account id.
  int? accountId;

  /// Target account id (for transfers).
  int? toAccountId;

  /// Category key (stable identifier).
  String? categoryKey;

  /// Sub-category key.
  String? subCategoryKey;

  /// Tag keys attached by default.
  List<String> tagKeys = [];

  /// Pre-filled amount (0 or null means user enters each time).
  double? defaultAmount;

  /// Pre-filled note.
  String? defaultNote;

  /// Execution mode: `direct`, `confirm`, or `edit`.
  late String mode;

  // ---- Visibility flags ----

  /// Show in the home-screen shortcut bar.
  bool showOnHome = true;

  /// Show in the quick-action hub.
  bool showInHub = true;

  /// Show in the iOS/Android shortcuts.
  bool showInShortcuts = false;

  /// Show in the home-screen widget.
  bool showInWidget = false;

  // ---- Usage tracking ----

  /// Lifetime usage counter.
  int usageCount = 0;

  /// Timestamp of the most recent execution.
  DateTime? lastUsedAt;

  /// If migrated from a [JiveTemplate], stores the original template id.
  int? legacyTemplateId;

  /// Creation timestamp.
  late DateTime createdAt;
}
