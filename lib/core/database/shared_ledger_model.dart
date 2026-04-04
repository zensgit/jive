import 'package:isar/isar.dart';

part 'shared_ledger_model.g.dart';

/// A shared family ledger that multiple users can collaborate on.
@collection
class JiveSharedLedger {
  Id id = Isar.autoIncrement;

  /// Unique key for sync with Supabase
  @Index(unique: true)
  String key = '';

  /// Display name
  String name = '';

  /// Owner user ID (Supabase auth.uid)
  String ownerUserId = '';

  /// Currency code
  String currency = 'CNY';

  /// Invite code for joining (6-char alphanumeric)
  String? inviteCode;

  /// Whether the current user is the owner
  bool isOwner = false;

  /// User's role: owner, admin, member, readonly
  String role = 'member';

  /// Number of members
  int memberCount = 1;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

/// A member in a shared ledger.
@collection
class JiveSharedLedgerMember {
  Id id = Isar.autoIncrement;

  /// Ledger key
  @Index()
  String ledgerKey = '';

  /// Member user ID
  String userId = '';

  /// Display name
  String displayName = '';

  /// Role: owner, admin, member, readonly
  String role = 'member';

  /// When they joined
  DateTime joinedAt = DateTime.now();
}
