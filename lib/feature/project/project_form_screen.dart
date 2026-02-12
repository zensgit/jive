import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/project_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/project_service.dart';
import '../../core/service/tag_service.dart';
import '../../core/design_system/theme.dart';
import '../category/category_icon_source_picker.dart';
import '../tag/tag_icon_catalog.dart';
import '../tag/tag_color_picker_sheet.dart';

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
  String? _selectedIcon;
  String _selectedColor = '#2E7D32';
  Isar? _isar;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(text: widget.project?.description ?? '');
    _budgetController = TextEditingController(
        text: widget.project?.budget != null && widget.project!.budget > 0
            ? widget.project!.budget.toString()
            : '');
    _selectedIcon = widget.project?.iconName;
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
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Color _colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return JiveTheme.primaryGreen;
    if (cleaned.length == 6) {
      return Color(0xFF000000 | value);
    }
    return Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;
    final currentColor = _colorFromHex(_selectedColor);

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
            _buildIconPicker(currentColor),
            const SizedBox(height: 24),
            _buildColorPicker(currentColor),
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

  Widget _buildIconPicker(Color currentColor) {
    return Row(
      children: [
        Text('图标', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _pickIcon,
          icon: iconWidgetForName(_selectedIcon, size: 20, color: currentColor),
          label: const Text('选择图标'),
        ),
      ],
    );
  }

  Widget _buildColorPicker(Color currentColor) {
    final colors = TagService.defaultColors;
    final isCustomSelected = !colors.contains(_selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('颜色', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: _openCustomColorPicker,
              icon: const Icon(Icons.palette, size: 18),
              label: const Text('更多颜色'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (final colorHex in colors) _buildColorDot(colorHex),
            _buildCustomColorDot(isCustomSelected, customHex: _selectedColor),
          ],
        ),
      ],
    );
  }

  Widget _buildColorDot(String colorHex) {
    final isSelected = _selectedColor == colorHex;
    final color = _colorFromHex(colorHex);
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = colorHex),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.black87, width: 2) : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _buildCustomColorDot(bool selected, {String? customHex}) {
    final showCustom = selected && customHex != null;
    return GestureDetector(
      onTap: _openCustomColorPicker,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: showCustom ? _colorFromHex(customHex) : null,
          gradient: showCustom
              ? null
              : const LinearGradient(
                  colors: [
                    Color(0xFFF44336),
                    Color(0xFFFFC107),
                    Color(0xFF4CAF50),
                    Color(0xFF2196F3),
                  ],
                ),
          border: selected ? Border.all(color: Colors.black87, width: 2) : null,
        ),
        child: showCustom
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : const Icon(Icons.palette, color: Colors.white, size: 16),
      ),
    );
  }

  Future<void> _pickIcon() async {
    final selected = await pickCategoryIcon(
      context,
      initialIcon: _selectedIcon ?? 'folder',
    );
    if (selected == null) return;
    setState(() => _selectedIcon = selected);
  }

  Future<void> _openCustomColorPicker() async {
    final result = await TagColorPickerSheet.show(
      context,
      initialColorHex: _selectedColor,
      swatchHexes: TagService.defaultColors,
    );
    if (result == null) return;
    setState(() => _selectedColor = result);
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
