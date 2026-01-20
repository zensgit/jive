import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/tag_service.dart';
import 'tag_icon_catalog.dart';
import 'tag_color_picker_sheet.dart';

class TagGroupDialog extends StatefulWidget {
  final Isar isar;
  final JiveTagGroup? group;
  final ScrollController? scrollController;

  const TagGroupDialog({
    super.key,
    required this.isar,
    this.group,
    this.scrollController,
  });

  @override
  State<TagGroupDialog> createState() => _TagGroupDialogState();
}

class _TagGroupDialogState extends State<TagGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconTextController = TextEditingController();
  String? _selectedColor;
  String? _selectedIcon;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    if (group != null) {
      _nameController.text = group.name;
      _selectedColor = group.colorHex;
      _selectedIcon = group.iconName;
      _iconTextController.text = group.iconText ?? '';
    } else {
      _selectedColor = TagService.defaultColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconTextController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入分组名称');
      return;
    }
    final iconText = _iconTextController.text.trim();
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final service = TagService(widget.isar);
      if (widget.group == null) {
        await service.createGroup(
          name: name,
          colorHex: _selectedColor,
          iconName: _selectedIcon,
          iconText: iconText.isEmpty ? null : iconText,
        );
      } else {
        final group = widget.group!
          ..name = name
          ..colorHex = _selectedColor
          ..iconName = _selectedIcon
          ..iconText = iconText.isEmpty ? null : iconText;
        await service.updateGroup(group);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message?.toString() ?? '保存失败';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '保存失败';
        _loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          children: [
            _buildSheetHandle(),
            if (_loading) ...[
              const SizedBox(height: 80),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 80),
            ] else ...[
              Row(
                children: [
                  Text(
                    widget.group == null ? '创建分组' : '编辑分组',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '分组名称',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _iconTextController,
                decoration: const InputDecoration(
                  labelText: '分组图标(Emoji)',
                  hintText: '例如 ✈️',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('颜色', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _buildColorGrid(),
              const SizedBox(height: 12),
              const Text('图标', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildIconChoice(null, Icons.cancel_outlined),
                  ...tagIconMap.entries.map((entry) => _buildIconChoice(entry.key, entry.value)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: Text(widget.group == null ? '创建' : '保存'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    final colors = TagService.defaultColors;
    final isCustomSelected = _selectedColor != null && !colors.contains(_selectedColor);
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (final color in colors) _buildColorDot(color),
        _buildCustomColorDot(isCustomSelected, customHex: _selectedColor),
      ],
    );
  }

  Widget _buildColorDot(String colorHex) {
    final isSelected = _selectedColor == colorHex;
    final color = _colorFromHex(colorHex);
    return GestureDetector(
      onTap: () => _selectColor(colorHex),
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
          color: showCustom ? _colorFromHex(customHex!) : null,
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

  Future<void> _openCustomColorPicker() async {
    final initial = _selectedColor ?? TagService.defaultColors.first;
    final result = await TagColorPickerSheet.show(
      context,
      initialColorHex: initial,
      swatchHexes: TagService.defaultColors,
    );
    if (result == null) return;
    _selectColor(result);
  }

  Color _colorFromHex(String hex) {
    final value = int.parse(hex.replaceFirst('#', '0xff'));
    return Color(value);
  }

  void _selectColor(String colorHex) {
    setState(() => _selectedColor = colorHex);
  }

  Widget _buildIconChoice(String? key, IconData icon) {
    final selected = _selectedIcon == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedIcon = key),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: Colors.black87, width: 2) : null,
        ),
        child: Icon(icon, size: 20, color: selected ? Colors.black87 : Colors.black45),
      ),
    );
  }
}
