import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/recurring_rule_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/recurring_service.dart';
import 'recurring_rule_form_screen.dart';

class RecurringRuleListScreen extends StatefulWidget {
  const RecurringRuleListScreen({super.key});

  @override
  State<RecurringRuleListScreen> createState() =>
      _RecurringRuleListScreenState();
}

class _RecurringRuleListScreenState extends State<RecurringRuleListScreen> {
  Isar? _isar;
  bool _isLoading = true;
  bool _isProcessing = false;
  List<JiveRecurringRule> _rules = [];
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = null;
      });
    }
    try {
      final isar = await _ensureIsar();
      final service = RecurringService(isar);
      final rules = await service.getRules();
      if (!mounted) return;
      setState(() {
        _rules = rules;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rules = [];
        _loadErrorMessage = '加载周期规则失败：$e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Future<void> _openRuleForm({JiveRecurringRule? rule}) async {
    final result = await Navigator.push<RecurringRuleSaveResult>(
      context,
      MaterialPageRoute(
        builder: (context) => RecurringRuleFormScreen(editingRule: rule),
      ),
    );
    if (result == null || !result.saved) return;
    await _loadRules();
    if (!mounted) return;
    _showProcessResultSnack(
      generatedDrafts: result.generatedDrafts,
      committedTransactions: result.committedTransactions,
      processingError: result.processingError,
      successPrefix: '规则已保存',
    );
  }

  Future<void> _processNow() async {
    if (_isProcessing) return;
    if (mounted) {
      setState(() => _isProcessing = true);
    }
    try {
      final isar = await _ensureIsar();
      final result = await RecurringService(isar).processDueRules();
      await _loadRules();
      if (mounted) {
        _showProcessResultSnack(
          generatedDrafts: result.generatedDrafts,
          committedTransactions: result.committedTransactions,
        );
      }
    } catch (e) {
      if (mounted) {
        _showProcessResultSnack(
          generatedDrafts: 0,
          committedTransactions: 0,
          processingError: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteRule(JiveRecurringRule rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除周期规则'),
        content: const Text('确定删除该规则？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await RecurringService(_isar!).deleteRule(rule.id);
    await _loadRules();
  }

  void _showProcessResultSnack({
    required int generatedDrafts,
    required int committedTransactions,
    String? processingError,
    String? successPrefix,
  }) {
    final message = _buildProcessResultMessage(
      generatedDrafts: generatedDrafts,
      committedTransactions: committedTransactions,
      processingError: processingError,
      successPrefix: successPrefix,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildProcessResultMessage({
    required int generatedDrafts,
    required int committedTransactions,
    String? processingError,
    String? successPrefix,
  }) {
    if (processingError != null && processingError.isNotEmpty) {
      if (successPrefix == null || successPrefix.isEmpty) {
        return '执行失败：$processingError';
      }
      return '$successPrefix，但自动执行失败：$processingError';
    }

    final total = generatedDrafts + committedTransactions;
    if (total == 0) {
      if (successPrefix == null || successPrefix.isEmpty) {
        return '当前没有到期规则';
      }
      return '$successPrefix，当前没有到期规则';
    }

    final detail = '草稿 $generatedDrafts 笔，入账 $committedTransactions 笔';
    if (successPrefix == null || successPrefix.isEmpty) {
      return '执行完成：$detail';
    }
    return '$successPrefix并执行：$detail';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          '周期记账',
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '立即执行一次',
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline),
            onPressed: _isProcessing ? null : _processNow,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openRuleForm(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadErrorMessage != null
          ? _buildLoadErrorState()
          : _rules.isEmpty
          ? _buildEmptyState()
          : _buildList(),
    );
  }

  Widget _buildLoadErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              '周期规则加载失败',
              style: GoogleFonts.lato(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _loadErrorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRules,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat,
                size: 48,
                color: JiveTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '创建周期记账规则',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持草稿或自动入账\n按日/周/月/年重复生成',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _openRuleForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: JiveTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('新建规则'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule, color: JiveTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ruleSubtitle(rule),
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.isActive,
                onChanged: (value) async {
                  await RecurringService(_isar!).setRuleActive(rule, value);
                  await _loadRules();
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openRuleForm(rule: rule);
                  } else if (value == 'delete') {
                    _deleteRule(rule);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('编辑')),
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _ruleSubtitle(JiveRecurringRule rule) {
    final typeLabel = rule.type == 'income'
        ? '收入'
        : rule.type == 'transfer'
        ? '转账'
        : '支出';
    final intervalLabel = _intervalLabel(rule);
    final commitLabel = rule.commitMode == 'commit' ? '自动入账' : '生成草稿';
    return '$typeLabel · ${rule.amount.toStringAsFixed(2)} · $intervalLabel · $commitLabel';
  }

  String _intervalLabel(JiveRecurringRule rule) {
    String unit = '月';
    if (rule.intervalType == 'day') {
      unit = '天';
    } else if (rule.intervalType == 'week') {
      unit = '周';
    } else if (rule.intervalType == 'year') {
      unit = '年';
    }
    return '每${rule.intervalValue}$unit';
  }
}
