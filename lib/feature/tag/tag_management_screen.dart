import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_conversion_log.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/tag_service.dart';
import 'tag_edit_dialog.dart';
import 'tag_group_dialog.dart';
import 'tag_transactions_screen.dart';
import 'tag_conversion_log_screen.dart';
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
            JiveTagConversionLogSchema,
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
    await service.refreshUsageCounts();
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
          title: groupDisplayName(group),
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
        actions: [
          IconButton(
            tooltip: '转换记录',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TagConversionLogScreen(isar: _isar),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      bottomNavigationBar: _isLoading ? null : _buildBottomActions(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : Column(
                  children: [
                    _buildModeTabs(filteredTags.length),
                    if (!_showArchived) _buildInfoBanner(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
    final countStyle = TextStyle(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 10,
    );
    final showIcon = hasTagIcon(tag);
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                tagIconWidget(tag, size: 12, color: color),
                const SizedBox(width: 4),
              ],
              Text(tagDisplayName(tag), style: textStyle),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${tag.usageCount}', style: countStyle),
              ),
            ],
          ),
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
    final groupCount = (await TagService(_isar).getGroups(includeArchived: false)).length;
    final initialSize = _tagSheetInitialSize(groupCount);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialSize,
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
          initialChildSize: 0.5,
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

  double _tagSheetInitialSize(int groupCount) {
    final chipCount = groupCount + 1;
    final rows = ((chipCount + 3) ~/ 4).clamp(1, 8);
    final size = 0.62 + rows * 0.03;
    if (size < 0.64) return 0.64;
    if (size > 0.86) return 0.86;
    return size;
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
    final tagTxs = await _isar.jiveTransactions
        .filter()
        .tagKeysElementEqualTo(tag.key)
        .findAll();
    final request = await _showConvertTagSheet(
      tag: tag,
      parentsExpense: parentsExpense,
      parentsIncome: parentsIncome,
      allCategories: categories,
      tagTransactions: tagTxs,
    );
    if (request == null) return;
    final result = await TagService(_isar).convertTagToCategory(
      tagKey: tag.key,
      isIncome: request.isIncome,
      parentKey: request.asSub ? request.parentKey : null,
      migratePolicy: request.policy,
      keepTagActive: request.keepTagActive,
      renameTo: request.name,
      existingCategoryKey: request.existingCategoryKey,
    );
    if (result != null) {
      await _loadData();
      final log = await _isar
          .collection<JiveTagConversionLog>()
          .filter()
          .tagKeyEqualTo(tag.key)
          .sortByCreatedAtDesc()
          .findFirst();
      if (log == null) {
        _showMessage('已转换为分类 "${result.name}"');
      } else {
        _showMessage('已转换为分类 "${result.name}"，更新 ${log.updatedTransactionCount}/${log.taggedTransactionCount} 笔交易');
      }
    } else {
      _showMessage('转换失败');
    }
  }

  Future<_TagConvertRequest?> _showConvertTagSheet({
    required JiveTag tag,
    required List<JiveCategory> parentsExpense,
    required List<JiveCategory> parentsIncome,
    required List<JiveCategory> allCategories,
    required List<JiveTransaction> tagTransactions,
  }) async {
    TagMigratePolicy policy = TagMigratePolicy.onlyNull;
    bool isIncome = false;
    bool keepTagActive = true;
    bool asSub = false;
    String? parentKey;
    bool useExistingCategory = true;
    final categoryNameByKey = {for (final item in allCategories) item.key: item.name};
    final renameController = TextEditingController(text: tag.name);
    final result = await showModalBottomSheet<_TagConvertRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.58,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final parents = isIncome ? parentsIncome : parentsExpense;
                final resolvedParentKey = asSub ? parentKey : null;
                final existing = _findExistingCategory(
                  categories: allCategories,
                  name: renameController.text.trim(),
                  isIncome: isIncome,
                  parentKey: resolvedParentKey,
                );
                final hasExisting = existing != null;
                final parentName = hasExisting && existing!.parentKey != null
                    ? categoryNameByKey[existing.parentKey!]
                    : null;
                final estimate = _estimateConversion(
                  transactions: tagTransactions,
                  categories: allCategories,
                  isIncome: isIncome,
                  policy: policy,
                );
                if (!hasExisting && useExistingCategory) {
                  useExistingCategory = false;
                }
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Center(
                            child: Text(
                              '转换为分类',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '该标签已关联 ${tag.usageCount} 笔交易',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: renameController,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        labelText: '分类名称',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (hasExisting) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '已存在分类：${existing!.name}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (parentName != null && parentName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '父级：$parentName',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('使用已有分类'),
                                  selected: useExistingCategory,
                                  onSelected: (selected) => setSheetState(() {
                                    useExistingCategory = true;
                                  }),
                                ),
                                ChoiceChip(
                                  label: const Text('改名新建'),
                                  selected: !useExistingCategory,
                                  onSelected: (selected) => setSheetState(() {
                                    useExistingCategory = false;
                                  }),
                                ),
                              ],
                            ),
                            if (!useExistingCategory)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '改名后将创建新分类',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('分类类型', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('支出'),
                          selected: !isIncome,
                          onSelected: (selected) {
                            if (!selected) return;
                            setSheetState(() {
                              isIncome = false;
                              parentKey = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('收入'),
                          selected: isIncome,
                          onSelected: (selected) {
                            if (!selected) return;
                            setSheetState(() {
                              isIncome = true;
                              parentKey = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: asSub,
                      title: const Text('创建为子分类'),
                      onChanged: (value) {
                        setSheetState(() {
                          asSub = value;
                          if (!asSub) parentKey = null;
                        });
                      },
                    ),
                    if (asSub)
                      DropdownButtonFormField<String?>(
                        value: parentKey,
                        decoration: const InputDecoration(
                          labelText: '父分类',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final parent in parents)
                            DropdownMenuItem(value: parent.key, child: Text(parent.name)),
                        ],
                        onChanged: (value) => setSheetState(() => parentKey = value),
                      ),
                    const SizedBox(height: 12),
                    Text('交易处理方式', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    _buildEstimateBanner(estimate),
                    const SizedBox(height: 8),
                    RadioListTile<TagMigratePolicy>(
                      value: TagMigratePolicy.onlyNull,
                      groupValue: policy,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('仅补全空分类'),
                      subtitle: const Text('不会修改已设置分类的交易'),
                      onChanged: (value) => setSheetState(() => policy = value!),
                    ),
                    RadioListTile<TagMigratePolicy>(
                      value: TagMigratePolicy.overwrite,
                      groupValue: policy,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('覆盖同类型分类'),
                      subtitle: const Text('仅在分类类型一致时覆盖已有分类'),
                      onChanged: (value) => setSheetState(() => policy = value!),
                    ),
                    RadioListTile<TagMigratePolicy>(
                      value: TagMigratePolicy.none,
                      groupValue: policy,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('不迁移'),
                      subtitle: const Text('仅创建分类，不改交易'),
                      onChanged: (value) => setSheetState(() => policy = value!),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: keepTagActive,
                      title: const Text('保留标签'),
                      onChanged: (value) => setSheetState(() => keepTagActive = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = renameController.text.trim();
                          if (name.isEmpty) {
                            _showMessage('请输入分类名称');
                            return;
                          }
                          if (hasExisting && !useExistingCategory) {
                            if (name == existing.name) {
                              _showMessage('已存在同名分类，请修改名称或选择使用已有分类');
                              return;
                            }
                          }
                          if (asSub && parentKey == null) {
                            _showMessage('请选择父分类');
                            return;
                          }
                              Navigator.pop(
                                context,
                                _TagConvertRequest(
                                  name: name,
                                  isIncome: isIncome,
                                  asSub: asSub,
                                  parentKey: parentKey,
                                  policy: policy,
                                  keepTagActive: keepTagActive,
                                  useExistingCategory: useExistingCategory,
                                  existingCategoryKey:
                                      useExistingCategory ? existing?.key : null,
                                ),
                              );
                            },
                            child: const Text('转换'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
    renameController.dispose();
    return result;
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

  Widget _buildEstimateBanner(_TagConversionEstimate estimate) {
    final textColor = Colors.grey.shade700;
    if (estimate.totalCount == 0) {
      return Text('暂无关联交易', style: TextStyle(color: textColor, fontSize: 12));
    }
    final base = '预计更新 ${estimate.updatedCount}/${estimate.totalCount} 笔交易';
    final skipParts = <String>[];
    if (estimate.skippedByPolicyCount > 0) {
      skipParts.add('不迁移 ${estimate.skippedByPolicyCount}');
    }
    if (estimate.skippedExistingCount > 0) {
      skipParts.add('已有分类 ${estimate.skippedExistingCount}');
    }
    if (estimate.skippedTypeMismatchCount > 0) {
      skipParts.add('类型不一致 ${estimate.skippedTypeMismatchCount}');
    }
    if (estimate.skippedUnknownCategoryCount > 0) {
      skipParts.add('分类缺失 ${estimate.skippedUnknownCategoryCount}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(base, style: TextStyle(color: textColor, fontSize: 12)),
        if (skipParts.isNotEmpty)
          Text(
            '跳过：${skipParts.join(' / ')}',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
      ],
    );
  }

  _TagConversionEstimate _estimateConversion({
    required List<JiveTransaction> transactions,
    required List<JiveCategory> categories,
    required bool isIncome,
    required TagMigratePolicy policy,
  }) {
    final total = transactions.length;
    var updated = 0;
    var skippedExisting = 0;
    var skippedMismatch = 0;
    var skippedUnknown = 0;
    var skippedByPolicy = 0;
    if (policy == TagMigratePolicy.none) {
      skippedByPolicy = total;
      return _TagConversionEstimate(
        totalCount: total,
        updatedCount: updated,
        skippedExistingCount: skippedExisting,
        skippedTypeMismatchCount: skippedMismatch,
        skippedUnknownCategoryCount: skippedUnknown,
        skippedByPolicyCount: skippedByPolicy,
      );
    }
    final categoryTypeByKey = <String, bool>{
      for (final item in categories) item.key: item.isIncome,
    };
    for (final tx in transactions) {
      final categoryEmpty = tx.categoryKey == null || tx.categoryKey!.isEmpty;
      if (policy == TagMigratePolicy.onlyNull) {
        if (!categoryEmpty) {
          skippedExisting += 1;
          continue;
        }
      } else if (policy == TagMigratePolicy.overwrite) {
        if (!categoryEmpty) {
          final type = categoryTypeByKey[tx.categoryKey!];
          if (type == null) {
            skippedUnknown += 1;
            continue;
          }
          if (type != isIncome) {
            skippedMismatch += 1;
            continue;
          }
        }
      }
      updated += 1;
    }
    return _TagConversionEstimate(
      totalCount: total,
      updatedCount: updated,
      skippedExistingCount: skippedExisting,
      skippedTypeMismatchCount: skippedMismatch,
      skippedUnknownCategoryCount: skippedUnknown,
      skippedByPolicyCount: skippedByPolicy,
    );
  }

  JiveCategory? _findExistingCategory({
    required List<JiveCategory> categories,
    required String name,
    required bool isIncome,
    String? parentKey,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    for (final item in categories) {
      if (item.isIncome != isIncome) continue;
      if ((item.parentKey ?? '') != (parentKey ?? '')) continue;
      if (item.name == trimmed) return item;
    }
    return null;
  }
}

enum _TagAction { edit, archive, delete, merge, convert }

class _TagConvertRequest {
  const _TagConvertRequest({
    required this.name,
    required this.isIncome,
    required this.asSub,
    required this.parentKey,
    required this.policy,
    required this.keepTagActive,
    required this.useExistingCategory,
    required this.existingCategoryKey,
  });

  final String name;
  final bool isIncome;
  final bool asSub;
  final String? parentKey;
  final TagMigratePolicy policy;
  final bool keepTagActive;
  final bool useExistingCategory;
  final String? existingCategoryKey;
}

class _TagConversionEstimate {
  const _TagConversionEstimate({
    required this.totalCount,
    required this.updatedCount,
    required this.skippedExistingCount,
    required this.skippedTypeMismatchCount,
    required this.skippedUnknownCategoryCount,
    required this.skippedByPolicyCount,
  });

  final int totalCount;
  final int updatedCount;
  final int skippedExistingCount;
  final int skippedTypeMismatchCount;
  final int skippedUnknownCategoryCount;
  final int skippedByPolicyCount;
}

enum _GroupAction { edit, archive, delete }
