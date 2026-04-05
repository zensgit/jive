import 'package:flutter/material.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/permission_service.dart';

/// Displays the RBAC permission matrix for a shared ledger.
///
/// Shows a table of roles (columns) × permissions (rows) with checkmarks,
/// highlights the current user's role, and provides info cards for each
/// permission.
class PermissionSettingsScreen extends StatelessWidget {
  /// The logged-in user's role in the current ledger.
  final String currentRole;

  const PermissionSettingsScreen({super.key, required this.currentRole});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? JiveTheme.darkSurface : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('权限说明', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildCurrentRoleBanner(context),
          const SizedBox(height: 16),
          _buildRoleDescriptions(context),
          const SizedBox(height: 16),
          _buildPermissionMatrix(context),
          const SizedBox(height: 16),
          _buildPermissionInfoCards(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Current role banner
  // ---------------------------------------------------------------------------

  Widget _buildCurrentRoleBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JiveTheme.primaryGreen.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: JiveTheme.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            '当前角色：',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: JiveTheme.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              PermissionMatrix.getRoleLabel(currentRole),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Role descriptions
  // ---------------------------------------------------------------------------

  Widget _buildRoleDescriptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? JiveTheme.darkCard : Colors.white;

    const descriptions = <String, String>{
      'owner': '账本创建者，拥有全部权限',
      'admin': '管理员，可管理预算与邀请',
      'member': '普通成员，可查看和记账',
      'readonly': '只读成员，仅可查看',
    };

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '角色说明',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...PermissionMatrix.roles.map((role) {
              final isCurrentRole = role == currentRole;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentRole
                            ? JiveTheme.primaryGreen
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        PermissionMatrix.getRoleLabel(role),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCurrentRole
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        descriptions[role] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Permission matrix table
  // ---------------------------------------------------------------------------

  Widget _buildPermissionMatrix(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? JiveTheme.darkCard : Colors.white;
    final dividerColor = isDark ? JiveTheme.darkDivider : Colors.grey.shade200;

    final roles = PermissionMatrix.roles;
    final permissions = LedgerPermission.values;

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '权限矩阵',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                columnSpacing: 12,
                horizontalMargin: 8,
                dividerThickness: 0.5,
                headingRowColor: WidgetStateProperty.all(
                  isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                ),
                border: TableBorder.all(color: dividerColor, width: 0.5),
                columns: [
                  DataColumn(
                    label: Text(
                      '权限',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  ...roles.map(
                    (role) => DataColumn(
                      label: _buildRoleHeader(role, isDark),
                    ),
                  ),
                ],
                rows: permissions.map((perm) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          PermissionMatrix.getPermissionLabel(perm),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      ...roles.map((role) {
                        final allowed =
                            PermissionMatrix.hasPermission(role, perm);
                        return DataCell(
                          Center(
                            child: allowed
                                ? const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: JiveTheme.primaryGreen,
                                  )
                                : Icon(
                                    Icons.remove_circle_outline,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleHeader(String role, bool isDark) {
    final isCurrentRole = role == currentRole;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          PermissionMatrix.getRoleLabel(role),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isCurrentRole
                ? JiveTheme.primaryGreen
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        if (isCurrentRole)
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: JiveTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Permission info cards
  // ---------------------------------------------------------------------------

  Widget _buildPermissionInfoCards(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? JiveTheme.darkCard : Colors.white;

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '权限详情',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...LedgerPermission.values.map((perm) {
              final allowed =
                  PermissionMatrix.hasPermission(currentRole, perm);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      allowed ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: allowed
                          ? JiveTheme.primaryGreen
                          : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PermissionMatrix.getPermissionLabel(perm),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            PermissionMatrix.getPermissionDescription(perm),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
