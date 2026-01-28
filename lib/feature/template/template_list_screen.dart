import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/template_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/service/template_service.dart';
import '../../core/design_system/theme.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  Isar? _isar;
  bool _isLoading = true;
  Map<String, List<JiveTemplate>> _groupedTemplates = {};

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    final isar = await _ensureIsar();
    final service = TemplateService(isar);
    final grouped = await service.getTemplatesGrouped();

    if (!mounted) return;
    setState(() {
      _groupedTemplates = grouped;
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
      ],
      directory: dir.path,
    );
    return _isar!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易模板'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: JiveTheme.surfaceWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedTemplates.isEmpty
              ? _buildEmptyState()
              : _buildTemplateList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '暂无模板',
            style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '在交易详情中点击"模板"按钮保存',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList() {
    final groups = _groupedTemplates.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final templates = _groupedTemplates[group]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                group,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ...templates.map((t) => _buildTemplateCard(t)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTemplateCard(JiveTemplate template) {
    final typeIcon = template.type == 'income'
        ? Icons.arrow_downward
        : template.type == 'transfer'
            ? Icons.swap_horiz
            : Icons.arrow_upward;
    final typeColor = template.type == 'income'
        ? Colors.green
        : template.type == 'transfer'
            ? Colors.blueGrey
            : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _useTemplate(template),
        onLongPress: () => _showTemplateOptions(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (template.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: JiveTheme.primaryGreen,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            template.name,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${template.category ?? '未分类'} · 使用 ${template.usageCount} 次',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                template.amount > 0
                    ? '¥${template.amount.toStringAsFixed(2)}'
                    : '金额待输入',
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: template.amount > 0 ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _useTemplate(JiveTemplate template) {
    Navigator.pop(context, template);
  }

  void _showTemplateOptions(JiveTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                template.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(template.isPinned ? '取消置顶' : '置顶'),
              onTap: () async {
                Navigator.pop(context);
                await TemplateService(_isar!).togglePin(template);
                _loadTemplates();
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
                    title: const Text('删除模板'),
                    content: Text('确定删除模板"${template.name}"？'),
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
                  await TemplateService(_isar!).deleteTemplate(template.id);
                  _loadTemplates();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
