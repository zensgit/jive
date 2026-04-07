/// Pure Dart view-model representing a "Scene" — a Book wrapped with
/// user-level filter & UI preferences.
///
/// Scenes are the product-layer concept shown to users; under the hood each
/// Scene maps 1:1 to a [JiveBook].
class Scene {
  final int bookId;
  final String bookKey;
  final String name;
  final String? emoji;
  final String? accentColorHex;
  final List<String> defaultCategoryKeys;
  final List<String> defaultTagKeys;
  final int? defaultProjectId;
  final bool isDefault;
  final bool isShared;

  // UI preferences (persisted via SharedPreferences per scene).
  final bool showBudgetOnHome;
  final bool showGoalsOnHome;

  const Scene({
    required this.bookId,
    required this.bookKey,
    required this.name,
    this.emoji,
    this.accentColorHex,
    this.defaultCategoryKeys = const [],
    this.defaultTagKeys = const [],
    this.defaultProjectId,
    this.isDefault = false,
    this.isShared = false,
    this.showBudgetOnHome = true,
    this.showGoalsOnHome = false,
  });

  /// Creates a copy with the given fields replaced.
  Scene copyWith({
    int? bookId,
    String? bookKey,
    String? name,
    String? emoji,
    String? accentColorHex,
    List<String>? defaultCategoryKeys,
    List<String>? defaultTagKeys,
    int? defaultProjectId,
    bool? isDefault,
    bool? isShared,
    bool? showBudgetOnHome,
    bool? showGoalsOnHome,
  }) {
    return Scene(
      bookId: bookId ?? this.bookId,
      bookKey: bookKey ?? this.bookKey,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      defaultCategoryKeys: defaultCategoryKeys ?? this.defaultCategoryKeys,
      defaultTagKeys: defaultTagKeys ?? this.defaultTagKeys,
      defaultProjectId: defaultProjectId ?? this.defaultProjectId,
      isDefault: isDefault ?? this.isDefault,
      isShared: isShared ?? this.isShared,
      showBudgetOnHome: showBudgetOnHome ?? this.showBudgetOnHome,
      showGoalsOnHome: showGoalsOnHome ?? this.showGoalsOnHome,
    );
  }

  @override
  String toString() => 'Scene($bookId, $name, emoji=$emoji)';
}
