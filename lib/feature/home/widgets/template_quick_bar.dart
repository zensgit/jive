import 'package:flutter/material.dart';

import '../../../core/database/template_model.dart';
import '../../../core/database/transaction_model.dart';
import '../../../core/design_system/theme.dart';
import '../../../core/service/database_service.dart';
import '../../../core/service/template_service.dart';
import '../../template/template_list_screen.dart';

/// Horizontal quick-bar showing the top 5 most-used templates.
///
/// Tap a chip to instantly create a transaction; long-press to edit.
class TemplateQuickBar extends StatefulWidget {
  final VoidCallback? onTransactionCreated;

  const TemplateQuickBar({super.key, this.onTransactionCreated});

  @override
  State<TemplateQuickBar> createState() => _TemplateQuickBarState();
}

class _TemplateQuickBarState extends State<TemplateQuickBar> {
  List<JiveTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isar = await DatabaseService.getInstance();
    final svc = TemplateService(isar);
    final all = await svc.getTemplates();
    // Top 5 by usage
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已记账: ${template.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onTransactionCreated?.call();
      _load(); // refresh order
    }
  }

  void _editTemplate(JiveTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TemplateListScreen()),
    ).then((_) => _load());
  }

  void _goToFullList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TemplateListScreen()),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, size: 18, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              '快捷模板',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length + 1, // +1 for "更多"
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == _templates.length) {
                return ActionChip(
                  label: const Text('更多'),
                  onPressed: _goToFullList,
                  backgroundColor: Colors.grey.shade200,
                  side: BorderSide.none,
                );
              }
              final t = _templates[i];
              final label = t.amount > 0
                  ? '${t.name}  \u00a5${t.amount.toStringAsFixed(0)}'
                  : t.name;
              return GestureDetector(
                onLongPress: () => _editTemplate(t),
                child: ActionChip(
                  label: Text(label),
                  onPressed: () => _executeTemplate(t),
                  backgroundColor: JiveTheme.primaryGreen.withAlpha(20),
                  side: BorderSide(color: JiveTheme.primaryGreen.withAlpha(60)),
                  labelStyle: TextStyle(
                    color: JiveTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
