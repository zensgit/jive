import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/tag_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/template_model.dart';
import '../../core/database/project_model.dart';
import '../../core/service/tag_service.dart';
import '../../core/design_system/theme.dart';

class TagManagerScreen extends StatefulWidget {
  const TagManagerScreen({super.key});

  @override
  State<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends State<TagManagerScreen> {
  Isar? _isar;
  bool _isLoading = true;
  List<JiveTag> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);

    final isar = await _ensureIsar();
    final service = TagService(isar);
    final tags = await service.getAllTags();

    if (!mounted) return;
    setState(() {
      _tags = tags;
      _isLoading = false;
    });
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
      return _isar!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        JiveTransactionSchema,
        JiveCategorySchema,
        JiveCategoryOverrideSchema,
        JiveAccountSchema,
        JiveAutoDraftSchema,
        JiveTemplateSchema,
        JiveTagSchema,
        JiveProjectSchema,
      ],
      directory: dir.path,
    );
    return _isar!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: JiveTheme.surfaceWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? _buildEmptyState()
              : _buildTagList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '暂无标签',
            style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '在备注中使用 #标签 格式添加',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTagList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tags.length,
      itemBuilder: (context, index) {
        final tag = _tags[index];
        return _buildTagCard(tag);
      },
    );
  }

  Widget _buildTagCard(JiveTag tag) {
    final color = tag.colorHex != null
        ? Color(int.parse(tag.colorHex!.replaceFirst('#', '0xFF')))
        : Colors.amber;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTagTransactions(tag),
        onLongPress: () => _showTagOptions(tag),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.label, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${tag.name}',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '使用 ${tag.usageCount} 次',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showTagTransactions(JiveTag tag) {
    // TODO: 跳转到该标签的交易列表
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看 #${tag.name} 的交易')),
    );
  }

  void _showTagOptions(JiveTag tag) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('设置颜色'),
              onTap: () {
                Navigator.pop(context);
                _showColorPicker(tag);
              },
            ),
            ListTile(
              leading: Icon(
                tag.isHidden ? Icons.visibility : Icons.visibility_off,
              ),
              title: Text(tag.isHidden ? '显示标签' : '隐藏标签'),
              onTap: () async {
                Navigator.pop(context);
                await TagService(_isar!).toggleHidden(tag);
                _loadTags();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('删除标签'),
                    content: Text('确定删除标签 #${tag.name}？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await TagService(_isar!).deleteTag(tag.id);
                  _loadTags();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(JiveTag tag) {
    final colors = [
      '#DCE775', // 嫩芽黄
      '#2E7D32', // 森林绿
      '#1976D2', // 蓝
      '#E53935', // 红
      '#FF9800', // 橙
      '#9C27B0', // 紫
      '#00BCD4', // 青
      '#795548', // 棕
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((hex) {
            final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
            final isSelected = tag.colorHex == hex;
            return GestureDetector(
              onTap: () async {
                await TagService(_isar!).updateTagColor(tag, hex);
                if (!mounted) return;
                Navigator.pop(context);
                _loadTags();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
