import 'package:flutter/material.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/account_service.dart';
import 'tag_icon_catalog.dart';

class TagPickerSheet extends StatefulWidget {
  final List<JiveTag> tags;
  final List<String> selectedKeys;
  final Future<JiveTag> Function(String name)? onCreateTag;
  final String title;

  const TagPickerSheet({
    super.key,
    required this.tags,
    required this.selectedKeys,
    this.onCreateTag,
    this.title = '选择标签',
  });

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _selectedKeys;
  String _query = '';
  static const int _maxTagNameLength = 9;

  @override
  void initState() {
    super.initState();
    _selectedKeys = List<String>.from(widget.selectedKeys);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterTags(widget.tags, _query);
    final canCreate = _canCreateTag(_query, widget.tags);
    final tooLong = _query.trim().length > _maxTagNameLength;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selectedKeys),
                  child: const Text('完成'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索或新建标签（最多9字）',
                prefixIcon: const Icon(Icons.search),
                suffixText: tooLong ? '超过9字' : null,
                suffixStyle: TextStyle(color: Colors.red.shade400, fontSize: 12),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            if (canCreate && widget.onCreateTag != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final created = await widget.onCreateTag!(_query.trim());
                    if (!mounted) return;
                    setState(() {
                      _selectedKeys.add(created.key);
                      widget.tags.add(created);
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text('创建标签 "${_query.trim()}"'),
                ),
              ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无标签', style: TextStyle(color: Colors.grey.shade500)),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filtered.map(_buildChip).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<JiveTag> _filterTags(List<JiveTag> tags, String query) {
    if (query.isEmpty) return tags;
    final lower = query.toLowerCase();
    return tags.where((tag) => tag.name.toLowerCase().contains(lower)).toList();
  }

  bool _canCreateTag(String query, List<JiveTag> tags) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > _maxTagNameLength) return false;
    return !tags.any((tag) => tag.name.toLowerCase() == trimmed.toLowerCase());
  }

  Widget _buildChip(JiveTag tag) {
    final selected = _selectedKeys.contains(tag.key);
    final color = AccountService.parseColorHex(tag.colorHex) ?? Colors.blueGrey;
    final label = tagDisplayName(tag);
    final showIcon = hasTagIcon(tag);
    final labelStyle = TextStyle(
      color: color,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );
    return FilterChip(
      selected: selected,
      label: showIcon
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tagIconWidget(tag, size: 12, color: color),
                const SizedBox(width: 4),
                Text(label, style: labelStyle),
              ],
            )
          : Text(label, style: labelStyle),
      backgroundColor: color.withValues(alpha: 0.08),
      selectedColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color.withValues(alpha: selected ? 0.6 : 0.3)),
      checkmarkColor: color,
      showCheckmark: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedKeys.add(tag.key);
          } else {
            _selectedKeys.remove(tag.key);
          }
        });
      },
    );
  }
}
