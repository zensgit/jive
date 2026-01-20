import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/tag_service.dart';
import 'tag_edit_dialog.dart';
import 'tag_group_dialog.dart';
import 'tag_transactions_screen.dart';
import 'tag_icon_catalog.dart';

class TagManagementScreen extends StatefulWidget {
  final Isar? isar;

  const TagManagementScreen({super.key, this.isar});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  static const _accentColor = Color(0xFF2E7D32);
  static const _accentSoft = Color(0xFFE8F5E9);

  late Isar _isar;
  bool _isLoading = true;
  String? _error;
  bool _showArchived = false;
  List<JiveTag> _tags = [];
  List<JiveTagGroup> _groups = [];
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final existing = widget.isar ?? Isar.getInstance();
      if (existing != null) {
        _isar = existing;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        _isar = await Isar.open(
          [
            JiveTransactionSchema,
            JiveCategorySchema,
            JiveCategoryOverrideSchema,
            JiveAccountSchema,
            JiveAutoDraftSchema,
            JiveTagSchema,
            JiveTagGroupSchema,
          ],
          directory: dir.path,
        );
      }
      await TagService(_isar).initDefaultGroups();
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    final service = TagService(_isar);
    final tags = await service.getTags(includeArchived: true);
    final groups = await service.getGroups(includeArchived: true);
    if (!mounted) return;
    setState(() {
      _tags = tags;
      _groups = groups;
      _isLoading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTags = _filterTags(_tags, _query, _showArchived);
    final groupMap = {for (final group in _groups) group.key: group};
    final tagsByGroup = <String?, List<JiveTag>>{};
    for (final tag in filteredTags) {
      final key = groupMap.containsKey(tag.groupKey) ? tag.groupKey : null;
      tagsByGroup.putIfAbsent(key, () => []).add(tag);
    }
    for (final list in tagsByGroup.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }

    final showEmptyGroups = !_showArchived && _query.isEmpty;
    final groupCards = <Widget>[];
    final ungroupedTags = tagsByGroup[null] ?? [];
    if (ungroupedTags.isNotEmpty) {
      groupCards.add(_buildGroupCard(
        title: '未分组',
        tags: ungroupedTags,
        group: null,
      ));
    }
    for (final group in _groups) {
      final tags = tagsByGroup[group.key] ?? [];
      if (tags.isNotEmpty || (showEmptyGroups && !group.isArchived)) {
        groupCards.add(_buildGroupCard(
          title: group.name,
          tags: tags,
          group: group,
        ));
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('标签管理', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: _isLoading ? null : _buildBottomActions(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : Column(
                  children: [
                    _buildModeTabs(filteredTags.length),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '搜索标签',
                          prefixIcon: const Icon(Icons.search),
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
                    ),
                    if (!_showArchived) _buildInfoBanner(),
                    Expanded(
                      child: groupCards.isEmpty
                          ? _buildEmptyState()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: groupCards,
                            ),
                    ),
                  ],
                ),
    );
  }

  List<JiveTag> _filterTags(List<JiveTag> tags, String query, bool showArchived) {
    final queryLower = query.toLowerCase();
    final filtered = tags.where((tag) {
      if (showArchived) {
        if (!tag.isArchived) return false;
      } else {
        if (tag.isArchived) return false;
      }
      if (queryLower.isNotEmpty && !tagDisplayName(tag).toLowerCase().contains(queryLower)) {
        return false;
      }
      return true;
    }).toList();
    filtered.sort((a, b) => a.order.compareTo(b.order));
    return filtered;
  }

  Widget _buildModeTabs(int tagCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _buildModeTab(
            label: '启用',
            selected: !_showArchived,
            onTap: () => setState(() => _showArchived = false),
          ),
          const SizedBox(width: 12),
          _buildModeTab(
            label: '已归档',
            selected: _showArchived,
            onTap: () => setState(() => _showArchived = true),
          ),
          const Spacer(),
          Text('共 $tagCount 个标签', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? _accentColor : Colors.grey.shade600;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: color, width: selected ? 2 : 1),
          ),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _accentSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: _accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '标签用于多维度标记账单，请合理添加，避免过度复杂。',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final text = _showArchived ? '暂无归档标签' : '暂无标签';
    return Center(
      child: Text(text, style: TextStyle(color: Colors.grey.shade500)),
    );
  }

  Widget _buildGroupCard({
    required String title,
    required List<JiveTag> tags,
    required JiveTagGroup? group,
  }) {
    final groupColor = AccountService.parseColorHex(group?.colorHex) ?? Colors.grey.shade600;
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: group?.isArchived == true ? Colors.grey.shade500 : Colors.black87,
      fontSize: 13,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              groupIconWidget(group, size: 16, color: groupColor),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: headerStyle)),
              if (group != null) _buildGroupActions(group),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags) _buildTagChip(tag),
              if (!_showArchived) _buildAddTagChip(group?.key),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(JiveTag tag) {
    final baseColor = AccountService.parseColorHex(tag.colorHex) ?? Colors.blueGrey;
    final color = tag.isArchived ? Colors.grey.shade500 : baseColor;
    final textStyle = TextStyle(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 11,
      decoration: tag.isArchived ? TextDecoration.lineThrough : null,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTagTransactions(tag),
        onLongPress: () => _showTagActions(tag),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text(tagDisplayName(tag), style: textStyle),
        ),
      ),
    );
  }

  Widget _buildAddTagChip(String? groupKey) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _createTag(groupKey: groupKey),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: const Text(
            '+ 添加',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Future<void> _showTagActions(JiveTag tag) async {
    final action = await showModalBottomSheet<_TagAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('编辑标签'),
                onTap: () => Navigator.pop(context, _TagAction.edit),
              ),
              ListTile(
                title: Text(tag.isArchived ? '恢复标签' : '归档标签'),
                onTap: () => Navigator.pop(context, _TagAction.archive),
              ),
              ListTile(
                title: const Text('合并标签'),
                onTap: () => Navigator.pop(context, _TagAction.merge),
              ),
              ListTile(
                title: const Text('转换为分类'),
                onTap: () => Navigator.pop(context, _TagAction.convert),
              ),
              ListTile(
                title: const Text('删除标签', style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pop(context, _TagAction.delete),
              ),
            ],
          ),
        );
      },
    );
    if (action == null) return;
    if (action == _TagAction.edit) {
      await _editTag(tag);
    } else if (action == _TagAction.archive) {
      await TagService(_isar).setTagArchived(tag.key, !tag.isArchived);
      await _loadData();
    } else if (action == _TagAction.delete) {
      await _deleteTag(tag);
    } else if (action == _TagAction.merge) {
      await _mergeTag(tag);
    } else if (action == _TagAction.convert) {
      await _convertTag(tag);
    }
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _createTag(),
                icon: const Icon(Icons.add),
                label: const Text('添加标签'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createGroup,
                icon: const Icon(Icons.add),
                label: const Text('添加分组'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupActions(JiveTagGroup group) {
    return PopupMenuButton<_GroupAction>(
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) async {
        if (action == _GroupAction.edit) {
          await _editGroup(group);
        } else if (action == _GroupAction.archive) {
          await TagService(_isar).setGroupArchived(group.key, !group.isArchived);
          await _loadData();
        } else if (action == _GroupAction.delete) {
          await _deleteGroup(group);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _GroupAction.edit,
          child: Text('编辑分组'),
        ),
        PopupMenuItem(
          value: _GroupAction.archive,
          child: Text(group.isArchived ? '恢复分组' : '归档分组'),
        ),
        const PopupMenuItem(
          value: _GroupAction.delete,
          child: Text('删除分组'),
        ),
      ],
    );
  }

  Future<bool?> _openTagSheet({JiveTag? tag, String? groupKey}) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.66,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          builder: (context, controller) {
            return TagEditDialog(
              isar: _isar,
              tag: tag,
              initialGroupKey: groupKey,
              scrollController: controller,
            );
          },
        );
      },
    );
  }

  Future<bool?> _openGroupSheet({JiveTagGroup? group}) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.66,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          builder: (context, controller) {
            return TagGroupDialog(
              isar: _isar,
              group: group,
              scrollController: controller,
            );
          },
        );
      },
    );
  }


  Future<void> _createTag({String? groupKey}) async {
    final result = await _openTagSheet(groupKey: groupKey);
    if (result == true) await _loadData();
  }

  Future<void> _editTag(JiveTag tag) async {
    final result = await _openTagSheet(tag: tag);
    if (result == true) await _loadData();
  }

  Future<void> _createGroup() async {
    final result = await _openGroupSheet();
    if (result == true) await _loadData();
  }

  Future<void> _editGroup(JiveTagGroup group) async {
    final result = await _openGroupSheet(group: group);
    if (result == true) await _loadData();
  }

  Future<void> _deleteGroup(JiveTagGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定删除分组 "${group.name}" 吗？分组内标签将移出分组。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    await TagService(_isar).deleteGroup(group.key);
    await _loadData();
  }

  Future<void> _deleteTag(JiveTag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确定删除标签 "${tag.name}" 吗？已使用 ${tag.usageCount} 次。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    await TagService(_isar).deleteTag(tag.key);
    await _loadData();
  }

  Future<void> _mergeTag(JiveTag source) async {
    final candidates = _tags.where((tag) => tag.key != source.key && !tag.isArchived).toList();
    if (candidates.isEmpty) {
      _showMessage('没有可合并的标签');
      return;
    }
    final target = await showModalBottomSheet<JiveTag>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final tag = candidates[index];
              final color = AccountService.parseColorHex(tag.colorHex) ?? Colors.blueGrey;
              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: color.withOpacity(0.2),
                ),
                title: Text(tagDisplayName(tag)),
                onTap: () => Navigator.pop(context, tag),
              );
            },
          ),
        );
      },
    );
    if (target == null) return;
    await TagService(_isar).mergeTags(targetKey: target.key, sourceKeys: [source.key]);
    await _loadData();
    _showMessage('已合并 "${source.name}" -> "${target.name}"');
  }

  Future<void> _convertTag(JiveTag tag) async {
    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final parentsExpense = categories.where((c) => c.parentKey == null && !c.isIncome).toList();
    final parentsIncome = categories.where((c) => c.parentKey == null && c.isIncome).toList();
    TagMigratePolicy policy = TagMigratePolicy.onlyNull;
    bool isIncome = false;
    bool keepTagActive = true;
    bool asSub = false;
    String? parentKey;
    final renameController = TextEditingController(text: tag.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final parents = isIncome ? parentsIncome : parentsExpense;
            return AlertDialog(
              title: const Text('转换为分类'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: renameController,
                      decoration: const InputDecoration(labelText: '分类名称'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<bool>(
                      value: isIncome,
                      decoration: const InputDecoration(labelText: '分类类型'),
                      items: const [
                        DropdownMenuItem(value: false, child: Text('支出')),
                        DropdownMenuItem(value: true, child: Text('收入')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          isIncome = value;
                          parentKey = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: asSub,
                      title: const Text('创建为子分类'),
                      onChanged: (value) {
                        setDialogState(() {
                          asSub = value;
                          if (!asSub) parentKey = null;
                        });
                      },
                    ),
                    if (asSub)
                      DropdownButtonFormField<String?>(
                        value: parentKey,
                        decoration: const InputDecoration(labelText: '父分类'),
                        items: [
                          for (final parent in parents)
                            DropdownMenuItem(value: parent.key, child: Text(parent.name)),
                        ],
                        onChanged: (value) => setDialogState(() => parentKey = value),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TagMigratePolicy>(
                      value: policy,
                      decoration: const InputDecoration(labelText: '迁移交易'),
                      items: const [
                        DropdownMenuItem(value: TagMigratePolicy.onlyNull, child: Text('仅补全空分类')),
                        DropdownMenuItem(value: TagMigratePolicy.overwrite, child: Text('覆盖现有分类')),
                        DropdownMenuItem(value: TagMigratePolicy.none, child: Text('不迁移')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => policy = value);
                      },
                    ),
                    SwitchListTile(
                      value: keepTagActive,
                      title: const Text('保留标签'),
                      onChanged: (value) => setDialogState(() => keepTagActive = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('转换')),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;
    if (asSub && parentKey == null) {
      _showMessage('请选择父分类');
      return;
    }
    final result = await TagService(_isar).convertTagToCategory(
      tagKey: tag.key,
      isIncome: isIncome,
      parentKey: asSub ? parentKey : null,
      migratePolicy: policy,
      keepTagActive: keepTagActive,
      renameTo: renameController.text.trim(),
    );
    if (result != null) {
      await _loadData();
      _showMessage('已转换为分类 "${result.name}"');
    } else {
      _showMessage('转换失败');
    }
  }

  void _openTagTransactions(JiveTag tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TagTransactionsScreen(
          tagKey: tag.key,
          title: tagDisplayName(tag),
          isar: _isar,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _TagAction { edit, archive, delete, merge, convert }

enum _GroupAction { edit, archive, delete }
