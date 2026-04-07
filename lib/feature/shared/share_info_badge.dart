import 'package:flutter/material.dart';

import '../../core/model/share_permission.dart';
import '../../core/service/object_sharing_service.dart';

/// A small badge that visualises an object's sharing status.
///
/// Place next to any object name (account, category, tag, etc.) to show
/// whether the item is private, shared, or inherited from its parent scene.
/// Tapping the badge displays a tooltip with a description.
class ShareInfoBadge extends StatelessWidget {
  final ObjectSharingService sharingService;
  final String objectType;
  final int objectId;

  const ShareInfoBadge({
    super.key,
    required this.sharingService,
    required this.objectType,
    required this.objectId,
  });

  @override
  Widget build(BuildContext context) {
    final info = sharingService.getShareInfo(objectType, objectId);
    final icon = _iconFor(info.visibility);
    final label = sharingService.getVisibilityLabel(info.visibility);

    return Tooltip(
      message: '$label · ${info.memberCount}人可见',
      child: GestureDetector(
        onTap: () => _showDetail(context, info, label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _backgroundFor(info.visibility),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: _foregroundFor(info.visibility)),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: _foregroundFor(info.visibility),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  IconData _iconFor(ShareVisibility v) {
    switch (v) {
      case ShareVisibility.private:
        return Icons.lock_outline;
      case ShareVisibility.shared:
        return Icons.group_outlined;
      case ShareVisibility.inherited:
        return Icons.reply;
    }
  }

  Color _backgroundFor(ShareVisibility v) {
    switch (v) {
      case ShareVisibility.private:
        return const Color(0xFFF5F5F5);
      case ShareVisibility.shared:
        return const Color(0xFFE8F5E9);
      case ShareVisibility.inherited:
        return const Color(0xFFFFF3E0);
    }
  }

  Color _foregroundFor(ShareVisibility v) {
    switch (v) {
      case ShareVisibility.private:
        return const Color(0xFF757575);
      case ShareVisibility.shared:
        return const Color(0xFF2E7D32);
      case ShareVisibility.inherited:
        return const Color(0xFFE65100);
    }
  }

  void _showDetail(
    BuildContext context,
    ObjectShareInfo info,
    String label,
  ) {
    final ownerText = info.ownerName != null ? '所有者: ${info.ownerName}' : '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$label · ${info.objectType}'),
        content: Text(
          '$ownerText\n成员数: ${info.memberCount}\n'
          '你的角色: ${info.currentUserRole.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
