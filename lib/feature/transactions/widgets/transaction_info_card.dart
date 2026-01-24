import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/database/transaction_model.dart';
import 'transaction_tag_chips.dart';

class TransactionInfoCard extends StatelessWidget {
  final JiveTransaction transaction;
  final String? projectName;

  const TransactionInfoCard({
    super.key,
    required this.transaction,
    this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 时间
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: '时间',
            value: _formatDateTime(transaction.timestamp),
          ),
          _buildDivider(),
          // 来源
          _buildInfoRow(
            icon: Icons.smartphone_outlined,
            label: '来源',
            value: transaction.source,
          ),
          // 项目 (如果有)
          if (projectName != null && projectName!.isNotEmpty) ...[
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.folder_outlined,
              label: '项目',
              value: projectName!,
              showArrow: true,
              valueColor: const Color(0xFF2E7D32),
            ),
          ],
          // 标签 (如果有)
          if (transaction.note != null && _extractTags(transaction.note!).isNotEmpty) ...[
            _buildDivider(),
            TransactionTagChips(tags: _extractTags(transaction.note!)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool showArrow = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey.shade800,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }

  String _formatDateTime(DateTime dt) {
    final date = DateFormat('yyyy-MM-dd').format(dt);
    final weekday = DateFormat('EEEE', 'zh_CN').format(dt);
    final time = DateFormat('HH:mm').format(dt);
    return '$date $weekday $time';
  }

  // 从备注中提取标签 (以 # 开头的词)
  String _extractTags(String note) {
    final regex = RegExp(r'#(\S+)');
    final matches = regex.allMatches(note);
    final tags = matches.map((m) => m.group(1)!).toList();
    return tags.join(',');
  }
}
