import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/book_model.dart';

class HomeTopBar extends StatelessWidget {
  final bool compact;
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
    required this.books,
    required this.currentBookId,
    required this.pendingDraftCount,
    required this.onSearch,
    required this.onCalendar,
    required this.onGearMenu,
    required this.onBookSwitch,
  });

  @override
  Widget build(BuildContext context) {
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
              "Good Evening,",
              style: GoogleFonts.lato(
                color: Colors.grey,
                fontSize: greetingSize,
              ),
            ),
            Text(
              "Huazhou",
              style: GoogleFonts.lato(
                color: Colors.black87,
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
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.search,
                  color: Colors.black54,
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
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.black54,
                  size: iconSize,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onGearMenu,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.settings,
                  color: Colors.black54,
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
    final label = currentBook?.name ?? '全部账本';
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
                  child: Text('切换账本',
                      style: GoogleFonts.lato(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive, size: 20),
                  title: const Text('全部账本'),
                  trailing: currentBookId == null
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onBookSwitch(null);
                  },
                ),
                ...books.map((book) => ListTile(
                      leading: Icon(
                        book.isDefault ? Icons.book : Icons.book_outlined,
                        size: 20,
                        color: book.isDefault
                            ? const Color(0xFF2E7D32)
                            : null,
                      ),
                      title: Text(book.name),
                      subtitle: book.isDefault
                          ? const Text('默认',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF2E7D32)))
                          : null,
                      trailing: currentBookId == book.id
                          ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onBookSwitch(book.id);
                      },
                    )),
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
            Icon(Icons.book_outlined,
                size: fontSize + 2, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.lato(
                    fontSize: fontSize,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down,
                size: fontSize + 2, color: const Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }
}
