import 'package:flutter/material.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';

class SystemCategorySuggestion {
  final String name;
  final String iconName;
  final String? parentName;
  final bool isParent;

  const SystemCategorySuggestion({
    required this.name,
    required this.iconName,
    this.parentName,
    this.isParent = false,
  });
}

class CategoryCreateResult {
  final List<String> names;
  final String iconName;
  final String? colorHex;
  final bool iconForceTinted;
  final bool autoMatchIcon;
  final List<SystemCategorySuggestion> systemSelections;
  final bool hasChanges;

  const CategoryCreateResult({
    required this.names,
    required this.iconName,
    this.colorHex,
    this.iconForceTinted = false,
    this.autoMatchIcon = false,
    this.systemSelections = const [],
    this.hasChanges = false,
  });
}

class CategoryCreateDialog extends StatefulWidget {
  final String parentName;
  final String initialIcon;
  final String? title;
  final String? nameLabel;
  final bool allowBatch;
  final String? initialText;
  final bool initialBatch;

  const CategoryCreateDialog({
    super.key,
    required this.parentName,
    required this.initialIcon,
    this.title,
    this.nameLabel,
    this.allowBatch = false,
    this.initialText,
    this.initialBatch = false,
  });

  @override
  State<CategoryCreateDialog> createState() => _CategoryCreateDialogState();
}

class _CategoryCreateDialogState extends State<CategoryCreateDialog> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  String? _selectedColorHex;
  bool _isBatch = false;
  bool _autoMatchIcon = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialText ?? "");
    _selectedIcon = widget.initialIcon;
    _isBatch = widget.allowBatch && widget.initialBatch;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = _resolveSelectedColor() ?? JiveTheme.primaryGreen;
    return AlertDialog(
      title: Text(widget.title ?? "添加子类 · ${widget.parentName}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _showIconPicker,
              child: CircleAvatar(
                radius: 32,
                backgroundColor: highlightColor.withValues(alpha: 0.1),
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
            if (widget.allowBatch)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isBatch,
                onChanged: (value) => setState(() => _isBatch = value),
                title: const Text("批量添加"),
              ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: widget.nameLabel ?? "子类名称",
                border: const OutlineInputBorder(),
              ),
              keyboardType: _isBatch ? TextInputType.multiline : TextInputType.text,
              textInputAction: _isBatch ? TextInputAction.newline : TextInputAction.done,
              maxLines: _isBatch ? 4 : 1,
              onSubmitted: _isBatch ? null : (_) => _save(),
            ),
            if (_isBatch) ...[
              const SizedBox(height: 6),
              const Text(
                "每行/逗号/分号分隔，支持粘贴，重复名称会自动忽略",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _autoMatchIcon,
              onChanged: (value) => setState(() => _autoMatchIcon = value),
              title: const Text("自动匹配图标"),
              subtitle: const Text("根据名称自动选择更合适的图标"),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: JiveTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: const Text("添加"),
        ),
      ],
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => GridView.count(
        crossAxisCount: 6,
        padding: const EdgeInsets.all(16),
        children: [
          'restaurant',
          'shopping_bag',
          'directions_car',
          'house',
          'sports_esports',
          'local_hospital',
          'school',
          'people',
          'pets',
          'trending_up',
          'attach_money',
          'bakery_dining',
          'local_cafe',
          'icecream',
          'movie',
          'flight',
          'key',
          'local_dining',
          'local_taxi',
          'local_parking',
          'local_gas_station',
          'local_convenience_store',
          'phone_iphone',
          'card_giftcard',
        ].map((name) {
          return IconButton(
            icon: CategoryService.buildIcon(name, size: 22),
            onPressed: () {
              setState(() => _selectedIcon = name);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _save() {
    final names = _parseNames();
    if (names.isEmpty) return;
    Navigator.pop(
      context,
      CategoryCreateResult(
        names: names,
        iconName: _selectedIcon,
        colorHex: _selectedColorHex,
        autoMatchIcon: _autoMatchIcon,
      ),
    );
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
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return "#${value.substring(2).toUpperCase()}";
  }

  List<String> _parseNames() {
    final raw = _nameController.text.trim();
    if (raw.isEmpty) return [];
    if (!_isBatch) return [raw];

    final parts = raw.split(RegExp(r'[\n,，;；]+'));
    final seen = <String>{};
    final names = <String>[];
    for (final part in parts) {
      final name = part.trim();
      if (name.isEmpty) continue;
      if (seen.add(name)) {
        names.add(name);
      }
    }
    return names;
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
