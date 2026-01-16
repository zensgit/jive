import 'package:flutter/material.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';
import '../../core/data/system_category_library.dart';
import 'category_icon_library.dart';

class _IconCandidate {
  final String iconName;
  final CategoryIconEntry entry;

  const _IconCandidate({required this.iconName, required this.entry});
}

class CategoryIconPickerScreen extends StatefulWidget {
  final String initialIcon;

  const CategoryIconPickerScreen({super.key, required this.initialIcon});

  @override
  State<CategoryIconPickerScreen> createState() => _CategoryIconPickerScreenState();
}

class _CategoryIconPickerScreenState extends State<CategoryIconPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _searchCache = {};
  String _query = "";
  late String _selectedIcon;
  late final List<_IconCandidate> _icons;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    _icons = _buildCandidates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = JiveTheme.primaryGreen;
    final normalized = normalizeSearch(_query);
    final icons = _icons.where((candidate) {
      if (normalized.isEmpty) return true;
      final key = _searchCache[candidate.iconName] ??= buildIconSearchKey(candidate.entry);
      return key.contains(normalized);
    }).toList();

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: "搜索图标",
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
          ),
        ],
      ),
    );
  }

  List<_IconCandidate> _buildCandidates() {
    final Map<String, Set<String>> keywordsByIcon = {};
    final Map<String, String> labelByIcon = {};

    void addCandidate(String iconName, String label, List<String> keywords) {
      final trimmed = iconName.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed;
      labelByIcon.putIfAbsent(key, () => label);
      final set = keywordsByIcon.putIfAbsent(key, () => <String>{});
      set.add(label);
      set.addAll(keywords);
    }

    void addLibrary(Map<String, Map<String, dynamic>> lib) {
      for (final entry in lib.entries) {
        final parentName = entry.key;
        final parentIcon = entry.value['icon'] as String? ?? "category";
        addCandidate(parentIcon, parentName, [parentName]);
        final children = entry.value['children'] as List<dynamic>? ?? const [];
        for (final child in children) {
          final name = (child['name'] as String? ?? "").trim();
          final icon = child['icon'] as String? ?? "category";
          if (name.isEmpty) continue;
          addCandidate(icon, name, [name, parentName]);
        }
      }
    }

    addLibrary(kSystemExpenseLibrary);
    addLibrary(kSystemIncomeLibrary);

    for (final entry in categoryIconEntries) {
      addCandidate(entry.name, entry.name, entry.keywords);
    }

    final candidates = <_IconCandidate>[];
    for (final iconEntry in keywordsByIcon.entries) {
      final iconName = iconEntry.key;
      final label = labelByIcon[iconName] ?? iconName;
      final entry = CategoryIconEntry(label, iconEntry.value.toList());
      candidates.add(_IconCandidate(iconName: iconName, entry: entry));
    }

    if (!_hasIcon(candidates, _selectedIcon)) {
      final fallbackLabel = _fallbackLabel(_selectedIcon);
      candidates.insert(
        0,
        _IconCandidate(
          iconName: _selectedIcon,
          entry: CategoryIconEntry(fallbackLabel, [fallbackLabel]),
        ),
      );
    }

    candidates.sort((a, b) => a.entry.name.compareTo(b.entry.name));
    return candidates;
  }

  bool _hasIcon(List<_IconCandidate> candidates, String iconName) {
    return candidates.any((candidate) => candidate.iconName == iconName);
  }

  String _fallbackLabel(String iconName) {
    if (iconName.startsWith("text:")) {
      final text = iconName.substring("text:".length).trim();
      return text.isEmpty ? "文字图标" : text;
    }
    if (iconName.startsWith("file:")) {
      return "自定义图片";
    }
    return iconName;
  }
}
