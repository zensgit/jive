import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/book_model.dart';
import '../model/scene.dart';
import 'book_service.dart';

/// Service that wraps [BookService] with per-scene UI preferences, exposing the
/// "Scene" product concept to the rest of the app.
///
/// Preferences (category filters, tag defaults, UI toggles, accent color) are
/// stored in [SharedPreferences] keyed by `scene_<bookId>_*`.
class SceneService extends ChangeNotifier {
  final BookService _bookService;
  final SharedPreferences _prefs;

  /// Currently active book id. Null means default book.
  int? _activeBookId;

  SceneService(this._bookService, this._prefs) {
    _activeBookId = _prefs.getInt(_kActiveBookIdKey);
  }

  // ---------------------------------------------------------------------------
  // SharedPreferences keys
  // ---------------------------------------------------------------------------

  static const _kActiveBookIdKey = 'scene_active_book_id';

  static String _emojiKey(int bookId) => 'scene_${bookId}_emoji';
  static String _accentKey(int bookId) => 'scene_${bookId}_accent';
  static String _categoryKeysKey(int bookId) =>
      'scene_${bookId}_category_keys';
  static String _tagKeysKey(int bookId) => 'scene_${bookId}_tag_keys';
  static String _projectIdKey(int bookId) => 'scene_${bookId}_project_id';
  static String _showBudgetKey(int bookId) => 'scene_${bookId}_show_budget';
  static String _showGoalsKey(int bookId) => 'scene_${bookId}_show_goals';
  static String _isSharedKey(int bookId) => 'scene_${bookId}_is_shared';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all scenes derived from active (non-archived) books.
  Future<List<Scene>> getScenes() async {
    final books = await _bookService.getActiveBooks();
    return books.map((b) => getSceneForBook(b)).toList();
  }

  /// Returns the currently active scene, or null if no books exist.
  Future<Scene?> getCurrentScene() async {
    if (_activeBookId != null) {
      final books = await _bookService.getActiveBooks();
      final match = books.where((b) => b.id == _activeBookId);
      if (match.isNotEmpty) {
        return getSceneForBook(match.first);
      }
    }
    // Fall back to default book.
    final defaultBook = await _bookService.getDefaultBook();
    if (defaultBook == null) return null;
    return getSceneForBook(defaultBook);
  }

  /// Switches the active scene to the given [bookId] and notifies listeners.
  Future<void> switchScene(int bookId) async {
    _activeBookId = bookId;
    await _prefs.setInt(_kActiveBookIdKey, bookId);
    notifyListeners();
  }

  /// Creates a new scene by creating a book and storing initial preferences.
  Future<Scene> createScene(
    String name,
    String? emoji, {
    List<String> categoryKeys = const [],
    List<String> tagKeys = const [],
    int? projectId,
  }) async {
    final book = await _bookService.createBook(
      name: name,
      iconName: 'book',
    );
    final bookId = book.id;

    // Store per-scene preferences.
    if (emoji != null) await _prefs.setString(_emojiKey(bookId), emoji);
    if (categoryKeys.isNotEmpty) {
      await _prefs.setString(
          _categoryKeysKey(bookId), jsonEncode(categoryKeys));
    }
    if (tagKeys.isNotEmpty) {
      await _prefs.setString(_tagKeysKey(bookId), jsonEncode(tagKeys));
    }
    if (projectId != null) {
      await _prefs.setInt(_projectIdKey(bookId), projectId);
    }

    notifyListeners();
    return getSceneForBook(book);
  }

  /// Updates UI preferences for a scene.
  Future<void> updateScenePrefs(
    int bookId, {
    bool? showBudget,
    bool? showGoals,
    String? accentColor,
    String? emoji,
    bool? isShared,
  }) async {
    if (showBudget != null) {
      await _prefs.setBool(_showBudgetKey(bookId), showBudget);
    }
    if (showGoals != null) {
      await _prefs.setBool(_showGoalsKey(bookId), showGoals);
    }
    if (accentColor != null) {
      await _prefs.setString(_accentKey(bookId), accentColor);
    }
    if (emoji != null) {
      await _prefs.setString(_emojiKey(bookId), emoji);
    }
    if (isShared != null) {
      await _prefs.setBool(_isSharedKey(bookId), isShared);
    }
    notifyListeners();
  }

  /// Converts a [JiveBook] into a [Scene] by reading stored preferences.
  Scene getSceneForBook(JiveBook book) {
    final bookId = book.id;

    final emoji = _prefs.getString(_emojiKey(bookId));
    final accent = _prefs.getString(_accentKey(bookId));
    final projectId = _prefs.getInt(_projectIdKey(bookId));
    final showBudget = _prefs.getBool(_showBudgetKey(bookId)) ?? true;
    final showGoals = _prefs.getBool(_showGoalsKey(bookId)) ?? false;
    final isShared = _prefs.getBool(_isSharedKey(bookId)) ?? false;

    List<String> categoryKeys = const [];
    final catJson = _prefs.getString(_categoryKeysKey(bookId));
    if (catJson != null) {
      categoryKeys = List<String>.from(jsonDecode(catJson) as List);
    }

    List<String> tagKeys = const [];
    final tagJson = _prefs.getString(_tagKeysKey(bookId));
    if (tagJson != null) {
      tagKeys = List<String>.from(jsonDecode(tagJson) as List);
    }

    return Scene(
      bookId: bookId,
      bookKey: book.key,
      name: book.name,
      emoji: emoji,
      accentColorHex: accent ?? book.colorHex,
      defaultCategoryKeys: categoryKeys,
      defaultTagKeys: tagKeys,
      defaultProjectId: projectId,
      isDefault: book.isDefault,
      isShared: isShared,
      showBudgetOnHome: showBudget,
      showGoalsOnHome: showGoals,
    );
  }
}
