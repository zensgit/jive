import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/tag_service.dart';
import '../category/category_icon_source_picker.dart';
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
      final iconText = group.iconText?.trim() ?? '';
      _selectedIcon = (group.iconName == null || group.iconName!.trim().isEmpty) && iconText.isNotEmpty
          ? 'text:$iconText'
          : group.iconName;
    } else {
      _selectedColor = TagService.defaultColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入分组名称');
      return;
    }
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
        );
      } else {
        final group = widget.group!
          ..name = name
          ..colorHex = _selectedColor
          ..iconName = _selectedIcon
          ..iconText = null;
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
    final primary = Theme.of(context).colorScheme.primary;
    final cancelStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(36),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      foregroundColor: Colors.grey.shade700,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final actionStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(36),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSheetHandle(),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        maxLength: 12,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        decoration: InputDecoration(
                          labelText: '分组名称',
                          hintText: '最多12字',
                          errorText: _error,
                          counterText: '',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('颜色', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildColorGrid(),
                      const SizedBox(height: 12),
                      _buildIconPicker(),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8 + bottomInset),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: cancelStyle,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: actionStyle,
                        onPressed: _loading ? null : _save,
                        child: Text(widget.group == null ? '创建' : '保存'),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildIconPicker() {
    final iconColor = Colors.grey.shade700;
    final icon = iconWidgetForName(_selectedIcon, size: 18, color: iconColor);
    return Row(
      children: [
        const Text('图标', style: TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _loading ? null : _pickIcon,
          icon: icon,
          label: const Text('选择图标'),
        ),
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

  Future<void> _pickIcon() async {
    final selected = await pickCategoryIcon(
      context,
      initialIcon: _selectedIcon ?? 'category',
    );
    if (selected == null) return;
    setState(() {
      _selectedIcon = selected;
    });
  }
}
