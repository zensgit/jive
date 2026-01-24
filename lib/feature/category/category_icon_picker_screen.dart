import 'package:flutter/material.dart';
import '../../core/data/emoji_library.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';
import '../../core/data/system_category_library.dart';
import 'category_icon_library.dart';

class _IconCandidate {
  final String iconName;
  final CategoryIconEntry entry;
  final bool isSystem;

  const _IconCandidate({
    required this.iconName,
    required this.entry,
    required this.isSystem,
  });
}

class _SystemIconSuggestion {
  final String name;
  final String iconName;
  final List<String> keywords;

  const _SystemIconSuggestion({
    required this.name,
    required this.iconName,
    required this.keywords,
  });
}

enum CategoryIconPickerMode { category, emoji }

class CategoryIconPickerScreen extends StatefulWidget {
  final String initialIcon;
  final CategoryIconPickerMode? initialMode;

  const CategoryIconPickerScreen({
    super.key,
    required this.initialIcon,
    this.initialMode,
  });

  @override
  State<CategoryIconPickerScreen> createState() => _CategoryIconPickerScreenState();
}

class _CategoryIconPickerScreenState extends State<CategoryIconPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _searchCache = {};
  String _query = "";
  late String _selectedIcon;
  late final List<_IconCandidate> _icons;
  late CategoryIconPickerMode _mode;
  late final Future<EmojiCatalog> _emojiFuture;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    _mode = widget.initialMode ??
        (_selectedIcon.startsWith("emoji:")
            ? CategoryIconPickerMode.emoji
            : CategoryIconPickerMode.category);
    _icons = _buildCandidates();
    _emojiFuture = EmojiLibrary.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = JiveTheme.primaryGreen;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("选择图标", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedIcon),
            child: const Text("确定"),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildModeSwitch(highlightColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: _mode == CategoryIconPickerMode.emoji
                              ? "搜索表情"
                              : "搜索图标",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = "");
                                  },
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _mode == CategoryIconPickerMode.category
                ? _buildCategoryGrid(highlightColor)
                : _buildEmojiPanel(highlightColor),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch(Color highlightColor) {
    final isCategory = _mode == CategoryIconPickerMode.category;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: "分类图标",
          child: _ModeSwitchIcon(
            icon: Icons.grid_view_rounded,
            highlightColor: highlightColor,
            selected: isCategory,
            onTap: () => _setMode(CategoryIconPickerMode.category),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: "表情符号",
          child: _ModeSwitchIcon(
            icon: Icons.emoji_emotions_outlined,
            highlightColor: highlightColor,
            selected: !isCategory,
            onTap: () => _setMode(CategoryIconPickerMode.emoji),
          ),
        ),
      ],
    );
  }

  void _setMode(CategoryIconPickerMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _searchController.clear();
      _query = "";
    });
  }

  Widget _buildCategoryGrid(Color highlightColor) {
    final normalized = normalizeSearch(_query);
    final icons = _icons.where((candidate) {
      if (normalized.isEmpty) return true;
      final key = _searchCache[candidate.iconName] ??= buildIconSearchKey(candidate.entry);
      return key.contains(normalized);
    }).toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final entry = icons[index];
        final isSelected = entry.iconName == _selectedIcon;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedIcon = entry.iconName),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? highlightColor.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? highlightColor : Colors.grey.shade200,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryService.buildIcon(
                  entry.iconName,
                  size: 22,
                  color: isSelected ? highlightColor : Colors.grey.shade700,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    entry.entry.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? highlightColor : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiPanel(Color highlightColor) {
    return FutureBuilder<EmojiCatalog>(
      future: _emojiFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final catalog = snapshot.data!;
        final filtered =
            _query.isEmpty ? null : EmojiLibrary.filter(catalog.entries, _query);
        if (filtered != null) {
          return _EmojiGrid(
            entries: filtered,
            selectedIcon: _selectedIcon,
            highlightColor: highlightColor,
            onSelect: (value) => setState(() => _selectedIcon = value),
            emptyText: "未找到相关表情",
          );
        }
        return DefaultTabController(
          length: catalog.groups.length,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                labelColor: highlightColor,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: highlightColor,
                tabs: [
                  for (final group in catalog.groups)
                    Tab(text: _displayGroupName(group.name)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final group in catalog.groups)
                      _EmojiGrid(
                        entries: group.entries,
                        selectedIcon: _selectedIcon,
                        highlightColor: highlightColor,
                        onSelect: (value) => setState(() => _selectedIcon = value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _displayGroupName(String group) {
    switch (group) {
      case 'Smileys & Emotion':
        return '表情与情绪';
      case 'People & Body':
        return '人物与身体';
      case 'Animals & Nature':
        return '动物与自然';
      case 'Food & Drink':
        return '食物与饮料';
      case 'Travel & Places':
        return '旅行与地点';
      case 'Activities':
        return '活动';
      case 'Objects':
        return '物体';
      case 'Symbols':
        return '符号';
      case 'Flags':
        return '旗帜';
      default:
        return group;
    }
  }

  List<_IconCandidate> _buildCandidates() {
    final systemCandidates = _buildSystemCandidates();
    final systemIconNames = {
      for (final candidate in systemCandidates) candidate.iconName,
    };
    final extraCandidates = <_IconCandidate>[];
    for (final entry in categoryIconEntries) {
      if (systemIconNames.contains(entry.name)) continue;
      extraCandidates.add(
        _IconCandidate(
          iconName: entry.name,
          entry: entry,
          isSystem: false,
        ),
      );
    }
    extraCandidates.sort(
      (a, b) => CategoryService.compareCategoryName(a.entry.name, b.entry.name),
    );

    final candidates = <_IconCandidate>[
      ...systemCandidates,
      ...extraCandidates,
    ];

    if (!_hasIcon(candidates, _selectedIcon)) {
      final fallbackLabel = _fallbackLabel(_selectedIcon);
      candidates.insert(
        0,
        _IconCandidate(
          iconName: _selectedIcon,
          entry: CategoryIconEntry(fallbackLabel, [fallbackLabel]),
          isSystem: false,
        ),
      );
    }
    return candidates;
  }

  List<_IconCandidate> _buildSystemCandidates() {
    final suggestions = <_SystemIconSuggestion>[];

    void addSuggestion(String name, String iconName, List<String> keywords) {
      final trimmedName = name.trim();
      final trimmedIcon = iconName.trim();
      if (trimmedName.isEmpty || trimmedIcon.isEmpty) return;
      final mergedKeywords = <String>{trimmedName, ...keywords};
      suggestions.add(
        _SystemIconSuggestion(
          name: trimmedName,
          iconName: trimmedIcon,
          keywords: mergedKeywords.toList(),
        ),
      );
    }

    void addLibrary(Map<String, Map<String, dynamic>> lib) {
      for (final entry in lib.entries) {
        final parentName = entry.key;
        final parentIcon = entry.value['icon'] as String? ?? "category";
        addSuggestion(parentName, parentIcon, [parentName]);
        final children = entry.value['children'] as List<dynamic>? ?? const [];
        for (final child in children) {
          final name = (child['name'] as String? ?? "").trim();
          final icon = child['icon'] as String? ?? "category";
          if (name.isEmpty) continue;
          addSuggestion(name, icon, [name, parentName]);
        }
      }
    }

    addLibrary(kSystemExpenseLibrary);
    addLibrary(kSystemIncomeLibrary);

    suggestions.sort((a, b) => CategoryService.compareCategoryName(a.name, b.name));

    final keywordsByIcon = <String, Set<String>>{};
    final labelByIcon = <String, String>{};
    final iconOrder = <String>[];

    for (final suggestion in suggestions) {
      final icon = suggestion.iconName;
      final keywords = keywordsByIcon.putIfAbsent(icon, () => <String>{});
      keywords.addAll(suggestion.keywords);
      if (!labelByIcon.containsKey(icon)) {
        labelByIcon[icon] = suggestion.name;
        iconOrder.add(icon);
      }
    }

    return iconOrder.map((iconName) {
      final label = labelByIcon[iconName] ?? iconName;
      final keywords = keywordsByIcon[iconName]?.toList() ?? <String>[label];
      return _IconCandidate(
        iconName: iconName,
        entry: CategoryIconEntry(label, keywords),
        isSystem: true,
      );
    }).toList();
  }

  bool _hasIcon(List<_IconCandidate> candidates, String iconName) {
    return candidates.any((candidate) => candidate.iconName == iconName);
  }

  String _fallbackLabel(String iconName) {
    if (iconName.startsWith("text:")) {
      final text = iconName.substring("text:".length).trim();
      return text.isEmpty ? "文字图标" : text;
    }
    if (iconName.startsWith("emoji:")) {
      return "表情符号";
    }
    if (iconName.startsWith("file:")) {
      return "自定义图片";
    }
    return iconName;
  }
}

class _ModeSwitchIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color highlightColor;
  final VoidCallback onTap;

  const _ModeSwitchIcon({
    required this.icon,
    required this.selected,
    required this.highlightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? highlightColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? highlightColor : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? highlightColor : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  final List<EmojiEntry> entries;
  final String selectedIcon;
  final Color highlightColor;
  final ValueChanged<String> onSelect;
  final String? emptyText;

  const _EmojiGrid({
    required this.entries,
    required this.selectedIcon,
    required this.highlightColor,
    required this.onSelect,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          emptyText ?? '',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    const iconSize = 28.0;
    final ratio = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (iconSize * ratio).round();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final iconName = 'emoji:${entry.sequence}';
        final isSelected = iconName == selectedIcon;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(iconName),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? highlightColor.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? highlightColor : Colors.grey.shade200,
              ),
            ),
            child: Center(
              child: Image.asset(
                entry.assetPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                cacheWidth: cacheWidth,
                errorBuilder: (_, __, ___) => Text(entry.emoji),
              ),
            ),
          ),
        );
      },
    );
  }
}
