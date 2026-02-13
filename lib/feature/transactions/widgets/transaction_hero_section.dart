import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/database/account_model.dart';
import '../../../core/database/category_model.dart';
import '../../../core/database/transaction_model.dart';
import '../../../core/design_system/theme.dart';
import '../../../core/service/category_service.dart';

class TransactionHeroSection extends StatelessWidget {
  final JiveTransaction transaction;
  final JiveCategory? category;
  final JiveCategory? subCategory;
  final JiveAccount? account;
  final JiveAccount? toAccount;

  const TransactionHeroSection({
    super.key,
    required this.transaction,
    this.category,
    this.subCategory,
    this.account,
    this.toAccount,
  });

  @override
  Widget build(BuildContext context) {
    final type = transaction.type ?? 'expense';
    final isTransfer = type == 'transfer';
    final isIncome = type == 'income';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            JiveTheme.primaryGreen.withValues(alpha: 0.08),
            JiveTheme.surfaceWhite,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // 分类图标
          _buildCategoryIcon(type),
          const SizedBox(height: 16),
          // 金额
          _buildAmount(type, isTransfer, isIncome),
          const SizedBox(height: 8),
          // 分类/转账描述
          _buildTitle(isTransfer),
          const SizedBox(height: 4),
          // 账户
          _buildSubtitle(isTransfer),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(String type) {
    final iconName = category?.iconName;
    final categoryColor =
        CategoryService.parseColorHex(category?.colorHex) ?? JiveTheme.primaryGreen;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: JiveTheme.primaryGreen.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: iconName != null
            ? CategoryService.buildIcon(
                iconName,
                size: 36,
                color: categoryColor,
                isSystemCategory: category?.isSystem,
                forceTinted: category?.iconForceTinted ?? false,
              )
            : _buildFallbackIcon(type),
      ),
    );
  }

  Widget _buildFallbackIcon(String type) {
    IconData icon;
    switch (type) {
      case 'income':
        icon = Icons.arrow_downward;
        break;
      case 'transfer':
        icon = Icons.swap_horiz;
        break;
      default:
        icon = Icons.shopping_bag_outlined;
    }
    return Icon(icon, size: 32, color: JiveTheme.primaryGreen);
  }

  Widget _buildAmount(String type, bool isTransfer, bool isIncome) {
    final format = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
    String prefix;
    Color color;

    if (isTransfer) {
      prefix = '';
      color = const Color(0xFF1E88E5);
    } else if (isIncome) {
      prefix = '+ ';
      color = const Color(0xFF43A047);
    } else {
      prefix = '- ';
      color = const Color(0xFFE53935);
    }

    return Text(
      '$prefix${format.format(transaction.amount)}',
      style: GoogleFonts.rubik(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _buildTitle(bool isTransfer) {
    String title;
    if (isTransfer) {
      title = '转账';
    } else {
      final catName = category?.name ?? transaction.category ?? '未分类';
      final subName = subCategory?.name ?? transaction.subCategory;
      title = subName != null && subName.isNotEmpty ? '$catName · $subName' : catName;
    }

    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildSubtitle(bool isTransfer) {
    String subtitle;
    if (isTransfer) {
      final fromName = account?.name ?? '未指定';
      final toName = toAccount?.name ?? '未指定';
      subtitle = '$fromName → $toName';
    } else {
      subtitle = account?.name ?? '未指定账户';
    }

    return Text(
      subtitle,
      style: GoogleFonts.lato(
        fontSize: 13,
        color: Colors.grey.shade500,
      ),
    );
  }
}
