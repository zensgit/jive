/// Visibility level of a shared object.
enum ShareVisibility { private, shared, inherited }

/// Role the current user has on a shared object.
enum ShareRole { owner, editor, viewer }

/// Describes the sharing state of a single domain object (scene, account,
/// category, or tag).
class ObjectShareInfo {
  /// The domain type: `scene`, `account`, `category`, or `tag`.
  final String objectType;

  /// Primary key of the object in its respective table.
  final int objectId;

  /// Current sharing visibility.
  final ShareVisibility visibility;

  /// The logged-in user's role on this object.
  final ShareRole currentUserRole;

  /// Display name of the owner, if available.
  final String? ownerName;

  /// Number of members who can see this object.
  final int memberCount;

  const ObjectShareInfo({
    required this.objectType,
    required this.objectId,
    required this.visibility,
    required this.currentUserRole,
    this.ownerName,
    this.memberCount = 1,
  });

  /// Creates a copy with the given fields replaced.
  ObjectShareInfo copyWith({
    String? objectType,
    int? objectId,
    ShareVisibility? visibility,
    ShareRole? currentUserRole,
    String? ownerName,
    int? memberCount,
  }) {
    return ObjectShareInfo(
      objectType: objectType ?? this.objectType,
      objectId: objectId ?? this.objectId,
      visibility: visibility ?? this.visibility,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      ownerName: ownerName ?? this.ownerName,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  String toString() =>
      'ObjectShareInfo($objectType#$objectId, $visibility, role=$currentUserRole)';
}
