/// Individual permissions that can be granted to ledger members.
enum LedgerPermission {
  view,
  create,
  edit,
  delete,
  invite,
  manageMembers,
  manageBudget,
  exportData,
}

/// Static permission matrix and helper methods for RBAC checks.
class PermissionMatrix {
  PermissionMatrix._();

  /// Role → permitted actions.
  static const Map<String, Set<LedgerPermission>> _matrix = {
    'owner': {
      LedgerPermission.view,
      LedgerPermission.create,
      LedgerPermission.edit,
      LedgerPermission.delete,
      LedgerPermission.invite,
      LedgerPermission.manageMembers,
      LedgerPermission.manageBudget,
      LedgerPermission.exportData,
    },
    'admin': {
      LedgerPermission.view,
      LedgerPermission.create,
      LedgerPermission.edit,
      LedgerPermission.delete,
      LedgerPermission.invite,
      LedgerPermission.manageBudget,
      LedgerPermission.exportData,
    },
    'member': {
      LedgerPermission.view,
      LedgerPermission.create,
      LedgerPermission.edit,
    },
    'readonly': {
      LedgerPermission.view,
    },
  };

  /// Mapping from human-readable action strings to [LedgerPermission].
  static const Map<String, LedgerPermission> _actionMap = {
    'view_transaction': LedgerPermission.view,
    'create_transaction': LedgerPermission.create,
    'edit_transaction': LedgerPermission.edit,
    'delete_transaction': LedgerPermission.delete,
    'invite_member': LedgerPermission.invite,
    'manage_members': LedgerPermission.manageMembers,
    'manage_budget': LedgerPermission.manageBudget,
    'export_data': LedgerPermission.exportData,
  };

  /// Whether [role] is allowed [permission].
  static bool hasPermission(String role, LedgerPermission permission) {
    return _matrix[role]?.contains(permission) ?? false;
  }

  /// All permissions granted to [role].
  static Set<LedgerPermission> getPermissions(String role) {
    return _matrix[role] ?? const {};
  }

  /// Whether [role] may perform [action] (e.g. `'create_transaction'`).
  static bool canPerformAction(String role, String action) {
    final permission = _actionMap[action];
    if (permission == null) return false;
    return hasPermission(role, permission);
  }

  /// Chinese display label for [role].
  static String getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return '所有者';
      case 'admin':
        return '管理员';
      case 'member':
        return '成员';
      case 'readonly':
        return '只读';
      default:
        return role;
    }
  }

  /// Chinese display label for [permission].
  static String getPermissionLabel(LedgerPermission permission) {
    switch (permission) {
      case LedgerPermission.view:
        return '查看账目';
      case LedgerPermission.create:
        return '新增账目';
      case LedgerPermission.edit:
        return '编辑账目';
      case LedgerPermission.delete:
        return '删除账目';
      case LedgerPermission.invite:
        return '邀请成员';
      case LedgerPermission.manageMembers:
        return '管理成员';
      case LedgerPermission.manageBudget:
        return '管理预算';
      case LedgerPermission.exportData:
        return '导出数据';
    }
  }

  /// Short Chinese description of what [permission] allows.
  static String getPermissionDescription(LedgerPermission permission) {
    switch (permission) {
      case LedgerPermission.view:
        return '查看账本中的所有交易记录';
      case LedgerPermission.create:
        return '新增交易记录到共享账本';
      case LedgerPermission.edit:
        return '修改已有的交易记录';
      case LedgerPermission.delete:
        return '删除账本中的交易记录';
      case LedgerPermission.invite:
        return '邀请新成员加入账本';
      case LedgerPermission.manageMembers:
        return '管理成员角色与权限';
      case LedgerPermission.manageBudget:
        return '设置和调整账本预算';
      case LedgerPermission.exportData:
        return '导出账本数据为文件';
    }
  }

  /// All role keys in descending privilege order.
  static const List<String> roles = ['owner', 'admin', 'member', 'readonly'];
}
