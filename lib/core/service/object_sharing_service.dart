import 'package:shared_preferences/shared_preferences.dart';

import '../model/share_permission.dart';

/// Service for querying and mutating per-object sharing boundaries.
///
/// Visibility preferences are persisted in [SharedPreferences] keyed by
/// `share_<objectType>_<objectId>_visibility`.
class ObjectSharingService {
  final SharedPreferences _prefs;

  ObjectSharingService(this._prefs);

  // ---------------------------------------------------------------------------
  // SharedPreferences key helpers
  // ---------------------------------------------------------------------------

  static String _visibilityKey(String objectType, int objectId) =>
      'share_${objectType}_${objectId}_visibility';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the [ObjectShareInfo] for the given domain object.
  ///
  /// When no explicit visibility has been stored the object defaults to
  /// [ShareVisibility.private].
  ObjectShareInfo getShareInfo(String objectType, int objectId) {
    final visibility = _readVisibility(objectType, objectId);

    return ObjectShareInfo(
      objectType: objectType,
      objectId: objectId,
      visibility: visibility,
      currentUserRole: ShareRole.owner,
      ownerName: '我',
      memberCount: visibility == ShareVisibility.private ? 1 : 2,
    );
  }

  /// Persists the [ShareVisibility] for the given object.
  Future<void> setVisibility(
    String objectType,
    int objectId,
    ShareVisibility visibility,
  ) async {
    final key = _visibilityKey(objectType, objectId);
    await _prefs.setString(key, visibility.name);
  }

  /// Returns `true` when the object has been explicitly marked as shared.
  bool isShared(String objectType, int objectId) {
    final v = _readVisibility(objectType, objectId);
    return v == ShareVisibility.shared || v == ShareVisibility.inherited;
  }

  /// Returns a human-readable warning when performing [action] on a shared
  /// object, or `null` when no warning is needed.
  ///
  /// [action] is one of `create`, `edit`, or `delete`.
  String? getConflictWarning(
    String objectType,
    int objectId,
    String action,
  ) {
    final visibility = _readVisibility(objectType, objectId);

    if (visibility == ShareVisibility.private) {
      if (action == 'create' || action == 'edit') {
        return '此${_typeLabel(objectType)}仅你可见，不会同步';
      }
      return null;
    }

    // shared or inherited — warn about impact on other members.
    switch (action) {
      case 'edit':
        return '修改此${_typeLabel(objectType)}将同步到其他成员';
      case 'delete':
        return '删除此${_typeLabel(objectType)}会影响共享场景的其他用户';
      case 'create':
        return '此${_typeLabel(objectType)}属于共享场景，其他成员也能看到';
      default:
        return null;
    }
  }

  /// Maps a [ShareVisibility] value to a localised label.
  String getVisibilityLabel(ShareVisibility visibility) {
    switch (visibility) {
      case ShareVisibility.private:
        return '私有';
      case ShareVisibility.shared:
        return '共享';
      case ShareVisibility.inherited:
        return '继承场景';
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  ShareVisibility _readVisibility(String objectType, int objectId) {
    final raw = _prefs.getString(_visibilityKey(objectType, objectId));
    if (raw == null) return ShareVisibility.private;
    return ShareVisibility.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => ShareVisibility.private,
    );
  }

  String _typeLabel(String objectType) {
    switch (objectType) {
      case 'scene':
        return '场景';
      case 'account':
        return '账户';
      case 'category':
        return '分类';
      case 'tag':
        return '标签';
      case 'transaction':
        return '交易';
      default:
        return '对象';
    }
  }
}
