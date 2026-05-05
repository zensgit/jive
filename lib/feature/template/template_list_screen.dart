import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/quick_action_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/quick_action_store_service.dart';
import '../category/category_icon_library.dart';
import '../quick_entry/quick_action_executor.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  static final _iconChoiceNames = _buildIconChoiceNames();
  static const _quickActionIconLabels = <String, String>{
    'local_grocery_store': '超市',
    'home': '家庭',
    'flight_takeoff': '出差',
    'fitness_center': '健身',
    'medical_services': '医疗',
    'credit_card': '信用卡',
    'swap_horiz': '转账',
    'payments': '收款',
  };
  static const _colorChoices = <String, Color>{
    '#2E7D32': Color(0xFF2E7D32),
    '#EF6C00': Color(0xFFEF6C00),
    '#1565C0': Color(0xFF1565C0),
    '#6A1B9A': Color(0xFF6A1B9A),
    '#C62828': Color(0xFFC62828),
    '#455A64': Color(0xFF455A64),
  };

  Isar? _isar;
  bool _isLoading = true;
  List<JiveQuickAction> _actions = [];

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() => _isLoading = true);

    final service = await _quickActionStore();
    final actions = await service.getRecords();

    if (!mounted) return;
    setState(() {
      _actions = actions;
      _isLoading = false;
    });
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Future<QuickActionStoreService> _quickActionStore() async {
    final isar = await _ensureIsar();
    return QuickActionStoreService(isar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快速动作'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: JiveTheme.surfaceWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _actions.isEmpty
          ? _buildEmptyState()
          : _buildActionList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '暂无快速动作',
            style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '在交易编辑器中点击"保存为快速动作"',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildActionList() {
    final visible = _actions.where((action) => action.showOnHome).toList();
    final hidden = _actions.where((action) => !action.showOnHome).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIntroCard(),
        _buildReorderableSection(
          title: '首页快速动作',
          subtitle: '拖拽右侧把手排序，会出现在首页和快记中心',
          actions: visible,
          showOnHome: true,
        ),
        const SizedBox(height: 12),
        _buildReorderableSection(
          title: '已隐藏',
          subtitle: '拖拽右侧把手排序，仍可通过 Deep Link 或快捷指令使用',
          actions: hidden,
          showOnHome: false,
        ),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: JiveTheme.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '快速动作会复用同一套 One Touch 执行协议：信息完整直接保存，缺金额轻确认，复杂交易进入编辑器。',
              style: GoogleFonts.lato(
                fontSize: 13,
                height: 1.35,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableSection({
    required String title,
    required String subtitle,
    required List<JiveQuickAction> actions,
    required bool showOnHome,
  }) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, subtitle),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: actions.length,
          onReorder: (oldIndex, newIndex) {
            _reorderSection(
              actions: actions,
              oldIndex: oldIndex,
              newIndex: newIndex,
              showOnHome: showOnHome,
            );
          },
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              action,
              key: ValueKey('quick_action_${action.stableId}'),
              dragHandle: ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    JiveQuickAction action, {
    required Key key,
    required Widget dragHandle,
  }) {
    final color = _actionColor(action);
    final icon = _actionIcon(action);

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _useAction(action),
        onLongPress: () => _showActionOptions(action),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (action.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: JiveTheme.primaryGreen,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            action.name,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_categoryLabel(action)} · ${_modeLabel(action.mode)} · 使用 ${action.usageCount} 次',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    action.defaultAmount != null
                        ? '¥${action.defaultAmount!.toStringAsFixed(2)}'
                        : '金额待输入',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: action.defaultAmount != null
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.showOnHome ? '首页显示' : '已隐藏',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: action.showOnHome
                          ? JiveTheme.primaryGreen
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              dragHandle,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reorderSection({
    required List<JiveQuickAction> actions,
    required int oldIndex,
    required int newIndex,
    required bool showOnHome,
  }) async {
    if (oldIndex == newIndex) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= actions.length) return;

    final ordered = List<JiveQuickAction>.from(actions);
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);

    final other = _actions
        .where((action) => action.showOnHome != showOnHome)
        .toList();
    setState(() {
      _actions = showOnHome ? [...ordered, ...other] : [...other, ...ordered];
    });

    final service = await _quickActionStore();
    await service.reorderActions(
      ordered.map((action) => action.stableId).toList(growable: false),
      showOnHome: showOnHome,
    );
    await _loadActions();
  }

  Future<void> _useAction(JiveQuickAction record) async {
    await QuickActionExecutor.execute(
      context,
      QuickActionStoreService.toQuickAction(record),
      onCompleted: () {
        if (!mounted) return;
        _loadActions();
        Navigator.maybePop(context, true);
      },
    );
  }

  void _showActionOptions(JiveQuickAction action) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                action.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(action.isPinned ? '取消置顶' : '置顶'),
              onTap: () async {
                Navigator.pop(context);
                final service = await _quickActionStore();
                await service.updatePresentation(
                  action.stableId,
                  isPinned: !action.isPinned,
                );
                _loadActions();
              },
            ),
            ListTile(
              leading: Icon(
                action.showOnHome
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              title: Text(action.showOnHome ? '从首页隐藏' : '显示在首页'),
              onTap: () async {
                Navigator.pop(context);
                final service = await _quickActionStore();
                await service.updatePresentation(
                  action.stableId,
                  showOnHome: !action.showOnHome,
                );
                _loadActions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('设置图标和颜色'),
              onTap: () {
                Navigator.pop(context);
                _showStylePicker(action);
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard_arrow_up),
              title: const Text('上移'),
              onTap: () async {
                Navigator.pop(context);
                final service = await _quickActionStore();
                await service.moveAction(action.stableId, -1);
                _loadActions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard_arrow_down),
              title: const Text('下移'),
              onTap: () async {
                Navigator.pop(context);
                final service = await _quickActionStore();
                await service.moveAction(action.stableId, 1);
                _loadActions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _confirmDelete(action);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStylePicker(JiveQuickAction action) {
    var selectedIcon = action.iconName ?? _defaultIconName(action);
    var selectedColor = action.colorHex ?? _defaultColorHex(action);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '设置「${action.name}」',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('图标', style: GoogleFonts.lato(fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _iconChoiceNames.map((iconName) {
                      final selected = selectedIcon == iconName;
                      return ChoiceChip(
                        selected: selected,
                        avatar: Icon(_iconData(iconName), size: 18),
                        label: Text(_iconLabel(iconName)),
                        onSelected: (_) {
                          setSheetState(() => selectedIcon = iconName);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('颜色', style: GoogleFonts.lato(fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: _colorChoices.entries.map((entry) {
                      final selected = selectedColor == entry.key;
                      return InkWell(
                        onTap: () {
                          setSheetState(() => selectedColor = entry.key);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: entry.value,
                            border: Border.all(
                              color: selected
                                  ? Colors.black87
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final service = await _quickActionStore();
                        await service.updatePresentation(
                          action.stableId,
                          iconName: selectedIcon,
                          colorHex: selectedColor,
                        );
                        _loadActions();
                      },
                      child: const Text('保存样式'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(JiveQuickAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除快速动作'),
        content: Text('确定删除快速动作「${action.name}」？关联的旧模板也会同步删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final service = await _quickActionStore();
    await service.deleteAction(action.stableId);
    _loadActions();
  }

  IconData _actionIcon(JiveQuickAction action) {
    final name = action.iconName ?? _defaultIconName(action);
    return _iconData(name);
  }

  Color _actionColor(JiveQuickAction action) {
    final hex = action.colorHex ?? _defaultColorHex(action);
    return _parseColor(hex) ?? _colorChoices[_defaultColorHex(action)]!;
  }

  String _defaultIconName(JiveQuickAction action) {
    if (action.transactionType == 'income') return 'payments';
    if (action.transactionType == 'transfer') return 'swap_horiz';
    return 'restaurant';
  }

  String _defaultColorHex(JiveQuickAction action) {
    if (action.transactionType == 'income') return '#2E7D32';
    if (action.transactionType == 'transfer') return '#455A64';
    return '#C62828';
  }

  Color? _parseColor(String hex) {
    final value = hex.replaceFirst('#', '');
    if (value.length != 6 && value.length != 8) return null;
    final parsed = int.tryParse(
      value.length == 6 ? 'FF$value' : value,
      radix: 16,
    );
    return parsed == null ? null : Color(parsed);
  }

  String _categoryLabel(JiveQuickAction action) {
    final names = [
      action.categoryName,
      action.subCategoryName,
    ].where((name) => name != null && name.trim().isNotEmpty).join(' / ');
    if (names.isNotEmpty) return names;
    if (action.transactionType == 'transfer') return '转账';
    return '未分类';
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'direct':
        return '直接保存';
      case 'confirm':
        return '轻确认';
      case 'edit':
        return '进编辑器';
      default:
        return '进编辑器';
    }
  }

  static List<String> _buildIconChoiceNames() {
    final names = <String>{
      for (final entry in categoryIconEntries) entry.name,
      ..._quickActionIconLabels.keys,
    };
    return names.toList(growable: false);
  }

  static IconData _iconData(String name) {
    switch (name) {
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'home':
        return Icons.home;
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'medical_services':
        return Icons.medical_services;
      case 'credit_card':
        return Icons.credit_card;
      case 'swap_horiz':
        return Icons.swap_horiz;
      default:
        return CategoryService.getIcon(name);
    }
  }

  static String _iconLabel(String name) {
    final label = _quickActionIconLabels[name];
    if (label != null) return label;
    for (final entry in categoryIconEntries) {
      if (entry.name != name || entry.keywords.isEmpty) continue;
      return entry.keywords.firstWhere(
        _containsChinese,
        orElse: () => entry.keywords.first,
      );
    }
    return name;
  }

  static bool _containsChinese(String value) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(value);
  }
}
