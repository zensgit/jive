import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/screenshot_ocr_service.dart';
import '../../core/service/transaction_service.dart';

class ScreenshotImportScreen extends StatefulWidget {
  const ScreenshotImportScreen({super.key});

  @override
  State<ScreenshotImportScreen> createState() =>
      _ScreenshotImportScreenState();
}

class _ScreenshotImportScreenState extends State<ScreenshotImportScreen> {
  final ScreenshotOcrService _ocrService = ScreenshotOcrService();
  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  ScreenshotParseResult? _result;
  bool _isProcessing = false;
  String? _errorMessage;

  // Editable controllers
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _dateController = TextEditingController();
  PaymentSource _selectedSource = PaymentSource.unknown;
  DateTime? _parsedDate;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _imagePath = file.path;
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _runOcr() async {
    if (_imagePath == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _ocrService.parsePaymentScreenshot(_imagePath!);
      if (result == null) {
        setState(() {
          _errorMessage = '未能识别出支付信息，请确认截图内容';
          _isProcessing = false;
        });
        return;
      }

      _result = result;
      _amountController.text = result.amount.toStringAsFixed(2);
      _merchantController.text = result.merchant ?? '';
      _parsedDate = result.timestamp ?? DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_parsedDate!);
      _selectedSource = result.source;

      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() {
        _errorMessage = '识别失败: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('请输入有效金额');
      return;
    }

    final isar = await DatabaseService.getInstance();
    final tx = JiveTransaction()
      ..amount = amount
      ..source = _sourceLabel(_selectedSource)
      ..timestamp = _parsedDate ?? DateTime.now()
      ..rawText = _result?.rawText
      ..note = _merchantController.text.isNotEmpty ? _merchantController.text : null
      ..type = 'expense';

    TransactionService.touchSyncMetadata(tx);

    await isar.writeTxn(() async {
      await isar.jiveTransactions.put(tx);
    });

    if (!mounted) return;
    _showSnackBar('已记录');
    Navigator.of(context).pop();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _sourceLabel(PaymentSource source) {
    switch (source) {
      case PaymentSource.wechat:
        return '微信支付';
      case PaymentSource.alipay:
        return '支付宝';
      case PaymentSource.unknown:
        return '未知';
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _parsedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_parsedDate ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _parsedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_parsedDate!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('截图导入')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview or placeholder
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_imagePath!),
                  height: 240,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 8),
                      Text('选择支付截图', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(_imagePath == null ? '选择截图' : '重新选择'),
                  ),
                ),
                if (_imagePath != null && _result == null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _runOcr,
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text('识别'),
                    ),
                  ),
                ],
              ],
            ),

            // Loading
            if (_isProcessing) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Center(
                child: Text('正在识别...', style: theme.textTheme.bodyMedium),
              ),
            ],

            // Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],

            // Result card
            if (_result != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('识别结果', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),

                      // Amount
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: '金额',
                          prefixText: '¥ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),

                      // Merchant
                      TextField(
                        controller: _merchantController,
                        decoration: const InputDecoration(
                          labelText: '商户',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date
                      TextField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          labelText: '日期',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Source selector
                      DropdownButtonFormField<PaymentSource>(
                        initialValue: _selectedSource,
                        decoration: const InputDecoration(
                          labelText: '来源',
                          border: OutlineInputBorder(),
                        ),
                        items: PaymentSource.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(_sourceLabel(s)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedSource = v);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveTransaction,
                          icon: const Icon(Icons.check),
                          label: const Text('记录'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
