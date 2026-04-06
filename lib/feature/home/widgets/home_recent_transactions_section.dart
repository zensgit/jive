import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/database/account_model.dart';
import '../../../core/database/category_model.dart';
import '../../../core/database/currency_model.dart';
import '../../../core/database/tag_model.dart';
import '../../../core/database/transaction_model.dart';
import '../../../core/design_system/theme.dart';
import '../../../core/service/account_service.dart';
import '../../tag/tag_icon_catalog.dart';

class HomeRecentTransactionsSection extends StatelessWidget {
  final bool compact;
  final List<JiveTransaction> transactions;
  final Map<String, JiveCategory> categoryByKey;
  final Map<String, JiveTag> tagByKey;
  final Map<int, JiveAccount> accountById;
  final bool isLoading;
  final bool showSmartTagBadge;
  final int? currentBookId;
  final String baseCurrency;
  final VoidCallback onViewAll;
  final Future<bool?> Function(BuildContext context, int transactionId)
      onTransactionDetail;
  final VoidCallback onAddTransaction;
  final VoidCallback onDataChanged;

  const HomeRecentTransactionsSection({
    super.key,
    this.compact = false,
    required this.transactions,
    required this.categoryByKey,
    required this.tagByKey,
    required this.accountById,
    required this.isLoading,
    required this.showSmartTagBadge,
    required this.currentBookId,
    required this.baseCurrency,
    required this.onViewAll,
    required this.onTransactionDetail,
    required this.onAddTransaction,
    required this.onDataChanged,
  });

  Widget buildTitle() {
    final titleSize = compact ? 18.0 : 20.0;
    final actionSize = compact ? 12.0 : 14.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "最近交易",
            style: GoogleFonts.lato(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            key: const Key('home_view_all_transactions_button'),
            onTap: onViewAll,
            child: Text(
              "查看全部",
              style: GoogleFonts.lato(
                color: JiveTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: actionSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionList() {
    return Expanded(child: buildTransactionListBody());
  }

  Widget buildTransactionListBody({
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }
    // Group transactions by date
    final grouped = <String, List<JiveTransaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in transactions) {
      final txDate = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
      String label;
      if (txDate == today) {
        label = '今天';
      } else if (txDate == yesterday) {
        label = '昨天';
      } else if (txDate.year == now.year) {
        label = DateFormat('M月d日').format(tx.timestamp);
      } else {
        label = DateFormat('yyyy年M月d日').format(tx.timestamp);
      }
      grouped.putIfAbsent(label, () => []).add(tx);
    }

    final entries = grouped.entries.toList();

    // Pre-compute flat list with headers to avoid O(n²) in itemBuilder
    final flatItems = <Object>[];
    for (final entry in entries) {
      final dayTotal = entry.value.fold<double>(0, (sum, tx) {
        if (tx.type == 'expense') return sum - tx.amount;
        if (tx.type == 'income') return sum + tx.amount;
        return sum;
      });
      flatItems.add(_DateHeader(entry.key, dayTotal));
      flatItems.addAll(entry.value);
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: flatItems.length,
      itemBuilder: (context, index) {
        final item = flatItems[index];
        if (item is _DateHeader) {
          return _buildDateHeader(context, item.label, item.total);
        }
        return _buildTransactionItem(context, item as JiveTransaction);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is used via its individual builder methods
    // (buildTitle, buildTransactionList, buildTransactionListBody).
    // The build method returns the title as a default.
    return buildTitle();
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && categoryByKey.containsKey(key)) {
      return categoryByKey[key]!.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return "未分类";
  }

  Widget _buildTransactionItem(BuildContext context, JiveTransaction item) {
    final type = item.type ?? "expense";
    final isIncome = type == "income";
    final isTransfer = type == "transfer";
    final isWeChat = item.source == 'WeChat';
    IconData leadingIcon;
    Color leadingColor;
    Color leadingBg;
    if (isTransfer) {
      leadingIcon = Icons.swap_horiz;
      leadingColor = Colors.blueGrey;
      leadingBg = Colors.blueGrey.shade50;
    } else if (isWeChat) {
      leadingIcon = Icons.wechat;
      leadingColor = Colors.green;
      leadingBg = const Color(0xFFE8F5E9);
    } else {
      leadingIcon = Icons.payment;
      leadingColor = Colors.blue;
      leadingBg = const Color(0xFFE3F2FD);
    }
    final amountPrefix = isTransfer ? "" : (isIncome ? "+ " : "- ");
    final amountColor = isTransfer
        ? Colors.blueGrey
        : (isIncome ? Colors.green : Colors.redAccent);
    final parentName = _displayCategoryName(item.categoryKey, item.category);
    final subName = _displayCategoryName(item.subCategoryKey, item.subCategory);
    final note = (item.note ?? '').trim();
    final hasNote = note.isNotEmpty;
    final showSmartBadge = showSmartTagBadge && item.smartTagKeys.isNotEmpty;
    final tags = item.tagKeys
        .map((key) => tagByKey[key])
        .whereType<JiveTag>()
        .toList();

    // 获取交易账户的货币信息
    final account = item.accountId != null
        ? accountById[item.accountId]
        : null;
    final txCurrency = account?.currency ?? 'CNY';
    final txSymbol = CurrencyDefaults.getSymbol(txCurrency);
    final txDecimals = CurrencyDefaults.getDecimalPlaces(txCurrency);
    final isMultiCurrency = txCurrency != baseCurrency;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final updated = await onTransactionDetail(context, item.id);
        if (updated == true) {
          onDataChanged();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: leadingBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(leadingIcon, color: leadingColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$subName • ${DateFormat('MM-dd HH:mm').format(item.timestamp)}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (showSmartBadge) ...[
                        const SizedBox(width: 6),
                        _buildSmartTagBadge(),
                      ],
                    ],
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.take(3).map((tag) {
                        final color =
                            AccountService.parseColorHex(tag.colorHex) ??
                            Colors.blueGrey;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            tagDisplayName(tag),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$amountPrefix$txSymbol${item.amount.toStringAsFixed(txDecimals)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: amountColor,
                  ),
                ),
                if (isMultiCurrency)
                  Text(
                    txCurrency,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartTagBadge() {
    final badge = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: JiveTheme.primaryGreen.withValues(alpha: 0.4),
        ),
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 12,
        color: JiveTheme.primaryGreen,
      ),
    );
    return Tooltip(
      message: '该交易由智能标签自动打标',
      triggerMode: TooltipTriggerMode.longPress,
      child: badge,
    );
  }

  Widget _buildDateHeader(BuildContext context, String label, double dayTotal) {
    final theme = Theme.of(context);
    final totalStr = dayTotal >= 0
        ? '+${NumberFormat('#,##0.00').format(dayTotal)}'
        : NumberFormat('#,##0.00').format(dayTotal);
    final totalColor = dayTotal >= 0
        ? JiveTheme.primaryGreen
        : Colors.red.shade400;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            totalStr,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: totalColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 40, color: JiveTheme.primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            "还没有交易记录",
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "点击右下角 + 号记第一笔",
            style: GoogleFonts.lato(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onAddTransaction,
            icon: const Icon(Icons.add),
            label: const Text('记一笔'),
            style: OutlinedButton.styleFrom(
              foregroundColor: JiveTheme.primaryGreen,
              side: BorderSide(color: JiveTheme.primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight marker for pre-computed date headers in flat list.
class _DateHeader {
  final String label;
  final double total;
  const _DateHeader(this.label, this.total);
}
