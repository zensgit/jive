import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/pdf_report_service.dart';

/// Screen to generate and preview/share annual PDF report.
class AnnualReportScreen extends StatefulWidget {
  const AnnualReportScreen({super.key});

  @override
  State<AnnualReportScreen> createState() => _AnnualReportScreenState();
}

class _AnnualReportScreenState extends State<AnnualReportScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('年度报告', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year selector
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择年份',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: years.map((year) => ChoiceChip(
                      label: Text('$year'),
                      selected: _selectedYear == year,
                      selectedColor: JiveTheme.primaryGreen.withAlpha(40),
                      onSelected: (_) => setState(() => _selectedYear = year),
                      labelStyle: TextStyle(
                        color: _selectedYear == year ? JiveTheme.primaryGreen : Colors.grey.shade700,
                        fontWeight: _selectedYear == year ? FontWeight.w600 : FontWeight.normal,
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Report description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('报告内容', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  _contentRow(Icons.summarize, '年度总览', '总收入、总支出、结余、储蓄率、净资产'),
                  _contentRow(Icons.calendar_month, '月度明细', '每月收入、支出、结余、交易笔数'),
                  _contentRow(Icons.pie_chart, '分类排行', '支出 Top 10 分类及占比'),
                  _contentRow(Icons.lightbulb, '财务洞察', '月均数据、最佳/最差月份、储蓄建议'),
                ],
              ),
            ),
            const Spacer(),

            // Generate buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _previewReport,
                    icon: const Icon(Icons.visibility),
                    label: const Text('预览'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isGenerating ? null : _shareReport,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share),
                    label: Text(_isGenerating ? '生成中...' : '导出分享'),
                    style: FilledButton.styleFrom(
                      backgroundColor: JiveTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _contentRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: JiveTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewReport() async {
    setState(() => _isGenerating = true);
    try {
      final pdfData = await PdfReportService.generateAnnualReport(_selectedYear);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('$_selectedYear 年度报告')),
            body: PdfPreview(
              build: (_) => pdfData,
              canChangePageFormat: false,
              canChangeOrientation: false,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareReport() async {
    setState(() => _isGenerating = true);
    try {
      final pdfData = await PdfReportService.generateAnnualReport(_selectedYear);
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'Jive_${_selectedYear}_Annual_Report.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
