import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/invoice_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/invoice_service.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late Isar _isar;
  late InvoiceService _service;
  bool _isLoading = true;
  List<JiveInvoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _isar = await DatabaseService.getInstance();
    _service = InvoiceService(_isar);
    await _load();
  }

  Future<void> _load() async {
    final all = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _invoices = all;
      _isLoading = false;
    });
  }

  Future<void> _scanQR() async {
    final qrCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('扫描发票'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入或粘贴 QR 码数据'),
            const SizedBox(height: 12),
            TextField(
              controller: qrCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'QR 码内容...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (ok == true && qrCtrl.text.trim().isNotEmpty) {
      await _service.createFromQR(qrCtrl.text.trim());
      await _load();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await _service.createFromImage(image.path);
      await _load();
    }
  }

  Future<void> _linkToTransaction(JiveInvoice invoice) async {
    final txs = await _isar.jiveTransactions
        .where()
        .sortByTimestampDesc()
        .limit(50)
        .findAll();

    if (!mounted) return;
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无交易可关联')),
      );
      return;
    }

    final selected = await showDialog<JiveTransaction>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择关联交易'),
        children: txs.map((tx) {
          final date = DateFormat('MM-dd').format(tx.timestamp);
          final cat = tx.category ?? '';
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, tx),
            child: ListTile(
              dense: true,
              title: Text('$cat  ${tx.amount.toStringAsFixed(2)}'),
              subtitle: Text('$date  ${tx.note ?? ''}'),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      await _service.linkToTransaction(invoice.id, selected.id);
      await _load();
    }
  }

  Future<void> _showDetail(JiveInvoice invoice) async {
    JiveTransaction? linkedTx;
    if (invoice.transactionId != null) {
      linkedTx = await _isar.jiveTransactions.get(invoice.transactionId!);
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '发票详情',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _detailRow('发票号', invoice.invoiceNumber),
            if (invoice.vendorName != null)
              _detailRow('商户', invoice.vendorName!),
            if (invoice.amount != null)
              _detailRow('金额', invoice.amount!.toStringAsFixed(2)),
            if (invoice.invoiceDate != null)
              _detailRow(
                  '发票日期', DateFormat('yyyy-MM-dd').format(invoice.invoiceDate!)),
            _detailRow('状态', _statusLabel(invoice.status)),
            _detailRow(
                '创建时间', DateFormat('yyyy-MM-dd HH:mm').format(invoice.createdAt)),
            if (linkedTx != null) ...[
              const Divider(height: 24),
              Text('关联交易', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              _detailRow('金额', linkedTx.amount.toStringAsFixed(2)),
              _detailRow('分类', linkedTx.category ?? '-'),
              _detailRow(
                  '日期', DateFormat('yyyy-MM-dd').format(linkedTx.timestamp)),
            ],
            if (invoice.imagePath != null) ...[
              const Divider(height: 24),
              Text('收据照片', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(invoice.imagePath!),
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(child: Text('图片无法加载')),
                  ),
                ),
              ),
            ],
            if (invoice.qrData != null) ...[
              const Divider(height: 24),
              _detailRow('QR 数据', invoice.qrData!),
            ],
            const SizedBox(height: 16),
            if (invoice.status == 'pending')
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _linkToTransaction(invoice);
                },
                icon: const Icon(Icons.link),
                label: const Text('关联交易'),
              ),
            const SizedBox(height: 8),
            if (invoice.status != 'archived')
              OutlinedButton.icon(
                onPressed: () async {
                  await _service.archive(invoice.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                },
                icon: const Icon(Icons.archive_outlined),
                label: const Text('归档'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return '待关联';
      case 'linked':
        return '已关联';
      case 'archived':
        return '已归档';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'linked':
        return Colors.green;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('发票/收据'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: '拍照录入',
            onPressed: _pickImage,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanQR,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('扫描发票'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('暂无发票', style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      Text('点击下方按钮扫描发票 QR 码',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final inv = _invoices[i];
                      final isUnlinked = inv.status == 'pending';
                      return Card(
                        elevation: isUnlinked ? 2 : 0.5,
                        color: isUnlinked
                            ? theme.colorScheme.errorContainer.withValues(alpha: 0.15)
                            : null,
                        child: ListTile(
                          leading: Icon(
                            inv.imagePath != null
                                ? Icons.photo_outlined
                                : Icons.qr_code,
                            color: _statusColor(inv.status),
                          ),
                          title: Text(
                            inv.vendorName ?? inv.invoiceNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              if (inv.amount != null)
                                inv.amount!.toStringAsFixed(2),
                              DateFormat('MM-dd').format(inv.createdAt),
                            ].join('  '),
                          ),
                          trailing: Chip(
                            label: Text(
                              _statusLabel(inv.status),
                              style: TextStyle(
                                fontSize: 11,
                                color: _statusColor(inv.status),
                              ),
                            ),
                            backgroundColor:
                                _statusColor(inv.status).withValues(alpha: 0.12),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () => _showDetail(inv),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
