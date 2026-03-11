import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/service/email_delete_user_governance_service.dart';

class EmailDeleteUserGovernanceScreen extends StatefulWidget {
  const EmailDeleteUserGovernanceScreen({
    super.key,
    this.service = const EmailDeleteUserGovernanceService(),
  });

  final EmailDeleteUserGovernanceService service;

  @override
  State<EmailDeleteUserGovernanceScreen> createState() =>
      _EmailDeleteUserGovernanceScreenState();
}

class _EmailDeleteUserGovernanceScreenState
    extends State<EmailDeleteUserGovernanceScreen> {
  final TextEditingController _accountIdController = TextEditingController(
    text: 'user-2026-delete',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'user@jive.app',
  );
  final TextEditingController _verificationCodeValidMinutesController =
      TextEditingController(text: '10');
  final TextEditingController _deletionCooldownHoursController =
      TextEditingController(text: '0');
  final TextEditingController _pendingSharedBookCountController =
      TextEditingController(text: '0');

  bool _emailVerified = true;
  bool _verificationCodeSent = true;
  bool _clearDataReady = true;
  bool _backupConfirmed = true;
  bool _highRiskOperation = false;
  bool _currentSessionValid = true;
  bool _confirmTextMatched = true;
  EmailDeleteUserGovernanceResult? _result;

  @override
  void dispose() {
    _accountIdController.dispose();
    _emailController.dispose();
    _verificationCodeValidMinutesController.dispose();
    _deletionCooldownHoursController.dispose();
    _pendingSharedBookCountController.dispose();
    super.dispose();
  }

  EmailDeleteUserGovernanceResult _evaluate() {
    final result = widget.service.evaluate(
      accountId: _accountIdController.text,
      email: _emailController.text,
      emailVerified: _emailVerified,
      verificationCodeSent: _verificationCodeSent,
      verificationCodeValidMinutes:
          int.tryParse(_verificationCodeValidMinutesController.text.trim()) ??
          0,
      clearDataReady: _clearDataReady,
      backupConfirmed: _backupConfirmed,
      deletionCooldownHours:
          int.tryParse(_deletionCooldownHoursController.text.trim()) ?? 0,
      highRiskOperation: _highRiskOperation,
      currentSessionValid: _currentSessionValid,
      confirmTextMatched: _confirmTextMatched,
      pendingSharedBookCount:
          int.tryParse(_pendingSharedBookCountController.text.trim()) ?? 0,
    );
    setState(() {
      _result = result;
    });
    return result;
  }

  Future<void> _copyJson() async {
    final result = _result ?? _evaluate();
    await Clipboard.setData(
      ClipboardData(text: widget.service.exportJson(result)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制 JSON')));
  }

  Future<void> _copyMarkdown() async {
    final result = _result ?? _evaluate();
    await Clipboard.setData(
      ClipboardData(text: widget.service.exportMarkdown(result)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制 MD')));
  }

  Future<void> _copyCsv() async {
    final result = _result ?? _evaluate();
    await Clipboard.setData(
      ClipboardData(text: widget.service.exportCsv(result)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制 CSV')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('邮箱注销治理中心')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _accountIdController,
            decoration: const InputDecoration(
              labelText: 'accountId',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _verificationCodeValidMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'verificationCodeValidMinutes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deletionCooldownHoursController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'deletionCooldownHours',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pendingSharedBookCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'pendingSharedBookCount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('emailVerified'),
            value: _emailVerified,
            onChanged: (value) {
              setState(() {
                _emailVerified = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('verificationCodeSent'),
            value: _verificationCodeSent,
            onChanged: (value) {
              setState(() {
                _verificationCodeSent = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('clearDataReady'),
            value: _clearDataReady,
            onChanged: (value) {
              setState(() {
                _clearDataReady = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('backupConfirmed'),
            value: _backupConfirmed,
            onChanged: (value) {
              setState(() {
                _backupConfirmed = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('highRiskOperation'),
            value: _highRiskOperation,
            onChanged: (value) {
              setState(() {
                _highRiskOperation = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('currentSessionValid'),
            value: _currentSessionValid,
            onChanged: (value) {
              setState(() {
                _currentSessionValid = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('confirmTextMatched'),
            value: _confirmTextMatched,
            onChanged: (value) {
              setState(() {
                _confirmTextMatched = value;
              });
            },
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _evaluate, child: const Text('评估邮箱注销治理')),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text('status: ${_result!.status}'),
            Text('governanceMode: ${_result!.governanceMode}'),
            Text('recommendation: ${_result!.recommendation}'),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: _copyJson, child: const Text('复制JSON')),
              OutlinedButton(
                onPressed: _copyMarkdown,
                child: const Text('复制MD'),
              ),
              OutlinedButton(onPressed: _copyCsv, child: const Text('复制CSV')),
            ],
          ),
        ],
      ),
    );
  }
}
