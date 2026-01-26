import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import '../../core/database/category_model.dart';
import '../../core/service/auto_draft_service.dart';
import '../../core/service/auto_rule_engine.dart';

class AutoRuleTesterScreen extends StatefulWidget {
  const AutoRuleTesterScreen({super.key, required this.isar});

  final Isar isar;

  @override
  State<AutoRuleTesterScreen> createState() => _AutoRuleTesterScreenState();
}

class _AutoRuleTesterScreenState extends State<AutoRuleTesterScreen> {
  final _sourceController = TextEditingController(text: 'WeChat');
  final _textController = TextEditingController();
  String? _typeOverride;
  bool _loading = false;
  _RuleTestResult? _result;

  @override
  void dispose() {
    _sourceController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _runTest() async {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入通知文本')),
      );
      return;
    }
    final source = _sourceController.text.trim();
    setState(() {
      _loading = true;
      _result = null;
    });
    final engine = await AutoRuleEngine.instance();
    final match = engine.match(
      text: rawText,
      source: source.isEmpty ? null : source,
    );
    final categories = CategoryIndex(
      await widget.isar.collection<JiveCategory>().where().findAll(),
    );
    final resolved = categories.resolve(match.parent, match.sub);
    final type = _typeOverride ?? match.type;
    var parentName = resolved.parent?.name ?? match.parent ?? '自动记账';
    var subName = resolved.child?.name ?? match.sub ?? '未分类';
    if (type == 'expense') {
      final meal = _inferMealSubCategory(
        parentName: parentName,
        subName: subName,
        timestamp: DateTime.now(),
      );
      if (meal != null) {
        subName = meal;
      }
    }
    if (!mounted) return;
    setState(() {
      _result = _RuleTestResult(
        ruleName: match.ruleName,
        type: type,
        matchedParent: match.parent,
        matchedSub: match.sub,
        matchedTags: match.tags,
        resolvedParent: parentName,
        resolvedSub: subName,
        parentKey: resolved.parent?.key,
        childKey: resolved.child?.key,
      );
      _loading = false;
    });
  }

  String? _inferMealSubCategory({
    required String parentName,
    required String subName,
    required DateTime timestamp,
  }) {
    if (parentName != '餐饮') return null;
    if (subName == '早餐' || subName == '午餐' || subName == '晚餐') {
      return subName;
    }
    final hour = timestamp.hour;
    if (hour >= 4 && hour < 10) return '早餐';
    if (hour >= 10 && hour < 16) return '午餐';
    return '晚餐';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('自动规则测试', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _sourceController,
            decoration: const InputDecoration(
              labelText: '来源 source',
              hintText: 'WeChat / Alipay / com.xxx',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '通知文本 raw_text',
              hintText: '粘贴通知或识别文本',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _typeOverride,
            decoration: const InputDecoration(
              labelText: '类型覆盖（可选）',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('自动识别')),
              DropdownMenuItem<String?>(value: 'expense', child: Text('支出')),
              DropdownMenuItem<String?>(value: 'income', child: Text('收入')),
              DropdownMenuItem<String?>(value: 'transfer', child: Text('转账')),
            ],
            onChanged: (value) {
              setState(() {
                _typeOverride = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _runTest,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_fill),
              label: Text(_loading ? '处理中...' : '开始测试'),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text('结果', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          if (_result == null)
            Text('等待输入', style: TextStyle(color: Colors.grey.shade500))
          else
            _buildResultCard(_result!),
        ],
      ),
    );
  }

  Widget _buildResultCard(_RuleTestResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('命中规则', result.ruleName ?? '无'),
          const SizedBox(height: 8),
          _buildRow('类型', _typeLabel(result.type)),
          const SizedBox(height: 8),
          _buildRow(
            '匹配分类',
            '${result.matchedParent ?? '-'} / ${result.matchedSub ?? '-'}',
          ),
          const SizedBox(height: 8),
          _buildRow(
            '解析分类',
            '${result.resolvedParent} / ${result.resolvedSub}',
          ),
          const SizedBox(height: 8),
          _buildRow(
            '分类Key',
            '${result.parentKey ?? '-'} / ${result.childKey ?? '-'}',
          ),
          const SizedBox(height: 8),
          _buildRow(
            '标签',
            result.matchedTags.isEmpty ? '-' : result.matchedTags.join(', '),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return '支出';
    }
  }
}

class _RuleTestResult {
  final String? ruleName;
  final String type;
  final String? matchedParent;
  final String? matchedSub;
  final List<String> matchedTags;
  final String resolvedParent;
  final String resolvedSub;
  final String? parentKey;
  final String? childKey;

  const _RuleTestResult({
    required this.ruleName,
    required this.type,
    required this.matchedParent,
    required this.matchedSub,
    required this.matchedTags,
    required this.resolvedParent,
    required this.resolvedSub,
    required this.parentKey,
    required this.childKey,
  });
}
