import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';
import 'category_icon_library.dart';
import 'category_icon_picker_screen.dart';
import 'category_icon_source_picker.dart';
import 'category_create_dialog.dart';

class CategoryCreateScreen extends StatefulWidget {
  final String title;
  final String? parentName;
  final String initialIcon;
  final String? nameLabel;
  final String? typeName;
  final String? typeLabel;
  final bool parentOnly;
  final bool allowBatch;
  final String? initialText;
  final bool initialBatch;
  final Map<String, Map<String, dynamic>>? systemLibrary;
  final Set<String> existingNames;
  final String? initialGroupName;
  final bool autoBatchAdd;
  final Future<bool> Function(SystemCategorySuggestion suggestion, String? colorHex)? onBatchAdd;

  const CategoryCreateScreen({
    super.key,
    required this.title,
    required this.initialIcon,
    this.parentName,
    this.nameLabel,
    this.typeName,
    this.typeLabel,
    this.parentOnly = false,
    this.allowBatch = false,
    this.initialText,
    this.initialBatch = false,
    this.systemLibrary,
    this.existingNames = const {},
    this.initialGroupName,
    this.autoBatchAdd = false,
    this.onBatchAdd,
  });

  @override
  State<CategoryCreateScreen> createState() => _CategoryCreateScreenState();
}

