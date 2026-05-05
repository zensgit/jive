import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/model/quick_action.dart';
import '../../../core/service/database_service.dart';
import '../../../core/service/quick_action_service.dart';
import '../../quick_entry/quick_action_executor.dart';
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
  List<QuickAction> _actions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isar = await DatabaseService.getInstance();
    final top5 = await QuickActionService(isar).getActions(limit: 5);
    if (mounted) {
      setState(() {
        _actions = top5;
        _isLoading = false;
      });
    }
  }

  Future<void> _executeAction(QuickAction action) async {
    await QuickActionExecutor.execute(
      context,
      action,
      onCompleted: () {
        widget.onTransactionCreated?.call();
        _load();
      },
    );
  }

  void _editActions() {
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
    if (_isLoading || _actions.isEmpty) return const SizedBox.shrink();

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
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _actions.length + 1, // +1 for "更多"
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == _actions.length) {
                return ActionChip(
                  label: const Text('更多'),
                  onPressed: _goToFullList,
                  backgroundColor: Colors.grey.shade200,
                  side: BorderSide.none,
                );
              }
              final action = _actions[i];
              final amount = action.defaultAmount ?? 0;
              final label = amount > 0
                  ? '${action.name}  \u00a5${amount.toStringAsFixed(0)}'
                  : action.name;
              return GestureDetector(
                onLongPress: _editActions,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ActionChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label),
                          Text(
                            '使用 ${action.usageCount} 次',
                            style: TextStyle(
                              fontSize: 10,
                              color: JiveTheme.primaryGreen.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () => _executeAction(action),
                      backgroundColor: JiveTheme.primaryGreen.withAlpha(20),
                      side: BorderSide(
                        color: JiveTheme.primaryGreen.withAlpha(60),
                      ),
                      labelStyle: TextStyle(
                        color: JiveTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                    if (action.usageCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: JiveTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${action.usageCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
