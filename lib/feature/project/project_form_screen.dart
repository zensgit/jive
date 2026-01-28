import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/project_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/template_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/project_service.dart';
import '../../core/design_system/theme.dart';

class ProjectFormScreen extends StatefulWidget {
  final JiveProject? project;

  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _budgetController;
  String _selectedIcon = 'folder';
  String _selectedColor = '#2E7D32';
  Isar? _isar;

  final _icons = [
    {'name': 'folder', 'icon': Icons.folder, 'label': '默认'},
    {'name': 'travel', 'icon': Icons.flight, 'label': '旅行'},
    {'name': 'home', 'icon': Icons.home, 'label': '住房'},
    {'name': 'car', 'icon': Icons.directions_car, 'label': '汽车'},
    {'name': 'wedding', 'icon': Icons.favorite, 'label': '婚礼'},
    {'name': 'education', 'icon': Icons.school, 'label': '教育'},
  ];

  final _colors = ['#2E7D32', '#1976D2', '#E53935', '#FF9800', '#9C27B0', '#00BCD4'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(text: widget.project?.description ?? '');
    _budgetController = TextEditingController(
        text: widget.project?.budget != null && widget.project!.budget > 0
            ? widget.project!.budget.toString()
            : '');
    _selectedIcon = widget.project?.iconName ?? 'folder';
    _selectedColor = widget.project?.colorHex ?? '#2E7D32';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
      return _isar!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      JiveTransactionSchema, JiveCategorySchema, JiveCategoryOverrideSchema,
      JiveAccountSchema, JiveAutoDraftSchema, JiveTemplateSchema,
      JiveTagSchema, JiveProjectSchema,
    ], directory: dir.path);
    return _isar!;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑项目' : '新建项目'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: JiveTheme.surfaceWhite,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '项目名称',
                border: OutlineInputBorder(),
                hintText: '如：日本旅行、新房装修',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入项目名称' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: '预算（可选）',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
                hintText: '留空表示不限预算',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            Text('图标', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _icons.map((item) {
                final isSelected = _selectedIcon == item['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = item['name'] as String),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? JiveTheme.primaryGreen.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: JiveTheme.primaryGreen, width: 2) : null,
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: isSelected ? JiveTheme.primaryGreen : Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(item['label'] as String, style: GoogleFonts.lato(fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('颜色', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colors.map((hex) {
                final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final isSelected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: JiveTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEditing ? '保存' : '创建项目', style: GoogleFonts.lato(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isar = await _ensureIsar();
    final service = ProjectService(isar);
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0;

    if (widget.project != null) {
      widget.project!
        ..name = _nameController.text.trim()
        ..description = _descController.text.trim().isEmpty ? null : _descController.text.trim()
        ..budget = budget
        ..iconName = _selectedIcon
        ..colorHex = _selectedColor;
      await service.updateProject(widget.project!);
    } else {
      await service.createProject(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        budget: budget,
        iconName: _selectedIcon,
        colorHex: _selectedColor,
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
