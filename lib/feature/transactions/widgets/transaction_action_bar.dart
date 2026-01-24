import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme.dart';

class TransactionActionBar extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onSaveAsTemplate;
  final VoidCallback? onMarkRefund;
  final VoidCallback? onShare;

  const TransactionActionBar({
    super.key,
    required this.onDelete,
    required this.onEdit,
    this.onCopy,
    this.onSaveAsTemplate,
    this.onMarkRefund,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：删除按钮
          _buildIconButton(
            Icons.delete_outline,
            '删除',
            onDelete,
            color: Colors.red.shade400,
          ),
          const SizedBox(width: 8),
          // 中间：快捷操作
          _buildIconButton(
            Icons.copy_outlined,
            '复制',
            onCopy ?? () {},
            enabled: onCopy != null,
          ),
          _buildIconButton(
            Icons.bookmark_add_outlined,
            '模板',
            onSaveAsTemplate ?? () {},
            enabled: onSaveAsTemplate != null,
          ),
          _buildIconButton(
            Icons.replay_outlined,
            '退款',
            onMarkRefund ?? () {},
            enabled: onMarkRefund != null,
          ),
          _buildIconButton(
            Icons.share_outlined,
            '分享',
            onShare ?? () {},
            enabled: onShare != null,
          ),
          const Spacer(),
          // 右侧：编辑按钮
          ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              '编辑',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: JiveTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    bool enabled = true,
    Color? color,
  }) {
    final iconColor = enabled
        ? (color ?? Colors.grey.shade600)
        : Colors.grey.shade300;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }

}
