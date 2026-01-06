import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';
import 'category_create_dialog.dart';

class CategoryCreateScreen extends StatefulWidget {
  final String title;
  final String? parentName;
  final String initialIcon;
  final String? nameLabel;
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
  late final List<_SystemGroup> _systemGroups;
  late final Map<String, SystemCategorySuggestion> _systemItemByName;
  String _selectedGroupName = "";
  int _systemGridColumns = 4;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialText ?? "");
    _selectedIcon = widget.initialIcon;
    _isBatch = widget.allowBatch && widget.initialBatch;
    _existingNames.addAll(widget.existingNames);
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
    _nameController.dispose();
    _iconSearchController.dispose();
    _systemSearchController.removeListener(_systemSearchListener);
    _systemSearchController.dispose();
    super.dispose();
  }

  void _initSystemGroups() {
    final library = widget.systemLibrary;
    if (library == null || library.isEmpty) {
      _systemGroups = const [];
      _systemItemByName = const {};
      return;
    }

    final groupChildren = <String, List<SystemCategorySuggestion>>{};
    final groupChildNames = <String, Set<String>>{};
    final groupIcons = <String, String>{};
    final itemByName = <String, SystemCategorySuggestion>{};
    final allSuggestions = <String, SystemCategorySuggestion>{};
    final globalChildNames = <String>{};
    void upsertSuggestion(Map<String, SystemCategorySuggestion> map, String name, String iconName) {
      if (name.trim().isEmpty) return;
      final existing = map[name];
      if (existing == null || (existing.iconName == "category" && iconName != "category")) {
        map[name] = SystemCategorySuggestion(name: name, iconName: iconName);
      }
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
      upsertSuggestion(allSuggestions, groupName, icon);

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
        final suggestion = SystemCategorySuggestion(name: name, iconName: childIcon);
        children.add(suggestion);
        upsertSuggestion(allSuggestions, name, childIcon);
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
      children.sort((a, b) => a.name.compareTo(b.name));
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
      allList.sort((a, b) => a.name.compareTo(b.name));
      sortedGroups.add(_SystemGroup(name: "全部", iconName: "category", children: allList));
    }

    groups.sort((a, b) {
      final aIndex = _preferredGroupOrder.indexOf(a.name);
      final bIndex = _preferredGroupOrder.indexOf(b.name);
      if (aIndex != -1 || bIndex != -1) {
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      }
      return a.name.compareTo(b.name);
    });
    sortedGroups.addAll(groups);

    itemByName.addAll(allSuggestions);
    _systemGroups = sortedGroups;
    _systemItemByName = itemByName;
    _selectedGroupName = _resolveInitialGroup();
  }

  String _resolveInitialGroup() {
    if (_systemGroups.isEmpty) return "";
    final initial = widget.initialGroupName?.trim();
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
    return WillPopScope(
      onWillPop: () async {
        _exitWithChanges();
        return false;
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
            const SizedBox(height: 16),
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
    if (widget.parentName == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showSystemBatch) ...[
                  GestureDetector(
                    onTap: () => _scrollToIcons(),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: highlightColor.withOpacity(0.1),
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
                        labelText: widget.nameLabel ?? "分类名称",
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: _isBatch ? TextInputType.multiline : TextInputType.text,
                      textInputAction: _isBatch ? TextInputAction.newline : TextInputAction.done,
                      maxLines: _isBatch ? 4 : 1,
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
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 4),
            if (!showSystemBatch)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoMatchIcon,
                onChanged: (value) => setState(() => _autoMatchIcon = value),
                title: const Text("自动匹配图标"),
                subtitle: const Text("根据名称自动选择更合适的图标"),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
                    onSubmitted: (_) => _save(),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: highlightColor.withOpacity(0.12),
                  child: CategoryService.buildIcon(
                    _selectedIcon,
                    size: 16,
                    color: highlightColor,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          _buildColorPicker(),
        ],
      ),
    );
  }

  Widget _buildIconSection() {
    final query = _normalizeSearch(_iconQuery);
    final highlightColor = _resolveSelectedColor() ?? JiveTheme.primaryGreen;
    final icons = _iconEntries.where((entry) {
      if (query.isEmpty) return true;
      final key = _iconSearchCache[entry.name] ??= _buildIconSearchKey(entry);
      return key.contains(query);
    }).toList();

    if (icons.isEmpty && _iconQuery.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
                onTap: () => setState(() => _selectedIcon = entry.name),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? highlightColor.withOpacity(0.15) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? highlightColor : Colors.transparent,
                    ),
                  ),
                  child: CategoryService.buildIcon(
                    entry.name,
                    size: 20,
                    color: isSelected ? highlightColor : Colors.grey.shade700,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
              final reserved = labelWidth +
                  (countText.isEmpty ? 0.0 : (8 + countWidth)) +
                  columnsButtonWidth +
                  columnsButtonGap +
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
                  _buildInlineSearchField(searchWidth),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            _isBatch
                ? (widget.autoBatchAdd ? "点击即可自动添加" : "选择多个后保存即可自动添加")
                : "点击可填充名称与图标",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
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
                final metaSize = _systemMetaSizeForColumns(columns);
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
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          primary: false,
                          itemCount: _systemGroups.length,
                          itemBuilder: (context, index) {
                            final group = _systemGroups[index];
                            final isSelected = !isSearching && group.name == _selectedGroupName;
                            return InkWell(
                              onTap: () {
                                if (isSearching) return;
                                setState(() => _selectedGroupName = group.name);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                margin: EdgeInsets.symmetric(vertical: leftRowMargin),
                                padding: EdgeInsets.symmetric(vertical: leftRowPadding, horizontal: 0),
                                decoration: BoxDecoration(
                                  color: isSelected ? JiveTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
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
                              child: GridView.builder(
                                padding: EdgeInsets.zero,
                                primary: false,
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
                                  final isSelected = _isBatch
                                      ? _selectedSystemNames.contains(entry.name)
                                      : entry.name == _nameController.text.trim() && entry.iconName == _selectedIcon;
                                  final canTap = !isExisting;
                                  return InkWell(
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
                                              color: isSelected ? highlightColor.withOpacity(0.15) : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: CategoryService.buildIcon(
                                                entry.iconName,
                                                size: iconSize,
                                                color: isExisting
                                                    ? Colors.grey.shade400
                                                    : (isSelected ? highlightColor : Colors.grey.shade700),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            entry.name,
                                            style: TextStyle(
                                              fontSize: labelSize,
                                              height: labelHeight,
                                              color: isExisting ? Colors.grey.shade400 : Colors.grey.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                          ),
                                          if (_isBatch && !widget.autoBatchAdd && !isExisting)
                                            Icon(
                                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                              size: indicatorSize,
                                              color: isSelected ? highlightColor : Colors.grey.shade400,
                                            )
                                          else if (isExisting)
                                            Text(
                                              "已添加",
                                              style: TextStyle(fontSize: metaSize, color: Colors.grey.shade400),
                                            ),
                                        ],
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
                  Text("${columns}列", style: const TextStyle(fontSize: 12)),
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
    if (_existingNames.contains(suggestion.name)) return;
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

  Widget _buildBatchActionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
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

  void _scrollToIcons() {
    // Keeping this for future extension (jump to icon area).
  }

  String _normalizeSearch(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
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

  double _systemMetaSizeForColumns(int columns) {
    final size = _systemLabelSizeForColumns(columns) - 1;
    return size < 8 ? 8 : size;
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
    final scale = MediaQuery.textScaleFactorOf(context);
    double base;
    if (columns <= 3) {
      base = 74;
    } else if (columns == 4) {
      base = 66;
    } else if (columns == 5) {
      base = 58;
    } else {
      base = 52;
    }
    if (scale >= 1.2) return base + 6;
    if (scale >= 1.1) return base + 3;
    return base;
  }

  Color? _resolveSelectedColor() {
    return CategoryService.parseColorHex(_selectedColorHex);
  }

  String _colorHexFromColor(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
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

  String _buildIconSearchKey(_IconEntry entry) {
    final buffer = StringBuffer();
    buffer.write(_normalizeSearch(entry.name));
    for (final keyword in entry.keywords) {
      final normalized = _normalizeSearch(keyword);
      buffer.write(" $normalized");
      buffer.write(" ${_normalizeSearch(PinyinHelper.getPinyinE(keyword))}");
      buffer.write(" ${_normalizeSearch(PinyinHelper.getShortPinyin(keyword))}");
    }
    return buffer.toString();
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

class _IconEntry {
  final String name;
  final List<String> keywords;

  const _IconEntry(this.name, this.keywords);
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
  '日常': '日用杂货',
  '日用品': '日用杂货',
  '居家工具': '日用杂货',
  '美妆': '日用杂货',
  '美容美发': '日用杂货',
  '居家': '住房居家',
  '住房': '住房居家',
  '房租': '住房居家',
  '房贷': '住房居家',
  '物业费': '住房居家',
  '水电煤': '住房居家',
  '服饰': '服饰鞋包',
  '鞋包': '服饰鞋包',
  '电器数码': '数码电器',
  '电器': '数码电器',
  '电子产品': '数码电器',
  '数码': '数码电器',
  '娱乐': '娱乐休闲',
  '休闲': '娱乐休闲',
  '电影': '娱乐休闲',
  '演出': '娱乐休闲',
  'K歌': '娱乐休闲',
  '游戏': '娱乐休闲',
  '运动': '娱乐休闲',
  '旅行': '娱乐休闲',
  '门票': '娱乐休闲',
  '教育': '教育学习',
  '学习': '教育学习',
  '培训': '教育学习',
  '考试': '教育学习',
  '学费': '教育学习',
  '校园': '教育学习',
  '汽车/加油': '交通',
  '油费': '交通',
  '洗车': '交通',
  '车险': '交通',
  '车贷': '交通',
  '车检': '交通',
  '购车款': '交通',
  '维修保养': '交通',
  '停车费': '交通',
  '过路费': '交通',
  '违章': '交通',
  '工资': '薪酬',
  '奖金': '薪酬',
  '提成': '薪酬',
  '津贴': '薪酬',
  '补贴': '薪酬',
  '理财': '投资',
  '股票': '投资',
  '基金': '投资',
  '利息': '投资',
  '报销': '补偿',
  '赔付': '补偿',
  '保险报销': '补偿',
  '二手置换': '二手',
  '闲鱼': '二手',
  '人情': '人情往来',
  '发红包': '人情往来',
  '请客送礼': '人情往来',
  '送礼': '人情往来',
  '婚嫁随礼': '人情往来',
  '寿辰': '人情往来',
  '孝敬父母': '人情往来',
  '乔迁': '人情往来',
  '其它': '其他',
};

const Map<String, List<String>> _groupAliasReverseMap = {
  '餐饮': ['吃喝', '三餐'],
  '住房居家': ['居家', '住房', '房租', '房贷', '物业费', '水电煤'],
  '日用杂货': ['日常', '日用品', '居家工具', '美妆', '美容美发'],
  '服饰鞋包': ['服饰', '鞋包'],
  '数码电器': ['电器数码', '电器', '电子产品', '数码'],
  '娱乐休闲': ['娱乐', '休闲', '电影', '演出', 'K歌', '游戏', '运动', '旅行', '门票'],
  '教育学习': ['教育', '学习', '培训', '考试', '学费', '校园'],
  '交通': ['汽车/加油', '油费', '洗车', '车险', '车贷', '车检', '购车款', '维修保养', '停车费', '过路费', '违章'],
  '薪酬': ['工资', '奖金', '提成', '津贴', '补贴'],
  '投资': ['理财', '股票', '基金', '利息'],
  '补偿': ['报销', '赔付', '保险报销'],
  '二手': ['二手置换', '闲鱼'],
  '人情往来': ['人情', '发红包', '请客送礼', '送礼', '婚嫁随礼', '寿辰', '孝敬父母', '乔迁'],
  '其他': ['其它'],
};

const List<String> _preferredGroupOrder = [
  '薪酬',
  '投资',
  '租金',
  '二手',
  '补偿',
  '餐饮',
  '交通',
  '住房居家',
  '日用杂货',
  '服饰鞋包',
  '数码电器',
  '娱乐休闲',
  '教育学习',
  '医疗',
  '人情往来',
  '宠物',
  '税费',
  '其他',
];

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

const List<_IconEntry> _iconEntries = [
  _IconEntry('restaurant', ['餐饮', '美食', 'food', 'restaurant']),
  _IconEntry('bakery_dining', ['早餐', '早饭', 'breakfast']),
  _IconEntry('lunch_dining', ['午餐', '午饭', 'lunch']),
  _IconEntry('dinner_dining', ['晚餐', '晚饭', 'dinner']),
  _IconEntry('tapas', ['夜宵', '宵夜', 'snack']),
  _IconEntry('delivery_dining', ['外卖', 'delivery']),
  _IconEntry('local_cafe', ['饮料', '奶茶', '咖啡', '茶', 'coffee', 'tea']),
  _IconEntry('icecream', ['零食', '甜品', 'icecream']),
  _IconEntry('shopping_basket', ['买菜', '生鲜', 'grocery']),
  _IconEntry('nutrition', ['水果', '果蔬', 'fruit', 'veg']),
  _IconEntry('celebration', ['聚会', 'party']),
  _IconEntry('liquor', ['酒', '酒水', 'liquor', 'wine']),
  _IconEntry('shopping_bag', ['购物', 'shopping']),
  _IconEntry('checkroom', ['服饰', '衣服', 'clothes']),
  _IconEntry('cases', ['鞋包', '包', 'shoes', 'bag']),
  _IconEntry('phone_iphone', ['数码', '手机', 'digital']),
  _IconEntry('kitchen', ['家电', 'appliance']),
  _IconEntry('chair', ['家居', '家具', 'home']),
  _IconEntry('local_shipping', ['快递', '物流', 'delivery']),
  _IconEntry('directions_car', ['交通', '出行', 'car']),
  _IconEntry('local_taxi', ['打车', '出租', 'taxi']),
  _IconEntry('subway', ['地铁', 'subway']),
  _IconEntry('directions_bus', ['公交', 'bus']),
  _IconEntry('local_gas_station', ['加油', 'gas']),
  _IconEntry('local_parking', ['停车', 'parking']),
  _IconEntry('train', ['火车', '高铁', 'train']),
  _IconEntry('flight', ['飞机', '机票', 'flight']),
  _IconEntry('house', ['居住', '住房', 'house']),
  _IconEntry('key', ['房租', '租房', 'rent']),
  _IconEntry('wifi', ['宽带', '网络', 'wifi']),
  _IconEntry('phone_android', ['话费', '手机费', 'phone']),
  _IconEntry('lightbulb', ['水电', '电费', 'water']),
  _IconEntry('business', ['物业', 'property']),
  _IconEntry('sports_esports', ['娱乐', '游戏', 'game']),
  _IconEntry('movie', ['电影', 'movie']),
  _IconEntry('videogame_asset', ['游戏', 'game']),
  _IconEntry('mic', ['KTV', '唱歌', 'karaoke']),
  _IconEntry('sports_basketball', ['运动', '健身', 'sport']),
  _IconEntry('landscape', ['旅行', '旅游', 'travel']),
  _IconEntry('card_membership', ['会员', 'member']),
  _IconEntry('local_hospital', ['医疗', '医院', 'hospital']),
  _IconEntry('medication', ['药品', '药', 'medicine']),
  _IconEntry('local_pharmacy', ['挂号', 'pharmacy']),
  _IconEntry('monitor_heart', ['检查', '体检']),
  _IconEntry('people', ['人情', '社交', 'people']),
  _IconEntry('redeem', ['红包', 'gift', 'bonus']),
  _IconEntry('local_dining', ['请客', '聚餐']),
  _IconEntry('pets', ['宠物', 'pet']),
  _IconEntry('pest_control_rodent', ['猫粮', '狗粮', 'petfood']),
  _IconEntry('trending_up', ['理财', '收益', 'invest']),
  _IconEntry('attach_money', ['工资', '收入', 'salary']),
  _IconEntry('military_tech', ['奖金', 'bonus']),
  _IconEntry('work', ['兼职', '工作', 'job']),
  _IconEntry('sell', ['二手', '卖出', 'sell']),
  _IconEntry('category', ['默认', '分类', 'category']),
];
