import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_rule_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/service/database_service.dart';
import '../../core/service/smart_tag_log_service.dart';
import '../../core/service/tag_rule_service.dart';
import '../../core/service/ui_pref_service.dart';
import '../../core/widgets/date_range_picker_sheet.dart';
import 'smart_tag_recent_matches_screen.dart';
import 'tag_icon_catalog.dart';

class TagRuleScreen extends StatefulWidget {
  final JiveTag tag;
  final Isar? isar;

  const TagRuleScreen({
    super.key,
    required this.tag,
    this.isar,
  });

  @override
  State<TagRuleScreen> createState() => _TagRuleScreenState();
}

class _TagRuleScreenState extends State<TagRuleScreen> {
  late Isar _isar;
  bool _loading = true;
  String? _error;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  bool _backfilling = false;
  bool _cancelBackfill = false;
  int _backfillProcessed = 0;
  int _backfillTotal = 0;
  final ValueNotifier<int> _progressTick = ValueNotifier<int>(0);
  BuildContext? _progressDialogContext;
  bool _cleaning = false;
  bool _cancelCleanup = false;
  int _cleanupProcessed = 0;
  int _cleanupTotal = 0;
  final ValueNotifier<int> _cleanupTick = ValueNotifier<int>(0);
  BuildContext? _cleanupDialogContext;
  bool _cleanupRemoveTagTooDefault = false;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final ScrollController _titleScrollController = ScrollController();
  bool _titleScrollScheduled = false;
  int _titleScrollGeneration = 0;
  List<JiveTagRule> _rules = [];
  Map<int, JiveAccount> _accountById = {};
  Map<String, JiveCategory> _categoryByKey = {};
  Map<String, List<JiveCategory>> _childrenByParent = {};
  _RuleSort _sort = _RuleSort.updatedDesc;
  _RuleFilter _filter = _RuleFilter.all;

  @override
  void initState() {
    super.initState();
    _loadCleanupPref();
    _init();
  }

