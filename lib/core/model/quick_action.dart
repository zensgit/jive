/// Execution mode for a [QuickAction].
///
/// - [direct]: all required fields are present; the transaction can be saved
///   immediately without any user input.
/// - [confirm]: some fields (e.g. amount) are missing; a lightweight
///   confirmation sheet is shown before saving.
/// - [edit]: opens the full transaction editor with prefilled fields.
enum QuickActionMode { direct, confirm, edit }

/// A pure-Dart view-model that wraps a template or user-defined shortcut.
///
/// Stage 1 of the QuickAction roadmap: this class is **not** persisted via
/// Isar. Instead, instances are converted on-the-fly from [JiveTemplate] by
/// [QuickActionService.toQuickAction].
class QuickAction {
  final String id;
  final String name;
  final String? iconName;
  final String? colorHex;

  /// Transaction type: `expense`, `income`, or `transfer`.
  final String transactionType;

  final int? bookId;
  final int? accountId;
  final String? categoryKey;
  final String? subCategoryKey;
  final List<String> tagKeys;
  final double? defaultAmount;
  final String? defaultNote;

  /// Determines how the action is executed when tapped.
  final QuickActionMode mode;

  /// Whether this action should appear in the home-screen shortcut bar.
  final bool showOnHome;

  /// Lifetime usage counter (carried over from [JiveTemplate.usageCount]).
  final int usageCount;

  /// Last time this action was executed.
  final DateTime? lastUsedAt;

  /// If this action was converted from a [JiveTemplate], stores the original
  /// template id for traceability.
  final int? legacyTemplateId;

  const QuickAction({
    required this.id,
    required this.name,
    this.iconName,
    this.colorHex,
    required this.transactionType,
    this.bookId,
    this.accountId,
    this.categoryKey,
    this.subCategoryKey,
    this.tagKeys = const [],
    this.defaultAmount,
    this.defaultNote,
    required this.mode,
    this.showOnHome = true,
    this.usageCount = 0,
    this.lastUsedAt,
    this.legacyTemplateId,
  });

  /// Creates a copy with the given fields replaced.
  QuickAction copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    String? transactionType,
    int? bookId,
    int? accountId,
    String? categoryKey,
    String? subCategoryKey,
    List<String>? tagKeys,
    double? defaultAmount,
    String? defaultNote,
    QuickActionMode? mode,
    bool? showOnHome,
    int? usageCount,
    DateTime? lastUsedAt,
    int? legacyTemplateId,
  }) {
    return QuickAction(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      transactionType: transactionType ?? this.transactionType,
      bookId: bookId ?? this.bookId,
      accountId: accountId ?? this.accountId,
      categoryKey: categoryKey ?? this.categoryKey,
      subCategoryKey: subCategoryKey ?? this.subCategoryKey,
      tagKeys: tagKeys ?? this.tagKeys,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      defaultNote: defaultNote ?? this.defaultNote,
      mode: mode ?? this.mode,
      showOnHome: showOnHome ?? this.showOnHome,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      legacyTemplateId: legacyTemplateId ?? this.legacyTemplateId,
    );
  }

  @override
  String toString() => 'QuickAction($id, $name, mode=$mode)';
}
