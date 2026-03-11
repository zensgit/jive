import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/service/bill_search_policy_governance_service.dart';

class BillSearchPolicyGovernanceScreen extends StatefulWidget {
  const BillSearchPolicyGovernanceScreen({
    super.key,
    this.service = const BillSearchPolicyGovernanceService(),
  });

  final BillSearchPolicyGovernanceService service;

  @override
  State<BillSearchPolicyGovernanceScreen> createState() =>
      _BillSearchPolicyGovernanceScreenState();
}

class _BillSearchPolicyGovernanceScreenState
    extends State<BillSearchPolicyGovernanceScreen> {
  final TextEditingController _queryController = TextEditingController(
    text: '餐饮 #午餐',
  );
  final TextEditingController _historyCountController = TextEditingController(
    text: '8',
  );
  final TextEditingController _selectedFilterCountController =
      TextEditingController(text: '2');
  final TextEditingController _sortModeController = TextEditingController(
    text: 'time',
  );
  final TextEditingController _estimatedResultCountController =
      TextEditingController(text: '120');
  final TextEditingController _searchWindowDaysController =
      TextEditingController(text: '30');

  bool _historyEnabled = true;
  bool _filterEnabled = true;
  bool _tagSuggestionEnabled = true;
  bool _actionSuggestionEnabled = true;
  BillSearchPolicyGovernanceResult? _result;

  @override
  void dispose() {
    _queryController.dispose();
    _historyCountController.dispose();
    _selectedFilterCountController.dispose();
    _sortModeController.dispose();
    _estimatedResultCountController.dispose();
    _searchWindowDaysController.dispose();
    super.dispose();
  }

  BillSearchPolicyGovernanceResult _evaluate() {
    final result = widget.service.evaluate(
      query: _queryController.text,
      historyEnabled: _historyEnabled,
      historyCount: int.tryParse(_historyCountController.text.trim()) ?? 0,
      filterEnabled: _filterEnabled,
      selectedFilterCount:
          int.tryParse(_selectedFilterCountController.text.trim()) ?? 0,
      sortMode: _sortModeController.text,
      estimatedResultCount:
          int.tryParse(_estimatedResultCountController.text.trim()) ?? 0,
      tagSuggestionEnabled: _tagSuggestionEnabled,
      actionSuggestionEnabled: _actionSuggestionEnabled,
      searchWindowDays:
          int.tryParse(_searchWindowDaysController.text.trim()) ?? 0,
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
      appBar: AppBar(title: const Text('账单搜索策略治理中心')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              labelText: 'query',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _historyCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'historyCount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _selectedFilterCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'selectedFilterCount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sortModeController,
            decoration: const InputDecoration(
              labelText: 'sortMode (time/amount/relevance)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _estimatedResultCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'estimatedResultCount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchWindowDaysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'searchWindowDays',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('historyEnabled'),
            value: _historyEnabled,
            onChanged: (value) {
              setState(() {
                _historyEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('filterEnabled'),
            value: _filterEnabled,
            onChanged: (value) {
              setState(() {
                _filterEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('tagSuggestionEnabled'),
            value: _tagSuggestionEnabled,
            onChanged: (value) {
              setState(() {
                _tagSuggestionEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('actionSuggestionEnabled'),
            value: _actionSuggestionEnabled,
            onChanged: (value) {
              setState(() {
                _actionSuggestionEnabled = value;
              });
            },
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _evaluate, child: const Text('评估账单搜索策略治理')),
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
