import 'package:flutter/material.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/category_icon_style.dart';
import '../budget/budget_settings_screen.dart';
import '../export/csv_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickCategoryIconStyle(
    BuildContext context, {
    required CategoryIconStyle current,
  }) async {
    final picked = await showModalBottomSheet<CategoryIconStyle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "分类图标风格",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "关闭",
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...CategoryIconStyle.values.map((style) {
                  final isSelected = current == style;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: JiveTheme.primaryGreen,
                    ),
                    title: Text(style.label),
                    onTap: () => Navigator.pop(sheetContext, style),
                  );
                }),
              ],
            ),
          ),
        );
      },
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
                      onTap: () =>
                          _pickCategoryIconStyle(context, current: style),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("预算", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text("预算设置"),
                  subtitle: const Text("预算提醒与展示偏好"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("数据", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text("导出数据"),
                  subtitle: const Text("按日期、分类和类型导出 CSV"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CsvExportScreen(),
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
