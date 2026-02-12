import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/tag_service.dart';
import '../category/category_icon_source_picker.dart';
import 'tag_icon_catalog.dart';
import 'tag_color_picker_sheet.dart';

class TagEditDialog extends StatefulWidget {
  final Isar isar;
  final JiveTag? tag;
  final String? initialGroupKey;
  final ScrollController? scrollController;

  const TagEditDialog({
    super.key,
    required this.isar,
    this.tag,
    this.initialGroupKey,
    this.scrollController,
  });

  @override
  State<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<TagEditDialog> {
  static const int _maxTagNameLength = 9;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupSearchController = TextEditingController();
  List<JiveTagGroup> _groups = [];
  String? _selectedGroupKey;
  String? _selectedColor;
  String? _selectedIcon;
  String _groupQuery = '';
  String? _groupError;
  bool _ungroupedSelected = false;
  bool _followGroupColor = false;
  bool _loading = true;
  String? _error;
  bool _iconDirty = false;

  @override
  void initState() {
    super.initState();
    final tag = widget.tag;
    if (tag != null) {
      _nameController.text = tag.name;
      _selectedGroupKey = tag.groupKey;
      _selectedColor = tag.colorHex ?? TagService.defaultColors.first;
      final iconText = tag.iconText?.trim() ?? '';
      _selectedIcon = (tag.iconName == null || tag.iconName!.trim().isEmpty) && iconText.isNotEmpty
          ? 'text:$iconText'
          : tag.iconName;
      if (tag.groupKey == null) {
        _ungroupedSelected = true;
      }
    } else {
      _selectedColor = TagService.defaultColors.first;
      if (widget.initialGroupKey != null) {
        _selectedGroupKey = widget.initialGroupKey;
      }
    }
    _loadGroups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final groups = await TagService(widget.isar).getGroups(includeArchived: false);
    if (!mounted) return;
    String? selectedName;
    if (_selectedGroupKey != null && _groupQuery.isEmpty) {
      for (final group in groups) {
        if (group.key == _selectedGroupKey) {
          selectedName = group.name;
          break;
        }
      }
    }
    setState(() {
      _groups = groups;
      _loading = false;
      final name = selectedName;
      if (name != null) {
        _groupSearchController.text = name;
        _groupSearchController.selection = TextSelection.collapsed(offset: name.length);
        _groupQuery = name;
        _ungroupedSelected = false;
      }
    });
  }

  Future<void> _createGroupFromQuery() async {
    final name = _groupQuery.trim();
    if (name.isEmpty) return;
    if (name.length > 12) {
      setState(() {
        _groupError = '分组名称最多12字';
      });
      return;
    }
    setState(() {
      _groupError = null;
      _loading = true;
    });
    try {
      final created = await TagService(widget.isar).createGroup(name: name);
      final groups = await TagService(widget.isar).getGroups(includeArchived: false);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _selectedGroupKey = created.key;
        _groupQuery = created.name;
        _groupSearchController.text = created.name;
        _groupSearchController.selection =
            TextSelection.collapsed(offset: created.name.length);
        _ungroupedSelected = false;
        _loading = false;
      });
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() {
        _groupError = e.message?.toString() ?? '创建分组失败';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _groupError = '创建分组失败';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入标签名称');
      return;
    }
    if (name.length > _maxTagNameLength) {
      setState(() => _error = '最多9字');
      return;
    }
    var colorHex = _selectedColor;
    if (_followGroupColor) {
      final groupColor = _resolveSelectedGroupColor();
      if (groupColor == null) {
        setState(() {
          _groupError = '请先选择分组';
        });
        return;
      }
      colorHex = groupColor;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final service = TagService(widget.isar);
      if (widget.tag == null) {
        await service.createTag(
          name: name,
          colorHex: colorHex,
          iconName: _selectedIcon,
          groupKey: _selectedGroupKey,
        );
      } else {
        final tag = widget.tag!
          ..name = name
          ..colorHex = colorHex
          ..groupKey = _selectedGroupKey;
        if (_iconDirty) {
          tag.iconName = _selectedIcon;
          tag.iconText = null;
        }
        await service.updateTag(tag);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ArgumentError catch (e) {
      if (!mounted) return;
      final message = e.message?.toString() ?? '保存失败';
      if (message.contains('最多9字')) {
        setState(() {
          _error = '最多9字';
          _loading = false;
        });
        return;
      }
      setState(() {
        _error = message;
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
    final filteredGroups = _groupQuery.isEmpty
        ? _groups
        : _groups
            .where((group) => groupDisplayName(group).toLowerCase().contains(_groupQuery.toLowerCase()))
            .toList();
    final canCreateGroup = _groupQuery.trim().isNotEmpty &&
        !_groups.any((group) => group.name.toLowerCase() == _groupQuery.toLowerCase());
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
                            widget.tag == null ? '创建标签' : '编辑标签',
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
                          labelText: '标签名称',
                          hintText: '最多9字',
                          errorText: _error,
                          suffixText: _nameController.text.trim().length > _maxTagNameLength
                              ? '超过9字'
                              : null,
                          suffixStyle: TextStyle(color: Colors.red.shade400, fontSize: 12),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          if (!mounted) return;
                          setState(() => _error = null);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildIconPicker(),
                      const SizedBox(height: 12),
                      _buildColorHeader(),
                      const SizedBox(height: 8),
                      if (_followGroupColor) ...[
                        _buildFollowColorPreview(),
                      ] else ...[
                        _buildColorGrid(),
                      ],
                      const SizedBox(height: 16),
                      _buildGroupSection(
                        filteredGroups: filteredGroups,
                        canCreateGroup: canCreateGroup,
                      ),
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
                        child: Text(widget.tag == null ? '创建' : '保存'),
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

  Widget _buildIconPicker() {
    final iconColor = Colors.grey.shade700;
    return Row(
      children: [
        const Text('图标', style: TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _loading ? null : _pickIcon,
          icon: iconWidgetForName(_selectedIcon, size: 18, color: iconColor),
          label: const Text('选择图标'),
        ),
      ],
    );
  }

  Widget _buildColorHeader() {
    return Row(
      children: [
        const Text('颜色', style: TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text('跟随目录颜色', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        Switch(
          value: _followGroupColor,
          onChanged: _toggleFollowGroupColor,
        ),
      ],
    );
  }

  Widget _buildFollowColorPreview() {
    final group = _findGroupByKey(_selectedGroupKey);
    if (group == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('请选择分组后自动跟随颜色', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      );
    }
    final colorHex = group.colorHex ?? TagService.defaultColors.first;
    final color = _colorFromHex(colorHex);
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '跟随 ${groupDisplayName(group)}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ),
      ],
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
          color: selected && customHex != null ? _colorFromHex(customHex) : null,
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

  Widget _buildGroupSection({
    required List<JiveTagGroup> filteredGroups,
    required bool canCreateGroup,
  }) {
    final showOnlyUngrouped = _ungroupedSelected;
    final chipCount = filteredGroups.length + 1;
    final shouldClamp = chipCount > 12;
    final maxHeight = MediaQuery.of(context).size.height * 0.18;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('标签分组', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: _groupSearchController,
          maxLength: 12,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: InputDecoration(
            labelText: '搜索或新建分组',
            hintText: '最多12字（新建）',
            counterText: '',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: _groupQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _groupSearchController.clear();
                      setState(() {
                        _groupQuery = '';
                        _selectedGroupKey = null;
                        _ungroupedSelected = false;
                      });
                    },
                  ),
          ),
          onChanged: (value) => setState(() {
            _groupQuery = value.trim();
            _groupError = null;
            _selectedGroupKey = null;
            _ungroupedSelected = false;
          }),
        ),
        if (_groupError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_groupError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        if (canCreateGroup)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _createGroupFromQuery,
              icon: const Icon(Icons.add),
              label: Text('创建分组 "${_groupQuery.trim()}"'),
            ),
          ),
        if (showOnlyUngrouped)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('未分组', style: TextStyle(fontSize: 10)),
                  selected: _ungroupedSelected,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  onSelected: (selected) => _toggleUngrouped(selected),
                ),
              ],
            ),
          )
        else if (filteredGroups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('暂无分组', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: shouldClamp
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: SingleChildScrollView(
                      primary: false,
                      physics: const ClampingScrollPhysics(),
                      child: _buildGroupChips(filteredGroups),
                    ),
                  )
                : _buildGroupChips(filteredGroups),
          ),
      ],
    );
  }

  Widget _buildGroupChips(List<JiveTagGroup> filteredGroups) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: const Text('未分组', style: TextStyle(fontSize: 10)),
          selected: _ungroupedSelected,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          onSelected: (selected) => _toggleUngrouped(selected),
        ),
        for (final group in filteredGroups)
          ChoiceChip(
            label: Text(groupDisplayName(group), style: const TextStyle(fontSize: 10)),
            selected: _selectedGroupKey == group.key,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            onSelected: (_) => _selectGroup(group.key),
          ),
      ],
    );
  }

  void _toggleFollowGroupColor(bool value) {
    setState(() {
      _followGroupColor = value;
      if (value) {
        final groupColor = _resolveSelectedGroupColor();
        if (groupColor != null) {
          _selectedColor = groupColor;
        }
      }
    });
  }

  void _selectColor(String colorHex) {
    setState(() {
      _selectedColor = colorHex;
      _followGroupColor = false;
    });
  }

  Future<void> _pickIcon() async {
    final selected = await pickCategoryIcon(
      context,
      initialIcon: _selectedIcon ?? 'category',
    );
    if (selected == null) return;
    setState(() {
      _selectedIcon = selected;
      _iconDirty = true;
    });
  }

  void _selectGroup(String? key) {
    setState(() {
      _selectedGroupKey = key;
      _groupError = null;
      _ungroupedSelected = false;
      if (key == null) {
        _groupQuery = '';
        _groupSearchController.clear();
        _followGroupColor = false;
      } else {
        final group = _findGroupByKey(key);
        if (group != null) {
          _groupSearchController.text = group.name;
          _groupSearchController.selection =
              TextSelection.collapsed(offset: group.name.length);
          _groupQuery = group.name;
        }
        if (_followGroupColor) {
          final groupColor = _resolveSelectedGroupColor();
          if (groupColor != null) {
            _selectedColor = groupColor;
          }
        }
      }
    });
  }

  void _toggleUngrouped(bool selected) {
    setState(() {
      _ungroupedSelected = selected;
      _groupError = null;
      if (selected) {
        _selectedGroupKey = null;
        _groupQuery = '';
        _groupSearchController.clear();
        _followGroupColor = false;
      }
    });
  }

  JiveTagGroup? _findGroupByKey(String? key) {
    if (key == null) return null;
    for (final group in _groups) {
      if (group.key == key) return group;
    }
    return null;
  }

  String? _resolveSelectedGroupColor() {
    final group = _findGroupByKey(_selectedGroupKey);
    if (group == null) return null;
    return group.colorHex ?? TagService.defaultColors.first;
  }
}
