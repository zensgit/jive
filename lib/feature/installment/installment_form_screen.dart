import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/installment_model.dart';
import '../../core/database/account_model.dart';
import '../../core/service/account_service.dart';

class InstallmentFormScreen extends StatefulWidget {
  const InstallmentFormScreen({super.key, this.installment});
  final JiveInstallment? installment;

  @override
  State<InstallmentFormScreen> createState() => _InstallmentFormScreenState();
}

class _InstallmentFormScreenState extends State<InstallmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _periodsCtrl = TextEditingController(text: '12');

  String _commitMode = InstallmentCommitMode.draft.value;
  String _feeType = InstallmentFeeType.average.value;
  DateTime _startDate = DateTime.now();
  JiveAccount? _selectedAccount;
  List<JiveAccount> _accounts = [];
  bool _saving = false;

  bool get _isEditing => widget.installment != null;

  // Preview calculation
  double get _monthly {
    final p = double.tryParse(_principalCtrl.text) ?? 0;
    final f = double.tryParse(_feeCtrl.text) ?? 0;
    final n = int.tryParse(_periodsCtrl.text) ?? 1;
    if (n <= 0) return 0;
    return (p + f) / n;
  }

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    if (_isEditing) _fillForm(widget.installment!);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _principalCtrl.dispose();
    _feeCtrl.dispose();
    _periodsCtrl.dispose();
    super.dispose();
  }

  void _fillForm(JiveInstallment inst) {
    _nameCtrl.text = inst.name;
    _principalCtrl.text = inst.principalAmount.toStringAsFixed(2);
    _feeCtrl.text = inst.totalFee.toStringAsFixed(2);
    _periodsCtrl.text = inst.totalPeriods.toString();
    _commitMode = inst.commitMode;
    _feeType = inst.feeType;
    _startDate = inst.startDate;
  }

  Future<void> _loadAccounts() async {
    final accts = await Isar.getInstance()!.collection<JiveAccount>().where().findAll();
    if (mounted) {
      setState(() {
        _accounts = accts;
        if (_isEditing) {
          try {
            _selectedAccount = accts.firstWhere((a) => a.id == widget.installment!.accountId);
          } catch (e) { debugPrint('Failed to find matching account for installment: $e'); }
        } else if (accts.isNotEmpty) {
          // default to first credit card account
          _selectedAccount = accts.firstWhere(
            (a) => a.groupName == 'Credit',
            orElse: () => accts.first,
          );
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择账户')),
      );
      return;
    }
    setState(() => _saving = true);

    final isar = Isar.getInstance()!;
    final inst = _isEditing ? widget.installment! : JiveInstallment();
    final periods = int.tryParse(_periodsCtrl.text) ?? 12;

    inst
      ..name = _nameCtrl.text.trim()
      ..accountId = _selectedAccount!.id
      ..principalAmount = double.tryParse(_principalCtrl.text) ?? 0
      ..totalFee = double.tryParse(_feeCtrl.text) ?? 0
      ..totalPeriods = periods
      ..feeType = _feeType
      ..commitMode = _commitMode
      ..startDate = _startDate
      ..nextDueAt = DateTime(_startDate.year, _startDate.month + 1, _startDate.day)
      ..isActive = true
      ..status = InstallmentStatus.active.value
      ..updatedAt = DateTime.now();

    if (!_isEditing) {
      inst
        ..key = const Uuid().v4()
        ..currency = 'CNY'
        ..createdAt = DateTime.now();
    }

    try {
      await isar.writeTxn(() async {
        await isar.collection<JiveInstallment>().put(inst);
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑分期' : '新建分期'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '分期名称 *',
                border: OutlineInputBorder(),
                hintText: '例如: MacBook Pro 分期',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),

            // Account
            _SectionLabel('信用卡/贷款账户'),
            const SizedBox(height: 8),
            _AccountDropdown(
              accounts: _accounts,
              selected: _selectedAccount,
              onChanged: (a) => setState(() => _selectedAccount = a),
            ),
            const SizedBox(height: 16),

            // Principal + Fee
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _principalCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '总金额 *',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                  onChanged: (_) {
                    setState(() {
                      // trigger rebuild to update monthly preview
                    });
                  },
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    return d == null || d <= 0 ? '请输入有效金额' : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _feeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '手续费',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                    hintText: '0.00',
                  ),
                  onChanged: (_) {
                    setState(() {
                      // trigger rebuild to update monthly preview
                    });
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Periods
            TextFormField(
              controller: _periodsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '期数 *',
                border: OutlineInputBorder(),
                suffixText: '期',
              ),
              onChanged: (_) {
                setState(() {
                  // trigger rebuild to update monthly preview
                });
              },
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0 ? '请输入有效期数' : null;
              },
            ),
            const SizedBox(height: 8),

            // Monthly preview
            if (_monthly > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('预计每期还款', style: TextStyle(color: Color(0xFF2E7D32))),
                    Text(
                      '¥${_monthly.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Start date
            _SectionLabel('首期日期'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null && mounted) setState(() => _startDate = d);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 20, color: Colors.grey.shade500),
                    const SizedBox(width: 10),
                    Text(DateFormat('yyyy年MM月dd日').format(_startDate),
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fee type
            _SectionLabel('手续费分配方式'),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(children: [
                RadioListTile<String>(
                  value: InstallmentFeeType.average.value,
                  groupValue: _feeType,
                  title: const Text('平均分摊'),
                  subtitle: const Text('每期手续费均等'),
                  onChanged: (v) => setState(() => _feeType = v!),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: InstallmentFeeType.first.value,
                  groupValue: _feeType,
                  title: const Text('首期一次性'),
                  subtitle: const Text('手续费在首期扣除'),
                  onChanged: (v) => setState(() => _feeType = v!),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Commit mode
            _SectionLabel('记账模式'),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(children: [
                RadioListTile<String>(
                  value: InstallmentCommitMode.draft.value,
                  groupValue: _commitMode,
                  title: const Text('草稿模式'),
                  subtitle: const Text('每期生成待确认草稿'),
                  onChanged: (v) => setState(() => _commitMode = v!),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: InstallmentCommitMode.commit.value,
                  groupValue: _commitMode,
                  title: const Text('自动记账'),
                  subtitle: const Text('每期自动写入账本'),
                  onChanged: (v) => setState(() => _commitMode = v!),
                ),
              ]),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: Text(_isEditing ? '保存修改' : '创建分期', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.lato(
            fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600));
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({required this.accounts, required this.selected, required this.onChanged});
  final List<JiveAccount> accounts;
  final JiveAccount? selected;
  final void Function(JiveAccount?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<JiveAccount?>(
          value: selected,
          isExpanded: true,
          hint: const Text('选择账户'),
          items: [
            for (final a in accounts)
              DropdownMenuItem<JiveAccount?>(value: a, child: Text(a.name)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
