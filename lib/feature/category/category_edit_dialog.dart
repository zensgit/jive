import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../core/database/category_model.dart';
import '../../core/service/category_service.dart';
import '../../core/design_system/theme.dart';

class CategoryEditDialog extends StatefulWidget {
  final JiveCategory category;
  final Isar isar;

  const CategoryEditDialog({super.key, required this.category, required this.isar});

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  String? _selectedColorHex;
  String? _selectedParentKey;
  List<JiveCategory> _parents = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIcon = widget.category.iconName;
    _selectedColorHex = widget.category.colorHex;
    _selectedParentKey = widget.category.parentKey;
    _loadParents();
  }

  Future<void> _loadParents() async {
    final parents = await CategoryService(widget.isar).getAllParents();
    // 排除自己 (不能认自己做爸爸)
    parents.removeWhere((p) => p.id == widget.category.id);
    if (mounted) setState(() => _parents = parents);
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = _resolveSelectedColor() ?? JiveTheme.primaryGreen;
    return AlertDialog(
      title: const Text("编辑分类"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 图标 (点击切换 - 简版)
            GestureDetector(
              onTap: _showIconPicker,
              child: CircleAvatar(
                radius: 32,
                backgroundColor: highlightColor.withOpacity(0.1),
                child: CategoryService.buildIcon(
                  _selectedIcon,
                  size: 32,
                  color: highlightColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text("点击修改图标", style: TextStyle(fontSize: 10, color: Colors.grey)),

            const SizedBox(height: 12),
            _buildColorPicker(),
            const SizedBox(height: 16),

            // 2. 名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "分类名称",
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),

            // 3. 所属父级
            DropdownButtonFormField<String?>(
              value: _selectedParentKey,
              decoration: const InputDecoration(
                labelText: "所属父级 (层级)",
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("无 (作为一级分类)")),
                ..._parents.map((p) => DropdownMenuItem(
                  value: p.key,
                  child: Row(
                    children: [
                      CategoryService.buildIcon(
                        p.iconName,
                        size: 16,
                        color: CategoryService.parseColorHex(p.colorHex) ?? Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(p.name),
                    ],
                  ),
                )),
              ],
              onChanged: (val) {
                setState(() => _selectedParentKey = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("取消"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: JiveTheme.primaryGreen, foregroundColor: Colors.white),
          onPressed: _save,
          child: const Text("保存"),
        ),
      ],
    );
  }

  void _showIconPicker() {
    // 简易图标选择器
    showModalBottomSheet(
      context: context,
      builder: (context) => GridView.count(
        crossAxisCount: 6,
        padding: const EdgeInsets.all(16),
        children: [
          'restaurant', 'shopping_bag', 'directions_car', 'house', 'sports_esports', 
          'local_hospital', 'school', 'people', 'pets', 'trending_up', 'attach_money',
          'bakery_dining', 'local_cafe', 'icecream', 'movie', 'flight', 'key'
        ].map((name) => IconButton(
          icon: CategoryService.buildIcon(name, size: 22),
          onPressed: () {
            setState(() => _selectedIcon = name);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    await CategoryService(widget.isar).updateCategory(
      widget.category.id, 
      newName, 
      _selectedIcon, 
      _selectedParentKey,
      _selectedColorHex,
    );

    if (mounted) Navigator.pop(context, true);
  }

  Widget _buildColorPicker() {
    return Row(
      children: [
        const Text("颜色", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorDot(null),
              ..._categoryColorOptions.map(_buildColorDot),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorDot(Color? color) {
    final hex = color == null ? null : _colorHexFromColor(color);
    final isSelected = _selectedColorHex == hex;
    final borderColor = isSelected ? (color ?? Colors.grey.shade600) : Colors.grey.shade300;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedColorHex = hex),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: color == null
            ? Icon(Icons.close, size: 12, color: Colors.grey.shade500)
            : (isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
      ),
    );
  }

  Color? _resolveSelectedColor() {
    return CategoryService.parseColorHex(_selectedColorHex);
  }

  String _colorHexFromColor(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
    return "#${value.substring(2).toUpperCase()}";
  }
}

const List<Color> _categoryColorOptions = [
  Color(0xFFF44336),
  Color(0xFFFF9800),
  Color(0xFFFFC107),
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFF795548),
  Color(0xFF607D8B),
];
