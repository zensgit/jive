import 'package:flutter/material.dart';
import '../../core/database/template_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/template_service.dart';
import '../import/screenshot_import_screen.dart';
import '../quick_add/conversational_input_screen.dart';
import '../template/template_list_screen.dart';
import '../transactions/add_transaction_screen.dart';

/// Bottom sheet shown on FAB long press.
///
/// Top section: 2x3 grid of entry mode cards.
/// Bottom section: horizontal scrollable list of top 5 templates by usage.
class QuickEntryHubSheet extends StatefulWidget {
  final int? bookId;
  final VoidCallback? onTransactionCreated;

  const QuickEntryHubSheet({
    super.key,
    this.bookId,
    this.onTransactionCreated,
  });

  @override
  State<QuickEntryHubSheet> createState() => _QuickEntryHubSheetState();
}

class _QuickEntryHubSheetState extends State<QuickEntryHubSheet> {
  List<JiveTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final isar = await DatabaseService.getInstance();
    final svc = TemplateService(isar);
    final all = await svc.getTemplates();
    all.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.usageCount.compareTo(a.usageCount);
    });
    final top5 = all.take(5).toList();
    if (mounted) setState(() { _templates = top5; _isLoading = false; });
  }

  Future<void> _executeTemplate(JiveTemplate template) async {
    final isar = await DatabaseService.getInstance();
    final svc = TemplateService(isar);
    final tx = svc.createTransactionFromTemplate(template);
    await isar.writeTxn(() async {
      await isar.jiveTransactions.put(tx);
    });
    await svc.incrementUsage(template);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已记账: ${template.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onTransactionCreated?.call();
    }
  }

  void _navigate(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      widget.onTransactionCreated?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildEntryGrid(),
              const SizedBox(height: 20),
              _buildTemplateSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryGrid() {
    final entries = <_EntryCardData>[
      _EntryCardData(
        emoji: '\u{1F4DD}',
        label: '手动记账',
        onTap: () => _navigate(
          AddTransactionScreen(
            initialType: TransactionType.expense,
            bookId: widget.bookId,
          ),
        ),
      ),
      _EntryCardData(
        emoji: '\u{1F3A4}',
        label: '语音记账',
        onTap: () => _navigate(
          AddTransactionScreen(
            initialType: TransactionType.expense,
            startWithSpeech: true,
            bookId: widget.bookId,
          ),
        ),
      ),
      _EntryCardData(
        emoji: '\u{1F4AC}',
        label: '对话记账',
        onTap: () => _navigate(
          ConversationalInputScreen(bookId: widget.bookId),
        ),
      ),
      _EntryCardData(
        emoji: '\u{1F4F8}',
        label: '截图识别',
        onTap: () => _navigate(const ScreenshotImportScreen()),
      ),
      _EntryCardData(
        emoji: '\u{1F4CB}',
        label: '从模板记',
        onTap: () => _navigate(const TemplateListScreen()),
      ),
      _EntryCardData(
        emoji: '\u{1F4E5}',
        label: '从分享记',
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请通过系统分享功能将内容分享到 Jive'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: entries.map((e) => _buildEntryCard(e)).toList(),
    );
  }

  Widget _buildEntryCard(_EntryCardData data) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: JiveTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    if (_isLoading || _templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '常用快速动作',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = _templates[i];
              final label = t.amount > 0
                  ? '${t.name}  \u00a5${t.amount.toStringAsFixed(0)}'
                  : t.name;
              return ActionChip(
                label: Text(label),
                onPressed: () => _executeTemplate(t),
                backgroundColor: JiveTheme.primaryGreen.withAlpha(20),
                side: BorderSide(color: JiveTheme.primaryGreen.withAlpha(60)),
                labelStyle: TextStyle(
                  color: JiveTheme.primaryGreen,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EntryCardData {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _EntryCardData({
    required this.emoji,
    required this.label,
    required this.onTap,
  });
}
