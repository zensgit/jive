import 'package:flutter/material.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/category_icon_style.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickCategoryIconStyle(
    BuildContext context, {
    required CategoryIconStyle current,
  }) async {
    var selected = current;
    final picked = await showDialog<CategoryIconStyle>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            title: const Text("分类图标风格"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: CategoryIconStyle.values.map((style) {
                final isSelected = selected == style;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: JiveTheme.primaryGreen,
                  ),
                  title: Text(style.label),
                  onTap: () => setStateDialog(() => selected = style),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("取消"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, selected),
                child: const Text("确定"),
              ),
            ],
          );
        },
      ),
    );
    if (picked == null || picked == current) return;
    await CategoryIconStyleStore.save(picked);
    CategoryIconStyleConfig.current = picked;
  }

  Widget _sectionCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("设置", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("外观", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ValueListenableBuilder<CategoryIconStyle>(
                  valueListenable: CategoryIconStyleConfig.notifier,
                  builder: (context, style, _) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text("分类图标风格"),
                      subtitle: Text(style.label),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onTap: () => _pickCategoryIconStyle(
                        context,
                        current: style,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

