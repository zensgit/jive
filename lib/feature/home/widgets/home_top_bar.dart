import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/book_model.dart';
import '../../../core/service/object_share_policy_service.dart';

class HomeTopBar extends StatelessWidget {
  final bool compact;
  final String? displayName;
  final List<JiveBook> books;
  final int? currentBookId;
  final int pendingDraftCount;
  final VoidCallback onSearch;
  final VoidCallback onCalendar;
  final VoidCallback onGearMenu;
  final void Function(int?) onBookSwitch;

  const HomeTopBar({
    super.key,
    this.compact = false,
    this.displayName,
    required this.books,
    required this.currentBookId,
    required this.pendingDraftCount,
    required this.onSearch,
    required this.onCalendar,
    required this.onGearMenu,
    required this.onBookSwitch,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了,';
    if (hour < 12) return '早上好,';
    if (hour < 14) return '中午好,';
    if (hour < 18) return '下午好,';
    return '晚上好,';
  }

  String get _name => displayName?.isNotEmpty == true ? displayName! : '访客';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greetingSize = compact ? 12.0 : 14.0;
    final nameSize = compact ? 20.0 : 24.0;
    final avatarRadius = compact ? 18.0 : 20.0;
    final iconSize = compact ? 18.0 : 20.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: GoogleFonts.lato(
                color: isDark ? Colors.grey.shade400 : Colors.grey,
                fontSize: greetingSize,
              ),
            ),
            Text(
              _name,
              style: GoogleFonts.lato(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: nameSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (books.length > 1) ...[
              const SizedBox(height: 4),
              _buildBookSwitcher(context),
            ],
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '搜索交易',
              onPressed: onSearch,
              icon: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.search,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: iconSize,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '日历视图',
              onPressed: onCalendar,
              icon: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: iconSize,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onGearMenu,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.settings,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: iconSize,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookSwitcher(BuildContext context) {
    final currentBook = books.where((b) => b.id == currentBookId).firstOrNull;
    final label = currentBook?.name ?? '全部场景';
    final fontSize = compact ? 11.0 : 12.0;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '切换场景',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive, size: 20),
                  title: const Text('全部场景'),
                  trailing: currentBookId == null
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onBookSwitch(null);
                  },
                ),
                ...books.map((book) {
                  final sharePolicy = const ObjectSharePolicyService().evaluate(
                    book: book,
                    objectLabel: '场景',
                  );
                  return ListTile(
                    leading: Icon(
                      book.isDefault
                          ? Icons.auto_awesome_mosaic
                          : Icons.auto_awesome_mosaic_outlined,
                      size: 20,
                      color: book.isDefault ? const Color(0xFF2E7D32) : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(book.name)),
                        if (sharePolicy.visibility !=
                            ObjectShareVisibility.private)
                          _buildShareBadge(sharePolicy.label),
                      ],
                    ),
                    subtitle: book.isDefault
                        ? const Text(
                            '默认场景',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                            ),
                          )
                        : null,
                    trailing: currentBookId == book.id
                        ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onBookSwitch(book.id);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_mosaic_outlined,
              size: fontSize + 2,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: fontSize,
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: fontSize + 2,
              color: const Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareBadge(String label) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 9,
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
