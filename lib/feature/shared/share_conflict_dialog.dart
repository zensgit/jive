import 'package:flutter/material.dart';

import '../../core/service/object_sharing_service.dart';

/// Dialog that warns the user before a destructive or shared action.
///
/// Call [showIfNeeded] before performing create / edit / delete operations on
/// objects that might be shared. If no warning applies the method returns
/// `true` immediately without showing any UI.
class ShareConflictDialog {
  ShareConflictDialog._();

  /// Shows a warning dialog when [ObjectSharingService.getConflictWarning]
  /// returns non-null for the given object and action.
  ///
  /// Returns `true` if the user chose to continue (or no warning was needed),
  /// `false` if the user cancelled.
  static Future<bool> showIfNeeded(
    BuildContext context, {
    required ObjectSharingService sharingService,
    required String objectType,
    required int objectId,
    required String action,
  }) async {
    final warning =
        sharingService.getConflictWarning(objectType, objectId, action);

    if (warning == null) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('共享提醒'),
        content: Text(warning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
