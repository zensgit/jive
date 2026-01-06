import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/auto_draft_service.dart';

class AutoDraftsScreen extends StatefulWidget {
  const AutoDraftsScreen({super.key});

  @override
  State<AutoDraftsScreen> createState() => _AutoDraftsScreenState();
}

class _AutoDraftsScreenState extends State<AutoDraftsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  bool _hasChanges = false;
  List<JiveAutoDraft> _drafts = [];
  final DateFormat _timeFormat = DateFormat('MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
    } else {
      _isar = await Isar.open(
        [JiveTransactionSchema, JiveCategorySchema, JiveAccountSchema, JiveAutoDraftSchema],
        directory: dir.path,
      );
    }
    await _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final list = await _isar.collection<JiveAutoDraft>()
        .where()
        .sortByTimestampDesc()
        .findAll();
    if (!mounted) return;
    setState(() {
      _drafts = list;
      _isLoading = false;
    });
  }

  Future<void> _confirmDraft(JiveAutoDraft draft) async {
    await AutoDraftService(_isar).confirmDraft(draft);
    _hasChanges = true;
    await _loadDrafts();
  }

  Future<void> _discardDraft(JiveAutoDraft draft) async {
    await AutoDraftService(_isar).discardDraft(draft);
    _hasChanges = true;
    await _loadDrafts();
  }

  Future<void> _confirmAll() async {
    final service = AutoDraftService(_isar);
    for (final draft in List<JiveAutoDraft>.from(_drafts)) {
      await service.confirmDraft(draft);
    }
    _hasChanges = true;
    await _loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("待确认自动记账", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            if (_drafts.isNotEmpty)
              TextButton(
                onPressed: _confirmAll,
                child: const Text("全部确认"),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDrafts,
                child: _drafts.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _drafts.length,
                        itemBuilder: (context, index) {
                          return _buildDraftCard(_drafts[index]);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 140),
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Center(
          child: Text("暂无待确认记录", style: TextStyle(color: Colors.grey.shade500)),
        ),
      ],
    );
  }

  Widget _buildDraftCard(JiveAutoDraft draft) {
    final type = draft.type ?? 'expense';
    final amountPrefix = type == 'income' ? '+ ' : '- ';
    final amountColor = type == 'income' ? Colors.green : Colors.redAccent;
    final category = draft.category ?? '自动记账';
    final sub = draft.subCategory ?? '未分类';
    final timeText = _timeFormat.format(draft.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text("$sub • $timeText", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                "$amountPrefix¥${draft.amount.toStringAsFixed(2)}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
              ),
            ],
          ),
          if ((draft.rawText ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              draft.rawText!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _discardDraft(draft),
                child: const Text("删除"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _confirmDraft(draft),
                child: const Text("确认"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
