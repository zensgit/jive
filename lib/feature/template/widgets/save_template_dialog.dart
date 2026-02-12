import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/transaction_model.dart';
import '../../../core/design_system/theme.dart';

class SaveTemplateDialog extends StatefulWidget {
  final JiveTransaction transaction;
  final String? categoryName;

  const SaveTemplateDialog({
    super.key,
    required this.transaction,
    this.categoryName,
  });

  @override
  State<SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<SaveTemplateDialog> {
  late TextEditingController _nameController;
  late TextEditingController _groupController;
  bool _saveAmount = true;

  @override
  void initState() {
    super.initState();
    final defaultName = widget.categoryName ?? '新模板';
    _nameController = TextEditingController(text: defaultName);
    _groupController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bookmark_add, color: JiveTheme.primaryGreen),
          const SizedBox(width: 8),
          const Text('保存为模板'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '模板名称',
                border: OutlineInputBorder(),
                hintText: '如：午餐、房租',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _saveAmount,
              onChanged: (value) => setState(() => _saveAmount = value ?? true),
              title: Text(
                '保存金额 ¥${widget.transaction.amount.toStringAsFixed(2)}',
                style: GoogleFonts.lato(fontSize: 14),
              ),
              subtitle: Text(
                _saveAmount ? '使用模板时自动填入金额' : '使用模板时需手动输入金额',
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _groupController,
              decoration: const InputDecoration(
                labelText: '分组（可选）',
                border: OutlineInputBorder(),
                hintText: '如：日常、月度',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: JiveTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入模板名称')),
      );
      return;
    }

    Navigator.pop(context, _TemplateFormResult(
      name: name,
      saveAmount: _saveAmount,
      groupName: _groupController.text.trim().isEmpty
          ? null
          : _groupController.text.trim(),
    ));
  }
}

class _TemplateFormResult {
  final String name;
  final bool saveAmount;
  final String? groupName;

  _TemplateFormResult({
    required this.name,
    required this.saveAmount,
    this.groupName,
  });
}

/// 显示保存模板底部弹窗的便捷方法
Future<Map<String, dynamic>?> showSaveTemplateDialog({
  required BuildContext context,
  required JiveTransaction transaction,
  String? categoryName,
}) async {
  final result = await showModalBottomSheet<_TemplateFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SaveTemplateBottomSheet(
      transaction: transaction,
      categoryName: categoryName,
    ),
  );

  if (result == null) return null;

  return {
    'name': result.name,
    'saveAmount': result.saveAmount,
    'groupName': result.groupName,
  };
}

class _SaveTemplateBottomSheet extends StatefulWidget {
  final JiveTransaction transaction;
  final String? categoryName;

  const _SaveTemplateBottomSheet({
    required this.transaction,
    this.categoryName,
  });

  @override
  State<_SaveTemplateBottomSheet> createState() => _SaveTemplateBottomSheetState();
}

class _SaveTemplateBottomSheetState extends State<_SaveTemplateBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _groupController;
  bool _saveAmount = true;

  @override
  void initState() {
    super.initState();
    final defaultName = widget.categoryName ?? '新模板';
    _nameController = TextEditingController(text: defaultName);
    _groupController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动指示条
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 标题
            Row(
              children: [
                const Icon(Icons.bookmark_add, color: JiveTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  '保存为模板',
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 模板名称
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '模板名称',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: '如：午餐、房租',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            // 保存金额选项
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _saveAmount,
                    onChanged: (v) => setState(() => _saveAmount = v ?? true),
                    activeColor: JiveTheme.primaryGreen,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '保存金额 ¥${widget.transaction.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _saveAmount ? '使用模板时自动填入金额' : '使用模板时需手动输入金额',
                          style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 分组
            TextField(
              controller: _groupController,
              decoration: InputDecoration(
                labelText: '分组（可选）',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: '如：日常、月度',
              ),
            ),
            const SizedBox(height: 24),
            // 按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JiveTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('保存模板'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入模板名称')),
      );
      return;
    }

    Navigator.pop(context, _TemplateFormResult(
      name: name,
      saveAmount: _saveAmount,
      groupName: _groupController.text.trim().isEmpty
          ? null
          : _groupController.text.trim(),
    ));
  }
}