  @override
  void dispose() {
    _titleScrollGeneration++;
    _titleScrollController.dispose();
    _progressTick.dispose();
    _cleanupTick.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleTitleScroll() {
    if (_titleScrollScheduled) return;
    _titleScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleScrollScheduled = false;
      _startTitleScroll();
    });
  }

  Future<void> _startTitleScroll() async {
    if (!mounted || !_titleScrollController.hasClients) return;
    final maxExtent = _titleScrollController.position.maxScrollExtent;
    if (maxExtent <= 8) return;
    final generation = ++_titleScrollGeneration;
    await Future.delayed(const Duration(milliseconds: 600));
    const pixelsPerSecond = 40.0;
    while (mounted && generation == _titleScrollGeneration) {
      if (!_titleScrollController.hasClients) return;
      final max = _titleScrollController.position.maxScrollExtent;
      if (max <= 8) return;
      final durationMs = (max / pixelsPerSecond * 1000).clamp(1200, 8000).round();
      final duration = Duration(milliseconds: durationMs);
      try {
        await _titleScrollController.animateTo(
          max,
          duration: duration,
          curve: Curves.easeInOut,
        );
        if (!mounted || generation != _titleScrollGeneration) return;
        await Future.delayed(const Duration(milliseconds: 700));
        await _titleScrollController.animateTo(
          0,
          duration: duration,
          curve: Curves.easeInOut,
        );
        if (!mounted || generation != _titleScrollGeneration) return;
        await Future.delayed(const Duration(milliseconds: 700));
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _init() async {
    try {
      _isar = widget.isar ?? await DatabaseService.getInstance();
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadCleanupPref() async {
    final value = await UiPrefService.getSmartCleanupRemoveTagToo();
    if (!mounted) return;
    setState(() => _cleanupRemoveTagTooDefault = value);
  }

  Future<void> _loadData() async {
    final service = TagRuleService(_isar);
    final rules = await service.getRules(widget.tag.key);

    final accounts = await AccountService(_isar).getActiveAccounts();
    final accountMap = {for (final account in accounts) account.id: account};

    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final cat in categories) cat.key: cat};
    final childrenByParent = <String, List<JiveCategory>>{};
    for (final cat in categories) {
      final parent = cat.parentKey;
      if (parent == null) continue;
      childrenByParent.putIfAbsent(parent, () => []).add(cat);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }

    if (!mounted) return;
    setState(() {
      _rules = rules;
      _accountById = accountMap;
      _categoryByKey = categoryMap;
      _childrenByParent = childrenByParent;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _toggleRule(JiveTagRule rule, bool enabled) async {
    if (!enabled && _isLastEnabledRule(rule)) {
      final action = await _confirmDisableLastRule();
      if (action == _DisableAllAction.cancel) return;
      rule.isEnabled = false;
      await TagRuleService(_isar).updateRule(rule);
      await _loadData();
      DataReloadBus.notify();
      if (action == _DisableAllAction.disableAndCleanup) {
        await _cleanupHistory();
      }
      return;
    }
    rule.isEnabled = enabled;
    await TagRuleService(_isar).updateRule(rule);
    await _loadData();
    DataReloadBus.notify();
  }

  Future<void> _editRule({JiveTagRule? rule}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TagRuleEditSheet(
          isar: _isar,
          tag: widget.tag,
          rule: rule,
          accounts: _accountById,
          categoryByKey: _categoryByKey,
          childrenByParent: _childrenByParent,
        );
      },
    );
    if (result == true) {
      await _loadData();
      DataReloadBus.notify();
    }
  }

  Future<void> _deleteRule(JiveTagRule rule) async {
    final willDisableAll = _isLastEnabledRule(rule);
    final action = await showDialog<_DeleteAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除规则'),
          content: Text(
            willDisableAll
                ? '删除后将没有启用中的规则，该标签不会再自动打标。是否同时清理历史智能标签？'
                : '确认删除该标签规则？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, _DeleteAction.cancel),
              child: const Text('取消'),
            ),
            if (willDisableAll)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, _DeleteAction.deleteOnly),
                child: const Text('仅删除'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                willDisableAll ? _DeleteAction.deleteAndCleanup : _DeleteAction.deleteOnly,
              ),
              child: Text(willDisableAll ? '删除并清理' : '删除'),
            ),
          ],
        );
      },
    );
    if (action == null || action == _DeleteAction.cancel) return;
    await TagRuleService(_isar).deleteRule(rule);
    await _loadData();
    DataReloadBus.notify();
    if (willDisableAll && action == _DeleteAction.deleteAndCleanup) {
      await _cleanupHistory();
    }
  }

  bool _isLastEnabledRule(JiveTagRule rule) {
    if (!rule.isEnabled) return false;
    return !_rules.any((r) => r.id != rule.id && r.isEnabled);
  }

  Future<_DisableAllAction> _confirmDisableLastRule() async {
    final action = await showDialog<_DisableAllAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('停用规则'),
        content: const Text('停用后将没有启用中的规则，该标签不会再自动打标。是否同时清理历史智能标签？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _DisableAllAction.cancel),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _DisableAllAction.disableOnly),
            child: const Text('仅停用'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _DisableAllAction.disableAndCleanup),
            child: const Text('停用并清理'),
          ),
        ],
      ),
    );
    return action ?? _DisableAllAction.cancel;
  }

  @override
  Widget build(BuildContext context) {
    final visibleRules = _applyFilterAndSort(_rules);
    final busy = _backfilling || _cleaning;
    final tagName = tagDisplayName(widget.tag);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final appBarBottomHeight = isLandscape ? 86.0 : 118.0;
    _scheduleTitleScroll();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 24,
              child: SingleChildScrollView(
                controller: _titleScrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '智能标签 · $tagName',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(appBarBottomHeight),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, isLandscape ? 0 : 4),
                child: _buildActionRow(busy),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, isLandscape ? 6 : 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _query = value.trim());
                  },
                  decoration: InputDecoration(
                    hintText: '搜索规则（关键词/分类/账户）',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _rules.isEmpty
                  ? _buildEmpty()
                  : Column(
                      children: [
                        _buildFilterBar(isLandscape: isLandscape),
                        Expanded(
                          child: visibleRules.isEmpty
                              ? _buildEmptySearch()
                              : ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    isLandscape ? 12 : 24,
                                  ),
                                  itemCount: visibleRules.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildRuleCard(visibleRules[index]),
                                ),
                        ),
                      ],
                    ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, isLandscape ? 4 : 8, 16, isLandscape ? 8 : 16),
          child: ElevatedButton.icon(
            onPressed: _loading ? null : () => _editRule(),
            icon: const Icon(Icons.add),
            label: const Text('新增规则'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 12),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(bool busy) {
    const accent = Color(0xFF2E7D32);

    Widget toolButton({
      required IconData icon,
      required String label,
      required VoidCallback? onPressed,
    }) {
      final enabled = onPressed != null;
      final fg = enabled ? accent : Colors.grey.shade500;
      return Tooltip(
        message: label,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: fg,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    Widget sortPill() {
      return PopupMenuButton<_RuleSort>(
        tooltip: '排序',
        enabled: !busy,
        onSelected: (value) => setState(() => _sort = value),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _RuleSort.updatedDesc,
            child: Text('最近更新'),
          ),
          PopupMenuItem(
            value: _RuleSort.createdDesc,
            child: Text('最近创建'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort, size: 16, color: busy ? Colors.grey.shade500 : accent),
              const SizedBox(width: 4),
              Text(
                '排序',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: busy ? Colors.grey.shade500 : accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final refreshPressed = busy
        ? null
        : () async {
            await _loadData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已更新规则')),
            );
          };

    final recentPressed = busy
        ? null
        : () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SmartTagRecentMatchesScreen(
                  tag: widget.tag,
                  isar: _isar,
                ),
              ),
            );
            if (!mounted) return;
            await _loadData();
          };

    Widget divider() {
      return Container(
        width: 1,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: Colors.grey.shade300,
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            toolButton(
              icon: Icons.refresh,
              label: '更新',
              onPressed: refreshPressed,
            ),
            divider(),
            toolButton(
              icon: Icons.history_toggle_off,
              label: '命中',
              onPressed: recentPressed,
            ),
            divider(),
            toolButton(
              icon: Icons.auto_fix_high,
              label: '补标',
              onPressed: busy || _rules.isEmpty ? null : _backfillHistory,
            ),
            divider(),
            toolButton(
              icon: Icons.cleaning_services_outlined,
              label: '清理',
              onPressed: busy ? null : _cleanupHistory,
            ),
            divider(),
            sortPill(),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(left: 4, right: 6),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _backfillHistory() async {
    if (_backfilling || _rules.isEmpty) return;
    final range = await _pickBackfillRange();
    if (range == null) return;
    final rangeLabel = _rangeLabel(range);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('补标历史交易'),
        content: Text('将根据当前规则为历史交易补充标签（$rangeLabel），仅对尚未包含该标签的交易生效。是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _backfilling = true;
      _cancelBackfill = false;
      _backfillProcessed = 0;
      _backfillTotal = 0;
    });
    _showBackfillProgress();
    try {
      final result = await TagRuleService(_isar).backfillForTag(
        widget.tag.key,
        rangeStart: range.start,
        rangeEnd: range.end,
        shouldCancel: () => _cancelBackfill,
        onProgress: (processed, total) {
          if (!mounted) return;
          setState(() {
            _backfillProcessed = processed;
            _backfillTotal = total;
          });
          _progressTick.value = _progressTick.value + 1;
        },
      );
      if (!mounted) return;
      final message = result.cancelled
          ? '已取消补标（已处理 ${result.scannedCount} 笔）'
          : result.updatedCount == 0
              ? '没有需要补标的交易'
              : '已补标 ${result.updatedCount} 笔交易（匹配 ${result.matchedCount}/${result.scannedCount}）';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await SmartTagLogService().addLog(
        SmartTagLogEntry(
          tagKey: widget.tag.key,
          tagName: widget.tag.name,
          scannedCount: result.scannedCount,
          matchedCount: result.matchedCount,
          updatedCount: result.updatedCount,
          skippedCount: result.skippedCount,
          cancelled: result.cancelled,
          success: true,
          message: message,
          rangeStart: range.start,
          rangeEnd: range.end,
          createdAt: DateTime.now(),
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      final errorMessage = '补标失败：$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      await SmartTagLogService().addLog(
        SmartTagLogEntry(
          tagKey: widget.tag.key,
          tagName: widget.tag.name,
          scannedCount: 0,
          matchedCount: 0,
          updatedCount: 0,
          skippedCount: 0,
          cancelled: false,
          success: false,
          message: errorMessage,
          rangeStart: range.start,
          rangeEnd: range.end,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      if (mounted) {
        if (_progressDialogContext != null) {
          Navigator.pop(_progressDialogContext!);
        }
        setState(() => _backfilling = false);
      }
    }
  }

  Future<void> _cleanupHistory() async {
    if (_cleaning || _backfilling) return;
    final range = await _pickBackfillRange();
    if (range == null) return;
    final rangeLabel = _rangeLabel(range);
    final service = TagRuleService(_isar);
    var removeTagToo = _cleanupRemoveTagTooDefault;
    var estimate = await service.estimateCleanupForTag(
      widget.tag.key,
      rangeStart: range.start,
      rangeEnd: range.end,
      removeTagToo: removeTagToo,
    );
    var estimating = false;

    Future<void> refreshEstimate(void Function(void Function()) setDialogState) async {
      setDialogState(() => estimating = true);
      final next = await service.estimateCleanupForTag(
        widget.tag.key,
        rangeStart: range.start,
        rangeEnd: range.end,
        removeTagToo: removeTagToo,
      );
      if (!mounted) return;
      setDialogState(() {
        estimate = next;
        estimating = false;
      });
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('清理历史智能标签'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('范围：$rangeLabel'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('同时移除标签'),
                    subtitle: const Text('仅对智能打标的交易生效'),
                    value: removeTagToo,
                    onChanged: (value) async {
                      removeTagToo = value;
                      _cleanupRemoveTagTooDefault = value;
                      await UiPrefService.setSmartCleanupRemoveTagToo(value);
                      await refreshEstimate(setDialogState);
                    },
                    activeThumbColor: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 6),
                  if (estimating)
                    const LinearProgressIndicator()
                  else
                    Text(
                      estimate.smartTaggedCount == 0
                          ? '该范围内没有需要清理的智能标签'
                          : '扫描 ${estimate.scannedCount} 笔，智能标签 ${estimate.smartTaggedCount} 笔；'
                              '预计清理智能标记 ${estimate.willRemoveSmartCount} 笔，'
                              '${removeTagToo ? '移除标签 ${estimate.willRemoveTagCount} 笔' : '保留原标签'}。',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: estimating || estimate.smartTaggedCount == 0
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('执行清理'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;

    setState(() {
      _cleaning = true;
      _cancelCleanup = false;
      _cleanupProcessed = 0;
      _cleanupTotal = 0;
    });
    _showCleanupProgress();
    try {
      final result = await service.cleanupForTag(
        widget.tag.key,
        rangeStart: range.start,
        rangeEnd: range.end,
        removeTagToo: removeTagToo,
        shouldCancel: () => _cancelCleanup,
        onProgress: (processed, total) {
          if (!mounted) return;
          setState(() {
            _cleanupProcessed = processed;
            _cleanupTotal = total;
          });
          _cleanupTick.value = _cleanupTick.value + 1;
        },
      );
      if (!mounted) return;
      final message = result.cancelled
          ? '已取消清理（已处理 ${result.scannedCount} 笔）'
          : result.updatedCount == 0
              ? '没有需要清理的智能标签'
              : removeTagToo
                  ? '已清理智能标签 ${result.updatedCount} 笔，移除标签 ${result.removedTagCount} 笔'
                  : '已清理智能标签 ${result.updatedCount} 笔';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await SmartTagLogService().addLog(
        SmartTagLogEntry(
          tagKey: widget.tag.key,
          tagName: widget.tag.name,
          scannedCount: result.scannedCount,
          matchedCount: result.smartTaggedCount,
          updatedCount: result.updatedCount,
          skippedCount: result.smartTaggedCount > result.updatedCount
              ? result.smartTaggedCount - result.updatedCount
              : 0,
          cancelled: result.cancelled,
          success: true,
          message: '清理：$message',
          rangeStart: range.start,
          rangeEnd: range.end,
          createdAt: DateTime.now(),
        ),
      );
      await _loadData();
      DataReloadBus.notify();
    } catch (e) {
      if (!mounted) return;
      final errorMessage = '清理失败：$e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      await SmartTagLogService().addLog(
        SmartTagLogEntry(
          tagKey: widget.tag.key,
          tagName: widget.tag.name,
          scannedCount: 0,
          matchedCount: 0,
          updatedCount: 0,
          skippedCount: 0,
          cancelled: false,
          success: false,
          message: errorMessage,
          rangeStart: range.start,
          rangeEnd: range.end,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      if (mounted) {
        if (_cleanupDialogContext != null) {
          Navigator.pop(_cleanupDialogContext!);
        }
        setState(() => _cleaning = false);
      }
    }
  }

  void _showBackfillProgress() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _progressDialogContext = dialogContext;
        return ValueListenableBuilder<int>(
          valueListenable: _progressTick,
          builder: (context, _, __) {
            final total = _backfillTotal;
            final processed = _backfillProcessed;
            final progress = total == 0 ? null : processed / total;
            return AlertDialog(
              title: const Text('正在补标'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(
                    total == 0 ? '准备中...' : '已处理 $processed / $total',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _cancelBackfill = true;
                    _progressDialogContext = null;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      _progressDialogContext = null;
      if (mounted) {
        setState(() {
          _backfillProcessed = 0;
          _backfillTotal = 0;
        });
      }
    });
  }

  void _showCleanupProgress() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _cleanupDialogContext = dialogContext;
        return ValueListenableBuilder<int>(
          valueListenable: _cleanupTick,
          builder: (context, _, __) {
            final total = _cleanupTotal;
            final processed = _cleanupProcessed;
            final progress = total == 0 ? null : processed / total;
            return AlertDialog(
              title: const Text('正在清理'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(total == 0 ? '准备中...' : '已处理 $processed / $total'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _cancelCleanup = true;
                    _cleanupDialogContext = null;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      _cleanupDialogContext = null;
      if (mounted) {
        setState(() {
          _cleanupProcessed = 0;
          _cleanupTotal = 0;
        });
      }
    });
  }

  Future<_BackfillRange?> _pickBackfillRange() async {
    return showModalBottomSheet<_BackfillRange>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部时间'),
              onTap: () => Navigator.pop(context, const _BackfillRange()),
            ),
            ListTile(
              title: const Text('近 7 天'),
              onTap: () => Navigator.pop(context, _lastDaysRange(7)),
            ),
            ListTile(
              title: const Text('近 30 天'),
              onTap: () => Navigator.pop(context, _lastDaysRange(30)),
            ),
            ListTile(
              title: const Text('选择日期范围'),
              onTap: () async {
                final now = DateTime.now();
                final lastDate = DateTime(now.year, now.month, now.day);
                DateTimeRange? picked;
                var didChange = false;
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return DateRangePickerSheet(
                      initialRange: null,
                      firstDay: DateTime(now.year - 5, 1, 1),
                      lastDay: lastDate,
                      minSelectableDay: DateTime(now.year - 5, 1, 1),
                      maxSelectableDay: lastDate,
                      bottomLabel: '选择补标时间范围',
                      onChanged: (range) {
                        didChange = true;
                        picked = range;
                      },
                    );
                  },
                );
                if (!didChange || picked == null) return;
                final start = DateTime(
                  picked!.start.year,
                  picked!.start.month,
                  picked!.start.day,
                );
                final end = DateTime(
                  picked!.end.year,
                  picked!.end.month,
                  picked!.end.day,
                  23,
                  59,
                  59,
                  999,
                );
                if (!context.mounted) return;
                Navigator.pop(context, _BackfillRange(start: start, end: end));
              },
            ),
          ],
        ),
      ),
    );
  }

  _BackfillRange _lastDaysRange(int days) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final start = todayStart.subtract(Duration(days: days - 1));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return _BackfillRange(start: start, end: end);
  }

  String _rangeLabel(_BackfillRange range) {
    if (range.start == null && range.end == null) return '全部时间';
    final start = range.start == null ? '不限' : _dateFormat.format(range.start!);
    final end = range.end == null ? '不限' : _dateFormat.format(range.end!);
    return '$start ~ $end';
  }

  Widget _buildFilterBar({required bool isLandscape}) {
    final total = _rules.length;
    final enabled = _rules.where((rule) => rule.isEnabled).length;
    final disabled = total - enabled;
    final selectedColor = const Color(0xFF2E7D32);
    final textStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isLandscape ? 4 : 10, 16, isLandscape ? 0 : 4),
      child: Row(
        children: [
          ChoiceChip(
            label: Text('全部 $total', style: textStyle),
            selected: _filter == _RuleFilter.all,
            selectedColor: selectedColor.withValues(alpha: 0.15),
            onSelected: (_) => setState(() => _filter = _RuleFilter.all),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('启用 $enabled', style: textStyle),
            selected: _filter == _RuleFilter.enabled,
            selectedColor: selectedColor.withValues(alpha: 0.15),
            onSelected: (_) => setState(() => _filter = _RuleFilter.enabled),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('停用 $disabled', style: textStyle),
            selected: _filter == _RuleFilter.disabled,
            selectedColor: selectedColor.withValues(alpha: 0.15),
            onSelected: (_) => setState(() => _filter = _RuleFilter.disabled),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('暂无智能规则', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('新增规则后，仅对新增交易生效', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('没有匹配的规则', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildRuleCard(JiveTagRule rule) {
    final lines = _buildRuleSummary(rule);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rule.isEnabled ? '已启用' : '已关闭',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: rule.isEnabled ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Switch(
                value: rule.isEnabled,
                onChanged: (value) => _toggleRule(rule, value),
                activeThumbColor: const Color(0xFF2E7D32),
              ),
              IconButton(
                onPressed: () => _editRule(rule: rule),
                icon: const Icon(Icons.edit, size: 20),
              ),
              IconButton(
                onPressed: () => _deleteRule(rule),
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  List<String> _buildRuleSummary(JiveTagRule rule) {
    final lines = <String>[];
    final type = _typeLabel(rule.applyType);
    if (type != null) lines.add('类型：$type');
    if (rule.minAmount != null || rule.maxAmount != null) {
      lines.add('金额：${_amountRange(rule.minAmount, rule.maxAmount)}');
    }
    if (rule.accountIds.isNotEmpty) {
      final names = rule.accountIds
          .map((id) => _accountById[id]?.name ?? '未知账户')
          .toList();
      lines.add('账户：${names.join('、')}');
    }
    if (rule.categoryKey != null || rule.subCategoryKey != null) {
      final parent = rule.categoryKey == null ? null : _categoryByKey[rule.categoryKey!];
      final child = rule.subCategoryKey == null ? null : _categoryByKey[rule.subCategoryKey!];
      if (parent != null && child != null) {
        lines.add('分类：${parent.name} / ${child.name}');
      } else if (parent != null) {
        lines.add('分类：${parent.name}');
      } else if (child != null) {
        lines.add('分类：${child.name}');
      }
    }
    if (rule.keywords.isNotEmpty) {
      lines.add('关键词：${rule.keywords.join('、')}');
    }
    if (lines.isEmpty) {
      lines.add('未设置过滤条件（将匹配全部新交易）');
    }
    return lines;
  }

  List<JiveTagRule> _applyFilterAndSort(List<JiveTagRule> source) {
    var filtered = _query.isEmpty
        ? List<JiveTagRule>.from(source)
        : source.where((rule) => _ruleSearchText(rule).contains(_query.toLowerCase())).toList();
    if (_filter == _RuleFilter.enabled) {
      filtered = filtered.where((rule) => rule.isEnabled).toList();
    } else if (_filter == _RuleFilter.disabled) {
      filtered = filtered.where((rule) => !rule.isEnabled).toList();
    }
    filtered.sort((a, b) {
      switch (_sort) {
        case _RuleSort.createdDesc:
          return b.createdAt.compareTo(a.createdAt);
        case _RuleSort.updatedDesc:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });
    return filtered;
  }

  String _ruleSearchText(JiveTagRule rule) {
    final parts = <String>[];
    final typeLabel = _typeLabel(rule.applyType);
    if (typeLabel != null) parts.add(typeLabel);
    if (rule.keywords.isNotEmpty) parts.addAll(rule.keywords);
    if (rule.accountIds.isNotEmpty) {
      parts.addAll(rule.accountIds.map((id) => _accountById[id]?.name ?? ''));
    }
    if (rule.categoryKey != null) {
      final parent = _categoryByKey[rule.categoryKey!];
      if (parent != null) parts.add(parent.name);
    }
    if (rule.subCategoryKey != null) {
      final child = _categoryByKey[rule.subCategoryKey!];
      if (child != null) parts.add(child.name);
    }
    if (rule.minAmount != null || rule.maxAmount != null) {
      parts.add(_amountRange(rule.minAmount, rule.maxAmount));
    }
    return parts.where((item) => item.trim().isNotEmpty).join(' ').toLowerCase();
  }

  String? _typeLabel(String? value) {
    switch (value) {
      case 'expense':
        return '支出';
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      case 'all':
      case null:
        return null;
      default:
        return value;
    }
  }

  String _amountRange(double? min, double? max) {
    if (min != null && max != null) return '¥${min.toStringAsFixed(0)} - ¥${max.toStringAsFixed(0)}';
    if (min != null) return '≥ ¥${min.toStringAsFixed(0)}';
    if (max != null) return '≤ ¥${max.toStringAsFixed(0)}';
    return '不限';
  }
}

enum _RuleSort { updatedDesc, createdDesc }

enum _DisableAllAction { cancel, disableOnly, disableAndCleanup }

enum _DeleteAction { cancel, deleteOnly, deleteAndCleanup }

enum _RuleFilter { all, enabled, disabled }

class _BackfillRange {
  final DateTime? start;
  final DateTime? end;

  const _BackfillRange({this.start, this.end});
}

class _RuleInput {
  final double? minAmount;
  final double? maxAmount;
  final List<String> keywords;

  const _RuleInput({
    required this.minAmount,
    required this.maxAmount,
    required this.keywords,
  });
}

class TagRuleEditSheet extends StatefulWidget {
  final Isar isar;
  final JiveTag tag;
  final JiveTagRule? rule;
  final Map<int, JiveAccount> accounts;
  final Map<String, JiveCategory> categoryByKey;
  final Map<String, List<JiveCategory>> childrenByParent;

  const TagRuleEditSheet({
    super.key,
    required this.isar,
    required this.tag,
    required this.accounts,
    required this.categoryByKey,
    required this.childrenByParent,
    this.rule,
  });

  @override
  State<TagRuleEditSheet> createState() => _TagRuleEditSheetState();
}

class _TagRuleEditSheetState extends State<TagRuleEditSheet> {
  final TextEditingController _minAmount = TextEditingController();
  final TextEditingController _maxAmount = TextEditingController();
  final TextEditingController _keywords = TextEditingController();
  bool _enabled = true;
  String _type = 'all';
  String? _categoryKey;
  String? _subCategoryKey;
  final Set<int> _selectedAccountIds = {};
  String? _error;
  bool _previewing = false;
  TagRuleEstimate? _previewResult;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    if (rule != null) {
      _enabled = rule.isEnabled;
      _type = rule.applyType ?? 'all';
      _categoryKey = rule.categoryKey;
      _subCategoryKey = rule.subCategoryKey;
      _selectedAccountIds.addAll(rule.accountIds);
      if (rule.minAmount != null) {
        _minAmount.text = rule.minAmount!.toStringAsFixed(0);
      }
      if (rule.maxAmount != null) {
        _maxAmount.text = rule.maxAmount!.toStringAsFixed(0);
      }
      if (rule.keywords.isNotEmpty) {
        _keywords.text = rule.keywords.join(' ');
      }
    }
  }

  @override
  void dispose() {
    _minAmount.dispose();
    _maxAmount.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final input = _collectInput();
    if (input == null) return;

    final service = TagRuleService(widget.isar);
    if (widget.rule == null) {
      await service.createRule(
        tagKey: widget.tag.key,
        isEnabled: _enabled,
        applyType: _type == 'all' ? null : _type,
        minAmount: input.minAmount,
        maxAmount: input.maxAmount,
        accountIds: _selectedAccountIds.toList(),
        categoryKey: _categoryKey,
        subCategoryKey: _subCategoryKey,
        keywords: input.keywords,
      );
    } else {
      final rule = widget.rule!
        ..isEnabled = _enabled
        ..applyType = _type == 'all' ? null : _type
        ..minAmount = input.minAmount
        ..maxAmount = input.maxAmount
        ..accountIds = _selectedAccountIds.toList()
        ..categoryKey = _categoryKey
        ..subCategoryKey = _subCategoryKey
        ..keywords = input.keywords;
      await service.updateRule(rule);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _previewRule() async {
    if (_previewing) return;
    final input = _collectInput();
    if (input == null) return;
    setState(() {
      _previewing = true;
      _previewResult = null;
    });
    try {
      final estimate = await TagRuleService(widget.isar).estimateRule(
        tagKey: widget.tag.key,
        applyType: _type == 'all' ? null : _type,
        minAmount: input.minAmount,
        maxAmount: input.maxAmount,
        accountIds: _selectedAccountIds.toList(),
        categoryKey: _categoryKey,
        subCategoryKey: _subCategoryKey,
        keywords: input.keywords,
      );
      if (!mounted) return;
      setState(() => _previewResult = estimate);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '预览失败：$e');
    } finally {
      if (mounted) {
        setState(() => _previewing = false);
      }
    }
  }

  _RuleInput? _collectInput() {
    final minValue = double.tryParse(_minAmount.text.trim());
    final maxValue = double.tryParse(_maxAmount.text.trim());
    if (minValue != null && maxValue != null && minValue > maxValue) {
      setState(() => _error = '金额区间不合法');
      return null;
    }
    final keywords = _keywords.text
        .split(RegExp(r'\s+'))
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    final hasCondition = (minValue != null ||
        maxValue != null ||
        _selectedAccountIds.isNotEmpty ||
        (_categoryKey != null && _categoryKey!.isNotEmpty) ||
        (_subCategoryKey != null && _subCategoryKey!.isNotEmpty) ||
        keywords.isNotEmpty);
    if (!hasCondition) {
      setState(() => _error = '请至少设置一个条件');
      return null;
    }
    setState(() => _error = null);
    return _RuleInput(minAmount: minValue, maxAmount: maxValue, keywords: keywords);
  }

  List<JiveCategory> _parentOptions() {
    final parents = widget.categoryByKey.values.where((cat) => cat.parentKey == null).toList();
    if (_type == 'income') {
      return parents.where((cat) => cat.isIncome).toList()..sort((a, b) => a.order.compareTo(b.order));
    }
    if (_type == 'expense') {
      return parents.where((cat) => !cat.isIncome).toList()..sort((a, b) => a.order.compareTo(b.order));
    }
    parents.sort((a, b) => a.order.compareTo(b.order));
    return parents;
  }

  List<JiveCategory> _childOptions() {
    if (_categoryKey == null || _categoryKey!.isEmpty) return [];
    return widget.childrenByParent[_categoryKey!] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      widget.rule == null ? '新增规则' : '编辑规则',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('启用规则'),
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                  activeThumbColor: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 6),
                Text('类型', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTypeChip('all', '全部'),
                    _buildTypeChip('expense', '支出'),
                    _buildTypeChip('income', '收入'),
                    _buildTypeChip('transfer', '转账'),
                  ],
                ),
                const SizedBox(height: 12),
                Text('金额区间', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '最小金额',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxAmount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '最大金额',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('账户', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.accounts.values
                      .map(
                        (account) => FilterChip(
                          label: Text(account.name),
                          selected: _selectedAccountIds.contains(account.id),
                          selectedColor: Colors.green.shade50,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAccountIds.add(account.id);
                              } else {
                                _selectedAccountIds.remove(account.id);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text('分类', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  initialValue: _categoryKey,
                  decoration: const InputDecoration(
                    labelText: '一级分类（可选）',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('不限'),
                    ),
                    ..._parentOptions().map(
                      (cat) => DropdownMenuItem<String?>(
                        value: cat.key,
                        child: Text(cat.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoryKey = value;
                      _subCategoryKey = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _subCategoryKey,
                  decoration: const InputDecoration(
                    labelText: '二级分类（可选）',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('不限'),
                    ),
                    ..._childOptions().map(
                      (cat) => DropdownMenuItem<String?>(
                        value: cat.key,
                        child: Text(cat.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _subCategoryKey = value);
                  },
                ),
                const SizedBox(height: 12),
                Text('关键词', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: _keywords,
                  decoration: const InputDecoration(
                    labelText: '备注/内容关键词（空格分隔）',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '匹配任意关键词即可触发，仅对新增交易生效',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _previewing ? null : _previewRule,
                    icon: _previewing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(_previewing ? '预览中...' : '预览命中'),
                  ),
                ),
                if (_previewing || _previewResult != null) ...[
                  const SizedBox(height: 8),
                  _buildPreviewPanel(),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
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
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    if (_previewing && _previewResult == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('正在计算命中交易数...'),
      );
    }
    final result = _previewResult;
    if (result == null) return const SizedBox.shrink();
    final willTag = result.willTagCount;
    final summary =
        '扫描 ${result.scannedCount} 笔，命中 ${result.matchedCount} 笔；已含标签 ${result.alreadyTaggedCount} 笔，预计新增 $willTag 笔。';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              const Text(
                '命中预览',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(summary, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _type == value,
      selectedColor: Colors.green.shade50,
      onSelected: (_) {
        setState(() {
          _type = value;
          if (_type == 'income' || _type == 'expense') {
            final parent = widget.categoryByKey[_categoryKey];
            if (parent != null && parent.isIncome != (_type == 'income')) {
              _categoryKey = null;
              _subCategoryKey = null;
            }
          }
        });
      },
    );
  }
}
