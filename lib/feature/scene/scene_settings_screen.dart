import 'package:flutter/material.dart';

import '../../core/model/scene.dart';
import '../../core/service/scene_service.dart';

/// Full-page settings screen for editing a single Scene's details and
/// preferences.
class SceneSettingsScreen extends StatefulWidget {
  final SceneService sceneService;
  final Scene scene;

  const SceneSettingsScreen({
    super.key,
    required this.sceneService,
    required this.scene,
  });

  @override
  State<SceneSettingsScreen> createState() => _SceneSettingsScreenState();
}

class _SceneSettingsScreenState extends State<SceneSettingsScreen> {
  late TextEditingController _nameCtrl;
  late String? _emoji;
  late String? _accentColor;
  late bool _showBudget;
  late bool _showGoals;
  late bool _isShared;

  static const _accentColors = [
    'FF5722',
    'E91E63',
    '9C27B0',
    '3F51B5',
    '2196F3',
    '009688',
    '4CAF50',
    'FFC107',
    'FF9800',
    '795548',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.scene.name);
    _emoji = widget.scene.emoji;
    _accentColor = widget.scene.accentColorHex;
    _showBudget = widget.scene.showBudgetOnHome;
    _showGoals = widget.scene.showGoalsOnHome;
    _isShared = widget.scene.isShared;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('场景设置'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // --- Name + Emoji ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickEmoji,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _emoji ?? '📖',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '场景名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // --- Default categories ---
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('默认分类筛选'),
            subtitle: Text(
              widget.scene.defaultCategoryKeys.isEmpty
                  ? '全部分类'
                  : '${widget.scene.defaultCategoryKeys.length} 个分类',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to category checklist picker
            },
          ),

          // --- Default tags ---
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('默认标签'),
            subtitle: Text(
              widget.scene.defaultTagKeys.isEmpty
                  ? '无默认标签'
                  : '${widget.scene.defaultTagKeys.length} 个标签',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to tag picker
            },
          ),

          const Divider(),

          // --- UI Preferences ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('首页显示',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ),

          SwitchListTile(
            title: const Text('显示预算状态'),
            subtitle: const Text('在首页展示该场景的预算进度'),
            value: _showBudget,
            onChanged: (v) => setState(() => _showBudget = v),
          ),

          SwitchListTile(
            title: const Text('显示目标进度'),
            subtitle: const Text('在首页展示该场景的储蓄目标'),
            value: _showGoals,
            onChanged: (v) => setState(() => _showGoals = v),
          ),

          const Divider(),

          // --- Accent color ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('主题色',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _accentColors.map((hex) {
                final color = Color(int.parse('FF$hex', radix: 16));
                final isSelected = _accentColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _accentColor = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // --- Share toggle ---
          SwitchListTile(
            title: const Text('共享账本'),
            subtitle: const Text('将此场景关联为共享账本'),
            value: _isShared,
            onChanged: (v) => setState(() => _isShared = v),
          ),

          const Divider(),

          // --- Delete ---
          if (!widget.scene.isDefault)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('删除场景',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _pickEmoji() {
    // Simplified emoji picker — show a few common options.
    final emojis = [
      '\u{1F3E0}', '\u{2708}\u{FE0F}', '\u{1F3D7}\u{FE0F}',
      '\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}', '\u{1F43E}',
      '\u{1F4BB}', '\u{1F393}', '\u{1F3AE}', '\u{1F4B0}', '\u{2615}',
      '\u{1F3CB}\u{FE0F}', '\u{1F697}',
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((e) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _emoji = e);
                    Navigator.pop(ctx);
                  },
                  child: Text(e, style: const TextStyle(fontSize: 32)),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    await widget.sceneService.updateScenePrefs(
      widget.scene.bookId,
      showBudget: _showBudget,
      showGoals: _showGoals,
      accentColor: _accentColor,
      emoji: _emoji,
      isShared: _isShared,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('场景设置已保存')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除场景「${widget.scene.name}」吗？相关账本数据不会删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, true); // Signal deletion to caller
    }
  }
}
