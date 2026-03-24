import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/service/ai_assistant_service.dart';
import '../../core/service/smart_input_service.dart';
import '../../core/utils/logger_util.dart';
import '../transactions/add_transaction_screen.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.isar,
  });

  final Isar isar;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  bool _isBusy = false;

  Future<void> _runAutoCategorize() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final service = AiAssistantService(widget.isar);
    try {
      final suggestions = await service.previewAutoCategorize(limit: 50);
      if (!mounted) return;
      if (suggestions.isEmpty) {
        _showMessage("暂无可智能分类的交易");
        return;
      }
      final applied = await _showAutoCategorizePreview(suggestions);
      if (applied == true) {
        final updated = await service.applyAutoCategorize(suggestions);
        if (!mounted) return;
        _showMessage("已更新 $updated 笔交易分类");
        Navigator.pop(context, true);
      }
    } catch (e, s) {
      JiveLogger.e("Auto categorize failed", e, s);
      if (mounted) {
        _showMessage("智能分类失败，请稍后重试");
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<bool?> _showAutoCategorizePreview(List<AutoCategorizeSuggestion> suggestions) async {
    final formatter = DateFormat('MM-dd HH:mm');
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "智能分类预览",
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "将为 ${suggestions.length} 笔交易匹配分类",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: suggestions.length > 6 ? 6 : suggestions.length,
                    itemBuilder: (context, index) {
                      final item = suggestions[index];
                      final categoryLabel = item.subName == null
                          ? item.parentName
                          : "${item.parentName} · ${item.subName}";
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          categoryLabel,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          item.rawText ?? "金额 ${item.amount}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        trailing: Text(
                          formatter.format(item.timestamp),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
                if (suggestions.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "仅展示前 6 条，剩余 ${suggestions.length - 6} 条将一并应用",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("取消"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("应用"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleClipboard() async {
    final parser = ClipboardParser();
    final result = await parser.parseClipboard();
    if (!mounted) return;
    if (result == null || !result.hasData) {
      _showMessage("剪贴板未识别到可用信息");
      return;
    }
    final text = result.toSpeechText().isNotEmpty ? result.toSpeechText() : result.rawText;
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(initialSpeechText: text),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _startVoice() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(startWithSpeech: true),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 助手"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildActionCard(
            title: "智能分类",
            subtitle: "为未分类交易匹配分类",
            icon: Icons.auto_awesome,
            color: Colors.teal,
            onTap: _isBusy ? null : _runAutoCategorize,
          ),
          _buildActionCard(
            title: "语音记账",
            subtitle: "按住说话快速录入",
            icon: Icons.mic,
            color: Colors.indigo,
            onTap: _startVoice,
          ),
          _buildActionCard(
            title: "剪贴板识别",
            subtitle: "识别微信/支付宝账单文本",
            icon: Icons.content_paste,
            color: Colors.orange,
            onTap: _handleClipboard,
          ),
          _buildActionCard(
            title: "AI 对话",
            subtitle: "财务洞察与问答（规划中）",
            icon: Icons.chat,
            color: Colors.blueGrey,
            onTap: () => _showMessage("对话能力规划中"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (onTap == null)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
