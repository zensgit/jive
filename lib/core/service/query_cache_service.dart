import 'package:isar/isar.dart';

import '../database/account_model.dart';
import '../database/category_model.dart';
import '../database/tag_model.dart';
import 'account_service.dart';

/// In-memory cache for frequently accessed data (categories, tags, accounts).
///
/// Uses a TTL of 30 seconds. Call [invalidateCache] after any data mutation.
class QueryCacheService {
  QueryCacheService(this._isar);

  final Isar _isar;

  static const Duration _ttl = Duration(seconds: 30);

  List<JiveCategory>? _categories;
  DateTime? _categoriesFetchedAt;

  List<JiveTag>? _tags;
  DateTime? _tagsFetchedAt;

  List<JiveAccount>? _accounts;
  DateTime? _accountsFetchedAt;

  bool _isValid(DateTime? fetchedAt) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < _ttl;
  }

  /// Returns cached categories, or fetches from Isar if stale/missing.
  Future<List<JiveCategory>> getCachedCategories() async {
    if (_categories != null && _isValid(_categoriesFetchedAt)) {
      return _categories!;
    }
    _categories =
        await _isar.collection<JiveCategory>().where().findAll();
    _categoriesFetchedAt = DateTime.now();
    return _categories!;
  }

  /// Returns cached tags, or fetches from Isar if stale/missing.
  Future<List<JiveTag>> getCachedTags() async {
    if (_tags != null && _isValid(_tagsFetchedAt)) {
      return _tags!;
    }
    _tags = await _isar.collection<JiveTag>().where().findAll();
    _tagsFetchedAt = DateTime.now();
    return _tags!;
  }

  /// Returns cached active accounts, or fetches from Isar if stale/missing.
  Future<List<JiveAccount>> getCachedAccounts({int? bookId}) async {
    if (_accounts != null && _isValid(_accountsFetchedAt)) {
      return _accounts!;
    }
    _accounts =
        await AccountService(_isar).getActiveAccounts(bookId: bookId);
    _accountsFetchedAt = DateTime.now();
    return _accounts!;
  }

  /// Clears all cached data. Call this after any data change.
  void invalidateCache() {
    _categories = null;
    _categoriesFetchedAt = null;
    _tags = null;
    _tagsFetchedAt = null;
    _accounts = null;
    _accountsFetchedAt = null;
  }
}
