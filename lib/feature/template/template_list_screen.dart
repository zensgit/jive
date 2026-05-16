import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/quick_action_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_path_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/quick_action_filter_service.dart';
import '../../core/service/quick_action_store_service.dart';
import '../category/category_icon_library.dart';
import '../category/category_icon_source_picker.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final isSearching = _searchQuery.trim().isNotEmpty;
    final filtered = QuickActionFilterService.filterRecords(
      _actions,
      _searchQuery,
    );
    final visible = filtered.where((action) => action.showOnHome).toList();
    final hidden = filtered.where((action) => !action.showOnHome).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIntroCard(),
        _buildSearchField(
          totalCount: _actions.length,
          matchCount: filtered.length,
        ),
        if (filtered.isEmpty)
          _buildSearchEmptyState()
        else ...[
          _buildActionSection(
            title: '首页快速动作',
            subtitle: isSearching
                ? '搜索结果仅供查找，清空搜索后可拖拽排序'
                : '拖拽右侧把手排序，会出现在首页和快记中心',
            actions: visible,
            showOnHome: true,
            canReorder: !isSearching,
          ),
          const SizedBox(height: 12),
          _buildActionSection(
            title: '已隐藏',
            subtitle: isSearching
                ? '这些隐藏动作匹配当前搜索，可点按执行或长按管理'
                : '拖拽右侧把手排序，仍可通过 Deep Link 或快捷指令使用',
            actions: hidden,
            showOnHome: false,
            canReorder: !isSearching,
          ),
        ],
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

  Widget _buildSearchField({required int totalCount, required int matchCount}) {
    final isSearching = _searchQuery.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        key: const ValueKey('quick_action_search_field'),
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索名称、分类、金额或模式',
          hintStyle: GoogleFonts.lato(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon: isSearching
              ? IconButton(
                  tooltip: '清空搜索',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '$totalCount',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
          helperText: isSearching ? '匹配 $matchCount / $totalCount 个快速动作' : null,
          helperStyle: GoogleFonts.lato(fontSize: 11, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.manage_search, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            '没有找到匹配的快速动作',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '试试搜索名称、分类、金额、备注、直接保存或轻确认',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection({
    required String title,
    required String subtitle,
    required List<JiveQuickAction> actions,
    required bool showOnHome,
    required bool canReorder,
  }) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, subtitle),
        if (canReorder)
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
          )
        else
          Column(
            children: actions
                .map(
                  (action) => _buildActionCard(
                    action,
                    key: ValueKey('quick_action_${action.stableId}'),
                    dragHandle: const SizedBox(width: 28),
                  ),
                )
                .toList(growable: false),
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
    final iconName = action.iconName ?? _defaultIconName(action);

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
                child: _buildIconPreview(iconName, size: 20, color: color),
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
              leading: const Icon(Icons.edit_note_outlined),
              title: const Text('编辑内容'),
              subtitle: const Text('名称、金额、账户、分类和备注'),
              onTap: () {
                Navigator.pop(context);
                _showCoreFieldEditor(action);
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

  Future<void> _showCoreFieldEditor(JiveQuickAction action) async {
    final isar = await _ensureIsar();
    final accounts = await isar.jiveAccounts.where().findAll();
    final categories = await isar.jiveCategorys.where().findAll();
    if (!mounted) return;

    final nameController = TextEditingController(text: action.name);
    final amountController = TextEditingController(
      text: action.defaultAmount == null
          ? ''
          : action.defaultAmount!.toStringAsFixed(2),
    );
    final noteController = TextEditingController(
      text: action.defaultNote ?? '',
    );
    var selectedType = action.transactionType;
    var selectedAccountId = action.accountId;
    var selectedToAccountId = action.toAccountId;
    var selectedCategoryLeafKey = action.subCategoryKey ?? action.categoryKey;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final isTransfer = selectedType == 'transfer';
          final categoryPaths = isTransfer
              ? const <CategoryPath>[]
              : const CategoryPathService().visiblePaths(
                  categories,
                  isIncome: selectedType == 'income',
                );
          CategoryPath? selectedPath;
          for (final path in categoryPaths) {
            if (path.leafKey == selectedCategoryLeafKey) {
              selectedPath = path;
              break;
            }
          }
          final accountIds = accounts.map((account) => account.id).toSet();
          final accountValue = accountIds.contains(selectedAccountId)
              ? selectedAccountId
              : null;
          final toAccountValue =
              accountIds.contains(selectedToAccountId) &&
                  selectedToAccountId != selectedAccountId
              ? selectedToAccountId
              : null;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '编辑「${action.name}」',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: '类型',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('支出')),
                      DropdownMenuItem(value: 'income', child: Text('收入')),
                      DropdownMenuItem(value: 'transfer', child: Text('转账')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() {
                        selectedType = value;
                        if (selectedType == 'transfer') {
                          selectedCategoryLeafKey = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: '默认金额（留空则轻确认）',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: accountValue,
                    decoration: const InputDecoration(
                      labelText: '账户',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('未选择'),
                    items: accounts
                        .map(
                          (account) => DropdownMenuItem<int>(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        setSheetState(() => selectedAccountId = value),
                  ),
                  if (isTransfer) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: toAccountValue,
                      decoration: const InputDecoration(
                        labelText: '转入账户',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('未选择'),
                      items: accounts
                          .where((account) => account.id != selectedAccountId)
                          .map(
                            (account) => DropdownMenuItem<int>(
                              value: account.id,
                              child: Text(account.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setSheetState(() => selectedToAccountId = value),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPath?.leafKey,
                      decoration: const InputDecoration(
                        labelText: '分类',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('未选择'),
                      items: categoryPaths
                          .map(
                            (path) => DropdownMenuItem<String>(
                              value: path.leafKey,
                              child: Text(path.displayName),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setSheetState(() => selectedCategoryLeafKey = value),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: '默认备注',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('请输入快速动作名称')),
                          );
                          return;
                        }
                        final amountText = amountController.text.trim();
                        final amount = amountText.isEmpty
                            ? null
                            : double.tryParse(amountText);
                        final categoryKeys =
                            selectedType == 'transfer' || selectedPath == null
                            ? null
                            : const CategoryPathService().toTransactionKeys(
                                categories,
                                selectedPath.leaf,
                              );
                        Navigator.pop(sheetContext);
                        final service = await _quickActionStore();
                        await service.updateCoreFields(
                          action.stableId,
                          name: name,
                          transactionType: selectedType,
                          accountId: accountValue,
                          toAccountId: toAccountValue,
                          categoryKey: categoryKeys?.categoryKey,
                          subCategoryKey: categoryKeys?.subCategoryKey,
                          categoryName: categoryKeys?.categoryName,
                          subCategoryName: categoryKeys?.subCategoryName,
                          defaultAmount: amount,
                          defaultNote: noteController.text,
                        );
                        await _loadActions();
                      },
                      child: const Text('保存内容'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    nameController.dispose();
    amountController.dispose();
    noteController.dispose();
  }

  void _showStylePicker(JiveQuickAction action) {
    var selectedIcon = action.iconName ?? _defaultIconName(action);
    var selectedColor = action.colorHex ?? _defaultColorHex(action);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
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
                    Row(
                      children: [
                        Text('图标', style: GoogleFonts.lato(fontSize: 13)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _pickAndSaveCustomIcon(
                                action,
                                initialIcon: selectedIcon,
                                colorHex: selectedColor,
                              );
                            });
                          },
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('更多图标'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '可选系统图标、表情、文字或本机图片；本机图片仅保存在当前设备。',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (!_isPresetIcon(selectedIcon))
                          ChoiceChip(
                            selected: true,
                            avatar: _buildIconPreview(
                              selectedIcon,
                              size: 18,
                              color: JiveTheme.primaryGreen,
                            ),
                            label: Text(_customIconLabel(selectedIcon)),
                            onSelected: (_) {},
                          ),
                        ..._iconChoiceNames.map((iconName) {
                          final selected = selectedIcon == iconName;
                          return ChoiceChip(
                            selected: selected,
                            avatar: _buildIconPreview(
                              iconName,
                              size: 18,
                              color: selected
                                  ? JiveTheme.primaryGreen
                                  : Colors.grey.shade700,
                            ),
                            label: Text(_iconLabel(iconName)),
                            onSelected: (_) {
                              setSheetState(() => selectedIcon = iconName);
                            },
                          );
                        }),
                      ],
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
                          Navigator.pop(sheetContext);
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndSaveCustomIcon(
    JiveQuickAction action, {
    required String initialIcon,
    required String colorHex,
  }) async {
    final picked = await pickCategoryIcon(
      context,
      initialIcon: initialIcon,
      forceTinted: true,
    );
    if (picked == null) return;
    if (!mounted) return;
    final service = await _quickActionStore();
    await service.updatePresentation(
      action.stableId,
      iconName: picked,
      colorHex: colorHex,
    );
    await _loadActions();
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

  static Widget _buildIconPreview(
    String iconName, {
    required double size,
    required Color color,
  }) {
    if (_quickActionIconLabels.containsKey(iconName)) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(_iconData(iconName), size: size, color: color),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: CategoryService.buildIcon(
        iconName,
        size: size,
        color: color,
        forceTinted: true,
      ),
    );
  }

  static bool _isPresetIcon(String iconName) {
    return _iconChoiceNames.contains(iconName);
  }

  static String _customIconLabel(String iconName) {
    if (iconName.startsWith('emoji:')) return '表情';
    if (iconName.startsWith('file:')) return '图片';
    if (iconName.startsWith('text:')) return '文字';
    if (iconName.startsWith('assets/')) return '图标';
    return '自定义';
  }
}
