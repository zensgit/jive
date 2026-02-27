import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/account_model.dart';
import '../../core/database/installment_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/installment_service.dart';

class InstallmentManageScreen extends StatefulWidget {
  const InstallmentManageScreen({super.key});

  @override
  State<InstallmentManageScreen> createState() =>
      _InstallmentManageScreenState();
}

class _InstallmentManageScreenState extends State<InstallmentManageScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  Isar? _isar;
  InstallmentService? _service;
  List<JiveInstallment> _installments = [];
  List<JiveAccount> _creditAccounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = _isar ?? await DatabaseService.getInstance();
    final service = InstallmentService(isar);
    final allAccounts = await AccountService(isar).getActiveAccounts();
    final creditAccounts = allAccounts
        .where((a) => a.type == 'liability' && a.subType == 'credit')
        .toList();
    final installments = await service.getInstallments();
    if (!mounted) return;
    setState(() {
      _isar = isar;
      _service = service;
      _creditAccounts = creditAccounts;
      _installments = installments;
      _loading = false;
    });
  }

  Future<void> _processDueNow() async {
    final service = _service;
    if (service == null) return;
    final result = await service.processDueInstallments();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '执行完成：草稿 ${result.generatedDrafts}，入账 ${result.committedTransactions}，完成 ${result.finishedInstallments}',
        ),
      ),
    );
    await _load();
  }

  Future<void> _createInstallment() async {
    if (_creditAccounts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先创建信用卡账户')));
      return;
    }
    var selectedAccount = _creditAccounts.first;
    final nameController = TextEditingController();
    final principalController = TextEditingController();
    final feeController = TextEditingController(text: '0');
    final periodsController = TextEditingController(text: '12');
    DateTime startDate = DateTime.now();
    InstallmentCommitMode commitMode = InstallmentCommitMode.draft;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('新建分期'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedAccount.id,
                      decoration: const InputDecoration(labelText: '信用卡账户'),
                      items: _creditAccounts
                          .map(
                            (a) => DropdownMenuItem<int>(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        JiveAccount? match;
                        for (final item in _creditAccounts) {
                          if (item.id == value) {
                            match = item;
                            break;
                          }
                        }
                        if (match != null) {
                          setState(() => selectedAccount = match);
                        }
                      },
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '名称'),
                    ),
                    TextField(
                      controller: principalController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: '本金'),
                    ),
                    TextField(
                      controller: feeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: '利息'),
                    ),
                    TextField(
                      controller: periodsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '期数'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: commitMode.value,
                      decoration: const InputDecoration(labelText: '执行模式'),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('仅生成草稿')),
                        DropdownMenuItem(value: 'commit', child: Text('自动入账')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(
                          () => commitMode = InstallmentCommitMode.fromValue(
                            value,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('首期日期'),
                      subtitle: Text(_dateFormat.format(startDate)),
                      trailing: const Icon(Icons.date_range),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2010),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    final service = _service;
    if (service == null) return;

    final principal = double.tryParse(principalController.text.trim());
    final fee = double.tryParse(feeController.text.trim()) ?? 0;
    final periods = int.tryParse(periodsController.text.trim());
    final name = nameController.text.trim();

    if (principal == null ||
        principal <= 0 ||
        periods == null ||
        periods <= 0 ||
        name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效分期参数')));
      return;
    }

    final installment = JiveInstallment()
      ..key = ''
      ..name = name
      ..accountId = selectedAccount.id
      ..currency = selectedAccount.currency
      ..principalAmount = principal
      ..totalFee = fee
      ..totalPeriods = periods
      ..feeType = InstallmentFeeType.average.value
      ..remainderType = InstallmentRemainderType.averageFirst.value
      ..commitMode = commitMode.value
      ..startDate = DateTime(startDate.year, startDate.month, startDate.day, 9)
      ..nextDueAt = DateTime(startDate.year, startDate.month, startDate.day, 9);

    try {
      await service.createInstallment(installment);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分期已创建')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('创建失败：$e')));
    }
  }

  Widget _buildItem(JiveInstallment installment) {
    final progress = installment.totalPeriods <= 0
        ? 0.0
        : installment.executedPeriods / installment.totalPeriods;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(installment.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '账户#${installment.accountId} · ${installment.executedPeriods}/${installment.totalPeriods}期 · ${installment.commitMode}',
            ),
            Text(
              '下次执行：${_dateFormat.format(installment.nextDueAt)} · 状态：${installment.status}',
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress.clamp(0, 1)),
          ],
        ),
        trailing: IconButton(
          tooltip: '提前结清',
          icon: const Icon(Icons.done_all),
          onPressed: installment.isActive
              ? () async {
                  await _service?.markInstallmentPrepaid(installment.id);
                  await _load();
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分期管理'),
        actions: [
          IconButton(
            tooltip: '执行到期分期',
            onPressed: _service == null ? null : _processDueNow,
            icon: const Icon(Icons.play_arrow),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _createInstallment,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _installments.isEmpty
          ? const Center(child: Text('暂无分期，点击右下角创建'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                itemCount: _installments.length,
                itemBuilder: (context, index) =>
                    _buildItem(_installments[index]),
              ),
            ),
    );
  }
}
