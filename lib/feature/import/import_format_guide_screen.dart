import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/alipay_csv_parser.dart';
import '../../core/service/import_service.dart';
import '../../core/service/wechat_csv_parser.dart';

/// Guide screen that helps users pick the right CSV import format
/// (WeChat, Alipay, or generic CSV) and parse the selected file.
class ImportFormatGuideScreen extends StatelessWidget {
  const ImportFormatGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('选择导入格式'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _FormatCard(
                emoji: '💬',
                name: '微信',
                subtitle: 'WeChat Pay',
                format: _ImportFormat.wechat,
                steps: [
                  '打开微信，进入「我」→「服务」→「钱包」',
                  '点击右上角「账单」',
                  '点击右上角「常见问题」',
                  '选择「下载账单」→「用于个人对账」',
                  '选择时间范围，输入邮箱接收',
                  '从邮箱下载 CSV 文件',
                ],
              ),
              SizedBox(height: 12),
              _FormatCard(
                emoji: '🔵',
                name: '支付宝',
                subtitle: 'Alipay',
                format: _ImportFormat.alipay,
                steps: [
                  '打开支付宝，进入「我的」→「账单」',
                  '点击右上角「···」→「开具交易流水证明」',
                  '或访问 consumeprod.alipay.com 下载',
                  '选择时间范围并申请下载',
                  '从邮箱下载 CSV 文件',
                ],
              ),
              SizedBox(height: 12),
              _FormatCard(
                emoji: '📄',
                name: '通用CSV',
                subtitle: 'Generic CSV',
                format: _ImportFormat.generic,
                steps: [
                  '准备一个 CSV 格式的账单文件',
                  '文件应包含：日期、金额、描述等列',
                  '支持自动检测微信/支付宝格式',
                  '未识别的格式将按通用CSV处理',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ImportFormat { wechat, alipay, generic }

class _FormatCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String subtitle;
  final _ImportFormat format;
  final List<String> steps;

  const _FormatCard({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.format,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '导出步骤：',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8, top: 1),
                    decoration: BoxDecoration(
                      color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: JiveTheme.primaryGreen,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _PickFileButton(format: format),
          ),
        ],
      ),
    );
  }
}

class _PickFileButton extends StatefulWidget {
  final _ImportFormat format;

  const _PickFileButton({required this.format});

  @override
  State<_PickFileButton> createState() => _PickFileButtonState();
}

class _PickFileButtonState extends State<_PickFileButton> {
  bool _loading = false;

  Future<void> _pickAndParse() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _loading = false);
        return;
      }

      final filePath = result.files.single.path!;
      final content = await File(filePath).readAsString();

      final records = _parseContent(content);
      if (!mounted) return;

      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未能解析到有效记录，请检查文件格式'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final formatLabel = _detectFormatLabel(content);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$formatLabel 解析成功，共 ${records.length} 条记录'),
            backgroundColor: JiveTheme.primaryGreen,
          ),
        );
        Navigator.of(context).pop(records);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件读取失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ImportParsedRecord> _parseContent(String content) {
    // Auto-detect format regardless of which card was tapped
    if (WechatCsvParser.isWechatFormat(content)) {
      return WechatCsvParser.parse(content);
    }
    if (AlipayCsvParser.isAlipayFormat(content)) {
      return AlipayCsvParser.parse(content);
    }
    // For generic or unrecognized, try both parsers
    final wechat = WechatCsvParser.parse(content);
    if (wechat.isNotEmpty) return wechat;
    final alipay = AlipayCsvParser.parse(content);
    if (alipay.isNotEmpty) return alipay;
    return [];
  }

  String _detectFormatLabel(String content) {
    if (WechatCsvParser.isWechatFormat(content)) return '微信';
    if (AlipayCsvParser.isAlipayFormat(content)) return '支付宝';
    return '通用CSV';
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _pickAndParse,
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.file_upload_outlined, size: 20),
      label: Text(_loading ? '解析中...' : '选择文件'),
      style: ElevatedButton.styleFrom(
        backgroundColor: JiveTheme.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
