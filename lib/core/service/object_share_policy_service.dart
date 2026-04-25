import '../database/book_model.dart';
import '../database/shared_ledger_model.dart';

enum ObjectShareVisibility { private, inheritedFromScene, shared }

class ObjectSharePolicy {
  final ObjectShareVisibility visibility;
  final String label;
  final String? warning;

  const ObjectSharePolicy({
    required this.visibility,
    required this.label,
    this.warning,
  });
}

/// First-stage object sharing policy: user-facing visibility and safety hints.
///
/// This intentionally does not create a second permission source; actual write
/// permissions still come from the shared ledger/book role model.
class ObjectSharePolicyService {
  const ObjectSharePolicyService();

  ObjectSharePolicy evaluate({
    required JiveBook? book,
    JiveSharedLedger? sharedLedger,
    bool explicitlyShared = false,
    bool objectIsPrivate = false,
    String objectLabel = '对象',
  }) {
    final isSharedScene =
        book?.isShared == true ||
        (book?.sharedLedgerKey != null && book!.sharedLedgerKey!.isNotEmpty) ||
        sharedLedger != null;

    if (explicitlyShared) {
      return ObjectSharePolicy(
        visibility: ObjectShareVisibility.shared,
        label: '共享',
        warning: '修改「$objectLabel」会影响共享成员看到的内容。',
      );
    }

    if (isSharedScene && !objectIsPrivate) {
      return ObjectSharePolicy(
        visibility: ObjectShareVisibility.inheritedFromScene,
        label: '继承场景共享',
        warning: '此「$objectLabel」位于共享场景中，相关交易会同步给场景成员。',
      );
    }

    return const ObjectSharePolicy(
      visibility: ObjectShareVisibility.private,
      label: '私有',
    );
  }

  String? privateObjectInSharedSceneWarning({
    required JiveBook? book,
    required bool objectIsPrivate,
    required String objectLabel,
  }) {
    final isSharedScene =
        book?.isShared == true ||
        (book?.sharedLedgerKey != null && book!.sharedLedgerKey!.isNotEmpty);
    if (!isSharedScene || !objectIsPrivate) return null;
    return '私有$objectLabel不能直接用于共享场景交易，请替换为共享对象或先退出共享场景。';
  }

  String deletionWarning({
    required String objectLabel,
    required int affectedTransactionCount,
    bool shared = false,
  }) {
    final scope = shared ? '共享成员' : '本地账本';
    if (affectedTransactionCount <= 0) {
      return '删除「$objectLabel」后，将不再出现在$scope的候选列表中。';
    }
    return '删除「$objectLabel」会影响$scope中 $affectedTransactionCount 笔交易的展示和筛选。';
  }
}
