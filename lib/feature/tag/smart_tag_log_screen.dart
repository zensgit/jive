import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/service/smart_tag_log_service.dart';

class SmartTagLogScreen extends StatefulWidget {
  const SmartTagLogScreen({super.key});

  @override
  State<SmartTagLogScreen> createState() => _SmartTagLogScreenState();
}

class _SmartTagLogScreenState extends State<SmartTagLogScreen> {
  final _service = SmartTagLogService();
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  bool _loading = true;
  List<SmartTagLogEntry> _logs = [];
  String? _filterTagKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await _service.loadLogs();
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
      if (_filterTagKey != null && logs.every((item) => item.tagKey != _filterTagKey)) {
        _filterTagKey = null;
      }
    });
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空记录'),
        content: const Text('确认清空所有补标记录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('补标记录', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        actions: [
          if (_logs.isNotEmpty)
            IconButton(
              tooltip: '清空记录',
              onPressed: _clear,
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text(
                    '暂无补标记录',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : Column(
                  children: [
                    _buildFilterBar(),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildLogCard(_filteredLogs[index]),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<SmartTagLogEntry> get _filteredLogs {
    if (_filterTagKey == null) return _logs;
    return _logs.where((entry) => entry.tagKey == _filterTagKey).toList();
  }

  Widget _buildFilterBar() {
    final tagNames = <String, String>{};
    for (final log in _logs) {
      tagNames.putIfAbsent(log.tagKey, () => log.tagName);
    }
    final chips = <Widget>[
      ChoiceChip(
        label: const Text('全部'),
        selected: _filterTagKey == null,
        onSelected: (_) => setState(() => _filterTagKey = null),
      ),
      ...tagNames.entries.map(
        (entry) => ChoiceChip(
          label: Text(entry.value),
          selected: _filterTagKey == entry.key,
          onSelected: (_) => setState(() => _filterTagKey = entry.key),
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map(
                (chip) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: chip,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLogCard(SmartTagLogEntry entry) {
    final rangeText = _rangeLabel(entry.rangeStart, entry.rangeEnd);
    final statusText = entry.success
        ? (entry.cancelled ? '已取消' : '已完成')
        : '失败';
    final resultText = entry.success
        ? '更新 ${entry.updatedCount} / ${entry.scannedCount} 笔'
        : (entry.message ?? '补标失败');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.tagName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _dateFormat.format(entry.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$statusText · $resultText',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            '匹配 ${entry.matchedCount} / ${entry.scannedCount} · 跳过 ${entry.skippedCount}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            '范围：$rangeText',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          if (entry.message != null && entry.message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.message!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  String _rangeLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '全部时间';
    final startText = start == null ? '不限' : DateFormat('yyyy-MM-dd').format(start);
    final endText = end == null ? '不限' : DateFormat('yyyy-MM-dd').format(end);
    return '$startText ~ $endText';
  }
}