class _CategoryCreateScreenState extends State<CategoryCreateScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _iconSearchController = TextEditingController();
  final TextEditingController _systemSearchController = TextEditingController();
  late final VoidCallback _systemSearchListener;
  late String _selectedIcon;
  String? _lastAutoFilledName;
  String? _selectedColorHex;
  String _iconQuery = "";
  String _systemQuery = "";
  bool _isBatch = false;
  bool _autoMatchIcon = false;
  final Map<String, String> _iconSearchCache = {};
  final Map<String, String> _systemSearchCache = {};
  final Set<String> _selectedSystemNames = {};
  final Set<String> _existingNames = {};
  bool _hasAutoChanges = false;
  late final Map<String, String> _iconLabelByName;
  late final List<_SystemGroup> _systemGroups;
  late final Map<String, SystemCategorySuggestion> _systemItemByName;
  String _selectedGroupName = "";
  int _systemGridColumns = 4;
  final ScrollController _systemGroupController = ScrollController();
  final ScrollController _systemGridController = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialText ?? "");
    _nameController.addListener(_handleNameChange);
    _selectedIcon = widget.initialIcon;
    _isBatch = widget.allowBatch && widget.initialBatch;
    _existingNames.addAll(widget.existingNames);
    _iconLabelByName = _buildIconLabelMap();
    _initSystemGroups();
    _systemSearchListener = () {
      final value = _systemSearchController.text;
      if (value == _systemQuery) return;
      setState(() => _systemQuery = value);
    };
    _systemSearchController.addListener(_systemSearchListener);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChange);
    _nameController.dispose();
    _iconSearchController.dispose();
    _systemSearchController.removeListener(_systemSearchListener);
    _systemSearchController.dispose();
    _systemGroupController.dispose();
    _systemGridController.dispose();
    super.dispose();
  }

  void _initSystemGroups() {
    final library = widget.systemLibrary;
    if (library == null || library.isEmpty) {
      _systemGroups = const [];
      _systemItemByName = const {};
      return;
    }

    if (_isParentCreateMode()) {
      final groups = <_SystemGroup>[];
      final itemByName = <String, SystemCategorySuggestion>{};
      final allChildren = <String, SystemCategorySuggestion>{};

      for (final entry in library.entries) {
        final groupName = _canonicalGroupName(entry.key);
        final icon = _normalizeSystemIcon(entry.value['icon'] as String?, groupName);
        final parentSuggestion = SystemCategorySuggestion(
          name: groupName,
          iconName: icon,
          isParent: true,
        );
        itemByName[groupName] = parentSuggestion;
        final childrenRaw = entry.value['children'] as List<dynamic>? ?? const [];
        final seenChildren = <String>{};
        final children = <SystemCategorySuggestion>[];
        for (final child in childrenRaw) {
          final name = (child['name'] as String? ?? "").trim();
          if (name.isEmpty || !seenChildren.add(name)) continue;
          final childIcon = _normalizeSystemIcon(child['icon'] as String?, name);
          final suggestion = SystemCategorySuggestion(
            name: name,
            iconName: childIcon,
            parentName: groupName,
            isParent: false,
          );
          children.add(suggestion);
          allChildren.putIfAbsent(name, () => suggestion);
        }

        children.sort((a, b) => CategoryService.compareCategoryName(a.name, b.name));
        groups.add(
          _SystemGroup(
            name: groupName,
            iconName: icon,
            children: children,
          ),
        );
      }

      groups.sort((a, b) => CategoryService.compareCategoryName(a.name, b.name));
      final sortedGroups = <_SystemGroup>[];
      if (allChildren.isNotEmpty) {
        final allList = allChildren.values.toList();
        allList.sort((a, b) => CategoryService.compareCategoryName(a.name, b.name));
        sortedGroups.add(_SystemGroup(name: "全部", iconName: "category", children: allList));
      }
      sortedGroups.addAll(groups);
      _systemGroups = sortedGroups;
      _systemItemByName = itemByName;
      _selectedGroupName = _resolveInitialGroup();
      return;
    }

    final groupChildren = <String, List<SystemCategorySuggestion>>{};
    final groupChildNames = <String, Set<String>>{};
    final groupIcons = <String, String>{};
    final itemByName = <String, SystemCategorySuggestion>{};
    final allSuggestions = <String, SystemCategorySuggestion>{};
    final globalChildNames = <String>{};
    void upsertSuggestion(Map<String, SystemCategorySuggestion> map, SystemCategorySuggestion suggestion) {
      final name = suggestion.name.trim();
      if (name.isEmpty) return;
      final existing = map[name];
      if (existing == null) {
        map[name] = suggestion;
        return;
      }
      final isParent = existing.isParent || suggestion.isParent;
      final iconName = (existing.iconName == "category" && suggestion.iconName != "category")
          ? suggestion.iconName
          : existing.iconName;
      final parentName = isParent ? null : (existing.parentName ?? suggestion.parentName);
      map[name] = SystemCategorySuggestion(
        name: name,
        iconName: iconName,
        parentName: parentName,
        isParent: isParent,
      );
    }

    for (final entry in library.entries) {
      final childrenRaw = entry.value['children'] as List<dynamic>? ?? const [];
      for (final child in childrenRaw) {
        final name = (child['name'] as String? ?? "").trim();
        if (name.isNotEmpty) {
          globalChildNames.add(_canonicalGroupName(name));
        }
      }
    }

    for (final entry in library.entries) {
      final rawGroupName = entry.key;
      final groupName = _canonicalGroupName(rawGroupName);
      final icon = _normalizeSystemIcon(entry.value['icon'] as String?, groupName);
      final parentSuggestion = SystemCategorySuggestion(
        name: groupName,
        iconName: icon,
        isParent: true,
      );
      upsertSuggestion(allSuggestions, parentSuggestion);

      final childrenRaw = entry.value['children'] as List<dynamic>? ?? const [];
      final children = groupChildren.putIfAbsent(groupName, () => <SystemCategorySuggestion>[]);
      final seenNames = groupChildNames.putIfAbsent(groupName, () => <String>{});

      final existingIcon = groupIcons[groupName];
      if (existingIcon == null || (existingIcon == "category" && icon != "category")) {
        groupIcons[groupName] = icon;
      }

      for (final child in childrenRaw) {
        final name = (child['name'] as String? ?? "").trim();
        if (name.isEmpty) continue;
        if (!seenNames.add(name)) continue;
        final childIcon = _normalizeSystemIcon(child['icon'] as String?, name);
        final suggestion = SystemCategorySuggestion(
          name: name,
          iconName: childIcon,
          parentName: groupName,
        );
        children.add(suggestion);
        upsertSuggestion(allSuggestions, suggestion);
      }
    }

    final groups = <_SystemGroup>[];
    for (final entry in groupChildren.entries) {
      final groupName = entry.key;
      final children = entry.value;
      if (children.isEmpty) {
        if (globalChildNames.contains(groupName)) {
          continue;
        }
        continue;
      }
      children.sort((a, b) => CategoryService.compareCategoryName(a.name, b.name));
      groups.add(
        _SystemGroup(
          name: groupName,
          iconName: groupIcons[groupName] ?? "category",
          children: children,
        ),
      );
    }

    final sortedGroups = <_SystemGroup>[];
    if (allSuggestions.isNotEmpty) {
      final allList = allSuggestions.values.toList();
      allList.sort((a, b) => CategoryService.compareCategoryName(a.name, b.name));
      sortedGroups.add(_SystemGroup(name: "全部", iconName: "category", children: allList));
    }

    groups.sort((a, b) => CategoryService.compareCategoryName(a.name, b.name));
    sortedGroups.addAll(groups);

    itemByName.addAll(allSuggestions);
    _systemGroups = sortedGroups;
    _systemItemByName = itemByName;
    _selectedGroupName = _resolveInitialGroup();
  }

  Future<void> _pickCustomIcon() async {
    final selected = await pickCategoryIcon(context, initialIcon: _selectedIcon);
    if (selected != null) {
      _applyIconSelection(selected);
    }
  }

  Future<void> _pickEmojiIcon() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryIconPickerScreen(
          initialIcon: _selectedIcon,
          initialMode: CategoryIconPickerMode.emoji,
        ),
        fullscreenDialog: true,
      ),
    );
    if (selected != null) {
      _applyIconSelection(selected);
    }
  }

  String _resolveInitialGroup() {
    if (_systemGroups.isEmpty) return "";
    final initial = widget.initialGroupName?.trim();
    if (initial == "全部") {
      final hasAll = _systemGroups.any((group) => group.name == "全部");
      if (hasAll) return "全部";
    }
    final groups = _systemGroups.where((group) => group.name != "全部").toList();
    if (initial != null && initial.isNotEmpty) {
      final tokens = _expandGroupTokens(initial);
      for (final token in tokens) {
        final canonical = _canonicalGroupName(token);
        final match = groups.firstWhere(
          (group) => group.name == canonical && group.children.isNotEmpty,
          orElse: () => const _SystemGroup(name: "", iconName: "", children: []),
        );
        if (match.name.isNotEmpty) return match.name;
      }
      for (final token in tokens) {
        final canonical = _canonicalGroupName(token);
        final childMatch = groups.firstWhere(
          (group) =>
              group.children.any((child) => child.name == token || child.name == canonical),
          orElse: () => const _SystemGroup(name: "", iconName: "", children: []),
        );
        if (childMatch.name.isNotEmpty) return childMatch.name;
      }
      for (final token in tokens) {
        final canonical = _canonicalGroupName(token);
        final fuzzyMatch = groups.firstWhere(
          (group) =>
              group.name.contains(token) ||
              token.contains(group.name) ||
              group.name.contains(canonical) ||
              canonical.contains(group.name),
          orElse: () => const _SystemGroup(name: "", iconName: "", children: []),
        );
        if (fuzzyMatch.name.isNotEmpty) return fuzzyMatch.name;
      }
    }
    return groups.isNotEmpty ? groups.first.name : _systemGroups.first.name;
  }

  String _normalizeSystemIcon(String? icon, String name) {
    final value = icon?.trim() ?? "";
    if (value.isEmpty) return "category";
    return value;
  }

	@override
	Widget build(BuildContext context) {
	  final canSave = _parseNames().isNotEmpty || _selectedSystemNames.isNotEmpty;
	  final hasSystemLibrary = _systemGroups.isNotEmpty;
	  final showBottomBar = _isBatch && !widget.autoBatchAdd && _selectedSystemNames.isNotEmpty;
	  return PopScope<Object?>(
	    canPop: false,
	    onPopInvokedWithResult: (didPop, result) {
	      if (didPop) return;
	      _exitWithChanges();
	    },
	    child: Scaffold(
	      backgroundColor: Colors.white,
	      appBar: AppBar(
	        title: Text(widget.title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          leading: BackButton(
            color: Colors.black87,
            onPressed: _exitWithChanges,
          ),
          actions: [
            TextButton(
              onPressed: canSave ? _save : null,
              child: Text(
                "保存",
                style: TextStyle(
                  color: canSave ? JiveTheme.primaryGreen : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, showBottomBar ? 16 : 12),
          children: [
            if (widget.allowBatch)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isBatch,
                onChanged: (value) {
                  setState(() {
                    _isBatch = value;
                    if (!_isBatch) _selectedSystemNames.clear();
                  });
                },
                title: const Text("批量添加"),
              ),
            _buildInfoCard(),
            const SizedBox(height: 6),
            if (hasSystemLibrary) _buildSystemCategorySection(),
            if (!hasSystemLibrary) _buildIconSection(),
          ],
        ),
        bottomNavigationBar: showBottomBar ? _buildBatchActionBar() : null,
      ),
    );
  }

  Widget _buildInfoCard() {
    final highlightColor = _resolveSelectedColor() ?? JiveTheme.primaryGreen;
    final showSystemBatch = _isBatch && _systemGroups.isNotEmpty;
    final duplicateHint = showSystemBatch ? null : _duplicateNameHint();
    final isParentCreate = _isParentCreateMode();
    if (isParentCreate) {
      final typeName = _effectiveTypeName();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("分类信息", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
              ],
            ),
            if (typeName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    widget.typeLabel ?? "收支类型",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Text(
                    typeName,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                ],
              ),
              const Divider(height: 20),
            ] else
              const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showSystemBatch) ...[
                  GestureDetector(
                    onTap: () => _scrollToIcons(),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: highlightColor.withValues(alpha: 0.1),
                      child: CategoryService.buildIcon(
                        _selectedIcon,
                        size: 22,
                        color: highlightColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: widget.nameLabel ?? "一级分类名称",
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: _isBatch ? TextInputType.multiline : TextInputType.text,
                      textInputAction: _isBatch ? TextInputAction.newline : TextInputAction.done,
                      maxLines: _isBatch ? 4 : 1,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _isBatch ? null : (_) => _save(),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "已选择 ${_selectedSystemNames.length} 个系统分类",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _selectedSystemNames.isEmpty
                                ? null
                                : () => setState(() => _selectedSystemNames.clear()),
                            child: const Text("清空"),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (_isBatch && !showSystemBatch) ...[
              const SizedBox(height: 6),
              const Text(
                "每行/逗号/分号分隔，支持粘贴，多余空格会自动忽略",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
            if (duplicateHint != null) ...[
              const SizedBox(height: 6),
              Text(
                duplicateHint,
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ],
            const SizedBox(height: 6),
            _buildColorPicker(),
            const SizedBox(height: 2),
            if (!showSystemBatch && !isParentCreate)
              SwitchListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: -2, vertical: -4),
                contentPadding: EdgeInsets.zero,
                value: _autoMatchIcon,
                onChanged: (value) => setState(() => _autoMatchIcon = value),
                title: const Text("自动匹配图标", style: TextStyle(fontSize: 11)),
                subtitle: Text(
                  "根据名称自动选择更合适的图标",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("一级分类", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              Text(
                widget.parentName ?? "",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ],
          ),
          const Divider(height: 20),
          if (showSystemBatch)
            Row(
              children: [
                const Text("二级分类", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                if (widget.autoBatchAdd)
                  Text(
                    "点击下方分类自动添加",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                else ...[
                  Text(
                    "已选择 ${_selectedSystemNames.length} 个",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _selectedSystemNames.isEmpty
                        ? null
                        : () => setState(() => _selectedSystemNames.clear()),
                    child: const Text("清空"),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                const Text("二级分类", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "输入分类名称",
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                GestureDetector(
                  onTap: _pickCustomIcon,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: highlightColor.withValues(alpha: 0.12),
                    child: CategoryService.buildIcon(
                      _selectedIcon,
                      size: 16,
                      color: highlightColor,
                    ),
                  ),
                ),
              ],
            ),
          if (duplicateHint != null) ...[
            const SizedBox(height: 6),
            Text(
              duplicateHint,
              style: TextStyle(fontSize: 11, color: Colors.red.shade400),
            ),
          ],
          const SizedBox(height: 10),
          _buildColorPicker(),
        ],
      ),
    );
  }

  Widget _buildIconSection() {
    final query = _normalizeSearch(_iconQuery);
    final highlightColor = _resolveSelectedColor() ?? JiveTheme.primaryGreen;
    final icons = categoryIconEntries.where((entry) {
      if (query.isEmpty) return true;
      final key = _iconSearchCache[entry.name] ??= buildIconSearchKey(entry);
      return key.contains(query);
    }).toList();

    if (icons.isEmpty && _iconQuery.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("分类图标", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _iconSearchController,
              onChanged: (value) => setState(() => _iconQuery = value),
              decoration: InputDecoration(
                hintText: "搜索图标",
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _iconQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _iconSearchController.clear();
                          setState(() => _iconQuery = "");
                        },
                      ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text("未找到相关图标", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("分类图标", style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _pickCustomIcon,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: const Text("更多图标"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _iconSearchController,
            onChanged: (value) => setState(() => _iconQuery = value),
            decoration: InputDecoration(
              hintText: "搜索图标",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _iconQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _iconSearchController.clear();
                        setState(() => _iconQuery = "");
                      },
                    ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final entry = icons[index];
              final isSelected = entry.name == _selectedIcon;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _applyIconSelection(
                  entry.name,
                  label: _iconLabelByName[entry.name],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? highlightColor.withValues(alpha: 0.15) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? highlightColor : Colors.transparent,
                    ),
                  ),
                  child: CategoryService.buildIcon(
                    entry.name,
                    size: 20,
                    color: isSelected ? highlightColor : JiveTheme.categoryIconInactive,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCategorySection() {
    if (_systemGroups.isEmpty) return const SizedBox.shrink();
    final highlightColor = _resolveSelectedColor() ?? JiveTheme.primaryGreen;
    final query = _normalizeSearch(_systemQuery);
    final isSearching = query.isNotEmpty;
    final items = isSearching ? _searchSystemItems(query) : _currentGroupItems();
    final listHeight = _systemListHeight(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final labelStyle = const TextStyle(fontWeight: FontWeight.bold);
              final countStyle = TextStyle(fontSize: 11, color: Colors.grey.shade500);
              final labelWidth = _measureTextWidth("分类图标", labelStyle);
              final countText = _isBatch && !widget.autoBatchAdd
                  ? "已选 ${_selectedSystemNames.length}"
                  : "";
              final countWidth = countText.isEmpty ? 0.0 : _measureTextWidth(countText, countStyle);
              const columnsButtonWidth = 32.0;
              const columnsButtonGap = 8.0;
              const emojiButtonWidth = 32.0;
              const emojiButtonGap = 8.0;
              final reserved = labelWidth +
                  (countText.isEmpty ? 0.0 : (8 + countWidth)) +
                  columnsButtonWidth +
                  columnsButtonGap +
                  emojiButtonWidth +
                  emojiButtonGap +
                  12;
              final maxSearchWidth = (constraints.maxWidth - reserved).clamp(120.0, constraints.maxWidth);
              final maxCompactWidth = maxSearchWidth < constraints.maxWidth * 0.65
                  ? maxSearchWidth
                  : constraints.maxWidth * 0.65;
              final searchWidth = _computeSearchFieldWidth(maxCompactWidth);
              return Row(
                children: [
                  Text("分类图标", style: labelStyle),
                  if (_isBatch && !widget.autoBatchAdd) ...[
                    const SizedBox(width: 8),
                    Text(
                      "已选 ${_selectedSystemNames.length}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                  const Spacer(),
                  _buildColumnsMenu(),
                  const SizedBox(width: 8),
                  _buildEmojiPickerButton(),
                  const SizedBox(width: 8),
                  _buildInlineSearchField(searchWidth),
                ],
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            _isBatch
                ? (widget.autoBatchAdd ? "点击即可自动添加" : "选择多个后保存即可自动添加")
                : "点击可填充名称与图标",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: listHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                var leftWidth = 46.0;
                var availableWidth = (constraints.maxWidth - leftWidth - gap).clamp(0.0, double.infinity);
                var columns = _columnsForWidth(availableWidth);
                leftWidth = _leftWidthForColumns(columns);
                availableWidth = (constraints.maxWidth - leftWidth - gap).clamp(0.0, double.infinity);
                columns = _columnsForWidth(availableWidth);
                leftWidth = _leftWidthForColumns(columns);
                final leftFontSize = _leftFontSizeForColumns(columns);
                final leftRowMargin = _leftRowMarginForColumns(columns);
                final leftRowPadding = _leftRowPaddingForColumns(columns);
                final leftLineHeight = _leftLineHeightForColumns(columns);
                final leftIndicatorWidth = _leftIndicatorWidthForColumns(columns);
                final iconSize = _systemIconSizeForColumns(columns);
                final iconBox = _systemIconBoxForColumns(columns);
                final labelSize = _systemLabelSizeForColumns(columns);
                final labelHeight = _systemLabelHeightForColumns(columns);
                final indicatorSize = _systemIndicatorSizeForColumns(columns);
                final gridSpacing = _systemGridSpacingForColumns(columns);
                final tileHeight = _systemTileHeight(context, columns);
                final tilePadding = _systemTilePaddingForColumns(columns);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: leftWidth,
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: _systemGroupController,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          primary: false,
                          controller: _systemGroupController,
                          addAutomaticKeepAlives: false,
                          itemCount: _systemGroups.length,
                          itemBuilder: (context, index) {
                            final group = _systemGroups[index];
                            final isSelected = !isSearching && group.name == _selectedGroupName;
                            return InkWell(
                              onTap: () {
                                if (isSearching) return;
                                setState(() {
                                  _selectedGroupName = group.name;
                                  _applyGroupSelection(group);
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                margin: EdgeInsets.symmetric(vertical: leftRowMargin),
                                padding: EdgeInsets.symmetric(vertical: leftRowPadding, horizontal: 0),
                                decoration: BoxDecoration(
                                  color: isSelected ? JiveTheme.primaryGreen.withValues(alpha: 0.04) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border(
                                    left: BorderSide(
                                      color: isSelected ? JiveTheme.primaryGreen : Colors.transparent,
                                      width: leftIndicatorWidth,
                                    ),
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    group.name,
                                    style: TextStyle(
                                      fontSize: leftFontSize,
                                      height: leftLineHeight,
                                      color: isSelected ? JiveTheme.primaryGreen : Colors.grey.shade600,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.left,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: items.isEmpty
                          ? Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  isSearching ? "未找到相关分类" : "暂无可用分类",
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ),
                            )
                          : Scrollbar(
                              thumbVisibility: true,
                              controller: _systemGridController,
                              child: GridView.builder(
                                padding: EdgeInsets.zero,
                                primary: false,
                                controller: _systemGridController,
                                cacheExtent: tileHeight * 8,
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: gridSpacing,
                                  mainAxisSpacing: gridSpacing,
                                  mainAxisExtent: tileHeight,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final entry = items[index];
                                  final isExisting = _existingNames.contains(entry.name);
                                  final isParentCreate = _isParentCreateMode();
                                  final isDisabled = _isBatch && isExisting;
                                  final isSelected = _isBatch
                                      ? _selectedSystemNames.contains(entry.name)
                                      : (isParentCreate
                                          ? entry.iconName == _selectedIcon
                                          : entry.name == _nameController.text.trim() &&
                                              entry.iconName == _selectedIcon);
                                  final canTap = !isDisabled;
                                  return RepaintBoundary(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: canTap ? () => _applySuggestion(entry) : null,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: tilePadding, horizontal: tilePadding),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: iconBox,
                                              height: iconBox,
                                              decoration: BoxDecoration(
                                                color: isSelected ? highlightColor.withValues(alpha: 0.15) : Colors.transparent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: CategoryService.buildIcon(
                                                  entry.iconName,
                                                  size: iconSize,
                                                  color: isDisabled
                                                      ? Colors.grey.shade400
                                                      : (isSelected
                                                          ? highlightColor
                                                          : JiveTheme.categoryIconInactive),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              entry.name,
                                              style: TextStyle(
                                                fontSize: labelSize,
                                                height: labelHeight,
                                                color: isDisabled
                                                    ? Colors.grey.shade400
                                                    : JiveTheme.categoryLabelInactive,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                            ),
                                            if (_isBatch && !widget.autoBatchAdd && !isDisabled)
                                              Icon(
                                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                                size: indicatorSize,
                                                color: isSelected ? highlightColor : Colors.grey.shade400,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _computeSearchFieldWidth(double maxWidth) {
    const textStyle = TextStyle(fontSize: 12);
    const prefixWidth = 32.0;
    const horizontalPadding = 20.0;
    const suffixWidth = 32.0;
    final text = _systemQuery.isEmpty ? "搜索" : _systemQuery;
    final textWidth = _measureTextWidth(text, textStyle);
    final minWidth = _measureTextWidth("搜索", textStyle) + prefixWidth + horizontalPadding + suffixWidth;
    final extra = suffixWidth;
    final desired = textWidth + prefixWidth + horizontalPadding + extra + 12;
    final safeMaxWidth = maxWidth < minWidth ? minWidth : maxWidth;
    return desired.clamp(minWidth, safeMaxWidth);
  }

  Widget _buildInlineSearchField(double targetWidth) {
    const textStyle = TextStyle(fontSize: 12);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: targetWidth,
      height: 32,
      child: TextField(
        controller: _systemSearchController,
        style: textStyle,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: "搜索",
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIcon: _systemQuery.isEmpty
              ? const SizedBox(width: 32, height: 32)
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  onPressed: () {
                    _systemSearchController.clear();
                  },
                ),
          filled: true,
          isDense: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  Widget _buildColumnsMenu() {
    return PopupMenuButton<int>(
      tooltip: "列数",
      onSelected: (value) {
        setState(() => _systemGridColumns = value);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.white,
      elevation: 6,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 120),
	      itemBuilder: (context) {
	        return [
	          for (final columns in const [3, 4, 5, 6])
	            PopupMenuItem(
	              value: columns,
	              height: 32,
	              child: Row(
	                children: [
	                  Icon(Icons.grid_view_rounded, size: 16, color: Colors.grey.shade600),
	                  const SizedBox(width: 6),
	                  Text('$columns列', style: const TextStyle(fontSize: 12)),
	                  const Spacer(),
	                  if (_systemGridColumns == columns)
	                    Icon(Icons.check, size: 16, color: JiveTheme.primaryGreen),
	                ],
	              ),
            ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.grid_view_rounded, size: 18, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildEmojiPickerButton() {
    return Tooltip(
      message: "表情符号",
      child: InkWell(
        onTap: _pickEmojiIcon,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.emoji_emotions_outlined, size: 18, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  List<SystemCategorySuggestion> _currentGroupItems() {
    if (_systemGroups.isEmpty) return [];
    final group = _systemGroups.firstWhere(
      (item) => item.name == _selectedGroupName,
      orElse: () => _systemGroups.first,
    );
    return group.children;
  }

  List<SystemCategorySuggestion> _searchSystemItems(String query) {
    final results = <SystemCategorySuggestion>[];
    final seen = <String>{};
    for (final group in _systemGroups) {
      for (final child in group.children) {
        if (!seen.add(child.name)) continue;
        final key = _systemSearchCache[child.name] ??= _buildSystemSearchKey(child);
        if (key.contains(query)) {
          results.add(child);
        }
      }
    }
    return results;
  }

  Future<void> _applySuggestion(SystemCategorySuggestion suggestion) async {
    if (_isBatch && _existingNames.contains(suggestion.name)) return;
    if (_isBatch && widget.autoBatchAdd && widget.onBatchAdd != null) {
      await _applyBatchAdd(suggestion);
      return;
    }
    if (_isBatch) {
      setState(() {
        if (_selectedSystemNames.contains(suggestion.name)) {
          _selectedSystemNames.remove(suggestion.name);
        } else {
          _selectedSystemNames.add(suggestion.name);
        }
      });
      return;
    }
    setState(() => _selectedIcon = suggestion.iconName);
    _nameController.text = suggestion.name;
    _nameController.selection = TextSelection.collapsed(offset: _nameController.text.length);
  }

  Future<void> _applyBatchAdd(SystemCategorySuggestion suggestion) async {
    final handler = widget.onBatchAdd;
    if (handler == null) return;
    final added = await handler(suggestion, _selectedColorHex);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    if (added) {
      _hasAutoChanges = true;
      setState(() => _existingNames.add(suggestion.name));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已添加: ${suggestion.name}")),
      );
    } else {
      setState(() => _existingNames.add(suggestion.name));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已存在: ${suggestion.name}")),
      );
    }
  }

  void _applyGroupSelection(_SystemGroup group) {
    final allowParentPick = _isParentCreateMode();
    if (!allowParentPick) return;
    final suggestion = _systemItemByName[group.name];
    if (suggestion == null) return;
    _applySuggestion(suggestion);
  }

  bool _isParentCreateMode() {
    final parentName = widget.parentName?.trim();
    return widget.parentOnly ||
        parentName == null ||
        parentName.isEmpty ||
        parentName == "支出" ||
        parentName == "收入";
  }

  String? _effectiveTypeName() {
    if (widget.typeName != null) return widget.typeName;
    final parentName = widget.parentName?.trim();
    if (parentName == "支出" || parentName == "收入") return parentName;
    return null;
  }

  Widget _buildBatchActionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Text(
              "已选 ${_selectedSystemNames.length} 个",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: JiveTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: const Text("一键添加"),
            ),
          ],
        ),
      ),
    );
  }

  void _exitWithChanges() {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    Navigator.pop(
      context,
      CategoryCreateResult(
        names: const [],
        iconName: _selectedIcon,
        colorHex: _selectedColorHex,
        hasChanges: _hasAutoChanges,
      ),
    );
  }

  void _save() {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    final selections = _selectedSystemNames.isEmpty
        ? const <SystemCategorySuggestion>[]
        : _selectedSystemNames
            .map((name) => _systemItemByName[name])
            .whereType<SystemCategorySuggestion>()
            .toList();
    if (selections.isNotEmpty) {
      Navigator.pop(
        context,
        CategoryCreateResult(
          names: selections.map((entry) => entry.name).toList(),
          iconName: _selectedIcon,
          colorHex: _selectedColorHex,
          autoMatchIcon: false,
          systemSelections: selections,
        ),
      );
      return;
    }
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

  String? _duplicateNameHint() {
    final raw = _nameController.text.trim();
    if (raw.isEmpty) return null;
    if (_isBatch) {
      final names = _parseNames();
      final duplicates = names.where((name) => _existingNames.contains(name)).toList();
      if (duplicates.isEmpty) return null;
      final preview = duplicates.take(3).join("、");
      final suffix = duplicates.length > 3 ? "等" : "";
      return "包含已存在名称：$preview$suffix，将自动跳过";
    }
    if (_existingNames.contains(raw)) {
      return "名称已存在";
    }
    return null;
  }

  void _scrollToIcons() {
    _pickCustomIcon();
  }

  String _normalizeSearch(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  }

  Map<String, String> _buildIconLabelMap() {
    final map = <String, String>{};
    for (final entry in categoryIconEntries) {
      final label = _preferredIconLabel(entry);
      if (label.isEmpty) continue;
      map[entry.name] = label;
    }
    return map;
  }

  String _preferredIconLabel(CategoryIconEntry entry) {
    if (entry.name == "category") return "";
    for (final keyword in entry.keywords) {
      if (_containsCjk(keyword)) return keyword;
    }
    return entry.keywords.isEmpty ? "" : entry.keywords.first;
  }

  bool _containsCjk(String value) {
    return RegExp(r'[\\u4e00-\\u9fff]').hasMatch(value);
  }

  void _applyIconSelection(String iconName, {String? label}) {
    setState(() => _selectedIcon = iconName);
    _maybeFillName(label ?? _guessLabelFromIcon(iconName));
  }

  void _maybeFillName(String? label) {
    if (_isBatch) return;
    final trimmed = label?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    final current = _nameController.text.trim();
    if (current.isNotEmpty && current != _lastAutoFilledName) return;
    _nameController.text = trimmed;
    _nameController.selection = TextSelection.collapsed(offset: _nameController.text.length);
    _lastAutoFilledName = trimmed;
  }

  void _handleNameChange() {
    final current = _nameController.text.trim();
    if (_lastAutoFilledName != null && current != _lastAutoFilledName) {
      _lastAutoFilledName = null;
    }
  }

  String? _guessLabelFromIcon(String iconName) {
    final trimmed = iconName.trim();
    if (trimmed.isEmpty || trimmed == "category") return null;
    if (trimmed.startsWith("emoji:") || trimmed.startsWith("file:")) return null;
    if (trimmed.startsWith("text:")) {
      final text = trimmed.substring("text:".length).trim();
      return text.isEmpty ? null : text;
    }
    final mapped = _iconLabelByName[trimmed];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    return _labelFromAssetName(trimmed);
  }

  String? _labelFromAssetName(String iconName) {
    var name = iconName;
    if (name.startsWith("assets/")) {
      name = name.split("/").last;
    } else if (name.startsWith("qj/")) {
      name = name.substring(3);
    }
    name = name.replaceAll(RegExp(r'\\.(png|svg)$'), '');
    if (name.contains('__')) {
      final parts = name.split('__');
      if (parts.length > 1) {
        final label = parts[1].replaceAll('_', ' ').trim();
        return label.isEmpty ? null : label;
      }
    }
    return null;
  }

  String _canonicalGroupName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;
    return _groupAliasMap[trimmed] ?? trimmed;
  }

  List<String> _expandGroupTokens(String raw) {
    final tokens = raw.split(RegExp(r'[\\/、\\s]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (tokens.isEmpty) return [raw];
    return tokens;
  }

  int _columnsForWidth(double width) {
    if (_systemGridColumns >= 3 && _systemGridColumns <= 6) {
      return _systemGridColumns;
    }
    final columns = (width / 42).floor();
    if (columns >= 6) return 6;
    if (columns >= 5) return 5;
    if (columns >= 4) return 4;
    return 3;
  }

  double _leftFontSizeForColumns(int columns) {
    if (columns <= 3) return 13.5;
    if (columns == 4) return 12.5;
    if (columns == 5) return 12.5;
    return 11.5;
  }

  double _leftLineHeightForColumns(int columns) {
    if (columns <= 3) return 1.25;
    if (columns == 4) return 1.2;
    if (columns == 5) return 1.2;
    return 1.15;
  }

  double _leftRowMarginForColumns(int columns) {
    if (columns <= 3) return 6;
    if (columns == 4) return 5;
    if (columns == 5) return 5;
    return 4;
  }

  double _leftRowPaddingForColumns(int columns) {
    if (columns <= 3) return 7;
    if (columns == 4) return 6;
    if (columns == 5) return 6;
    return 5;
  }

  double _leftWidthForColumns(int columns) {
    if (columns <= 3) return 54;
    if (columns == 4) return 52;
    if (columns == 5) return 50;
    return 46;
  }

  double _leftIndicatorWidthForColumns(int columns) {
    if (columns <= 5) return 1.5;
    return 1.2;
  }

  double _systemIconSizeForColumns(int columns) {
    if (columns <= 3) return 22;
    if (columns == 4) return 20;
    if (columns == 5) return 18;
    return 16;
  }

  double _systemIconBoxForColumns(int columns) {
    if (columns <= 3) return 32;
    if (columns == 4) return 30;
    if (columns == 5) return 28;
    return 26;
  }

  double _systemLabelSizeForColumns(int columns) {
    if (columns <= 3) return 11;
    if (columns == 4) return 10;
    if (columns == 5) return 9;
    return 8;
  }

  double _systemLabelHeightForColumns(int columns) {
    if (columns <= 4) return 1.1;
    if (columns == 5) return 1.05;
    return 1.0;
  }

  double _systemIndicatorSizeForColumns(int columns) {
    if (columns <= 3) return 14;
    if (columns == 4) return 12;
    if (columns == 5) return 11;
    return 10;
  }

  double _systemGridSpacingForColumns(int columns) {
    if (columns <= 3) return 6;
    if (columns == 4) return 5;
    return 4;
  }

  double _systemTilePaddingForColumns(int columns) {
    if (columns <= 3) return 3;
    if (columns == 4) return 2.5;
    if (columns == 5) return 2;
    return 1;
  }

  double _systemListHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeHeight = media.size.height - media.padding.top - media.padding.bottom - media.viewInsets.bottom;
    final target = safeHeight * 0.62;
    return target.clamp(240.0, 640.0);
  }

	double _systemTileHeight(BuildContext context, int columns) {
	  final scale = MediaQuery.textScalerOf(context).scale(14.0) / 14.0;
	  double base;
	  if (columns <= 3) {
	    base = 80;
	  } else if (columns == 4) {
      base = 72;
    } else if (columns == 5) {
      base = 64;
    } else {
      base = 58;
    }
    if (scale >= 1.2) return base + 6;
    if (scale >= 1.1) return base + 3;
    return base;
  }

  Color? _resolveSelectedColor() {
    return CategoryService.parseColorHex(_selectedColorHex);
  }

	String _colorHexFromColor(Color color) {
	  final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
	  return "#${value.substring(2).toUpperCase()}";
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

  String _buildSystemSearchKey(SystemCategorySuggestion entry) {
    final name = _normalizeSearch(entry.name);
    final icon = _normalizeSearch(entry.iconName);
    final pinyin = _normalizeSearch(PinyinHelper.getPinyinE(entry.name));
    final short = _normalizeSearch(PinyinHelper.getShortPinyin(entry.name));
    final buffer = StringBuffer("$name $icon $pinyin $short");
    final aliases = _groupAliasReverseMap[entry.name] ?? const [];
    for (final alias in aliases) {
      final normalized = _normalizeSearch(alias);
      buffer.write(" $normalized");
      buffer.write(" ${_normalizeSearch(PinyinHelper.getPinyinE(alias))}");
      buffer.write(" ${_normalizeSearch(PinyinHelper.getShortPinyin(alias))}");
    }
    return buffer.toString();
  }
}

class _SystemGroup {
  final String name;
  final String iconName;
  final List<SystemCategorySuggestion> children;

  const _SystemGroup({
    required this.name,
    required this.iconName,
    required this.children,
  });
}

const Map<String, String> _groupAliasMap = {
  '吃喝': '餐饮',
  '三餐': '餐饮',
  '母婴': '育儿',
  '母婴育儿': '育儿',
  '宝宝': '育儿',
  '婴儿': '育儿',
  '工资': '收入',
  '奖金': '收入',
  '提成': '收入',
  '津贴': '收入',
  '补贴': '收入',
  '薪水': '收入',
  '理财': '金融',
  '股票': '金融',
  '基金': '金融',
  '利息': '金融',
  '其他': '其它',
};

const Map<String, List<String>> _groupAliasReverseMap = {
  '餐饮': ['吃喝', '三餐'],
  '育儿': ['母婴', '母婴育儿', '宝宝', '婴儿'],
  '收入': ['工资', '奖金', '提成', '津贴', '补贴', '薪水'],
  '金融': ['理财', '股票', '基金', '利息'],
  '其它': ['其他'],
};

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
