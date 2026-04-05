import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/travel_trip_model.dart';
import '../../core/service/travel_service.dart';

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------
const _kPrimary = Color(0xFF1565C0);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
final _dateFmt = DateFormat('yyyy-MM-dd');

String _statusLabel(String status) {
  switch (status) {
    case 'planning':
      return '计划中';
    case 'active':
      return '进行中';
    case 'completed':
      return '已完成';
    case 'reviewed':
      return '已回顾';
    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'planning':
      return Colors.orange;
    case 'active':
      return Colors.green;
    case 'completed':
      return Colors.blueGrey;
    case 'reviewed':
      return Colors.purple;
    default:
      return Colors.grey;
  }
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  late final TravelService _service;
  List<JiveTravelTrip> _trips = [];
  JiveTravelTrip? _activeTrip;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = TravelService(Isar.getInstance()!);
    _load();
  }

  Future<void> _load() async {
    final trips = await _service.getAllTrips();
    final active = await _service.getActiveTrip();
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _activeTrip = active;
      _loading = false;
    });
  }

  // ---- Create trip dialog ----
  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final currencyCtrl = TextEditingController(text: 'CNY');
    DateTime? startDate;
    DateTime? endDate;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('新建旅行'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: '旅行名称'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: destCtrl,
                      decoration: const InputDecoration(labelText: '目的地'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: budgetCtrl,
                      decoration: const InputDecoration(labelText: '预算（可选）'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: currencyCtrl,
                      decoration: const InputDecoration(labelText: '基础货币'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => startDate = picked);
                              }
                            },
                            child: Text(
                              startDate != null
                                  ? _dateFmt.format(startDate!)
                                  : '开始日期',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate:
                                    startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => endDate = picked);
                              }
                            },
                            child: Text(
                              endDate != null
                                  ? _dateFmt.format(endDate!)
                                  : '结束日期',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true) return;

    final name = nameCtrl.text.trim();
    final dest = destCtrl.text.trim();
    if (name.isEmpty || dest.isEmpty) return;

    final budget = double.tryParse(budgetCtrl.text.trim());
    await _service.createTrip(
      name: name,
      destination: dest,
      budget: budget,
      baseCurrency: currencyCtrl.text.trim(),
      startDate: startDate,
      endDate: endDate,
    );
    await _load();
  }

  // ---- Trip detail screen ----
  void _openDetail(JiveTravelTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TripDetailScreen(
          tripId: trip.id,
          onChanged: _load,
        ),
      ),
    );
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '旅行模式',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flight_takeoff,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('暂无旅行',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('点击 + 创建第一个���行计划',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_activeTrip != null) ...[
                        _ActiveTripCard(
                          trip: _activeTrip!,
                          onTap: () => _openDetail(_activeTrip!),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ..._trips
                          .where((t) => t.id != _activeTrip?.id)
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TripCard(
                                  trip: t,
                                  onTap: () => _openDetail(t),
                                ),
                              )),
                    ],
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active trip card with progress bar
// ---------------------------------------------------------------------------
class _ActiveTripCard extends StatelessWidget {
  final JiveTravelTrip trip;
  final VoidCallback onTap;

  const _ActiveTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = trip.startDate ?? trip.createdAt;
    final end = trip.endDate;

    double progress = 0;
    String progressText = '';
    if (end != null) {
      final totalDays = end.difference(start).inDays;
      final elapsed = now.difference(start).inDays;
      if (totalDays > 0) {
        progress = (elapsed / totalDays).clamp(0.0, 1.0);
        progressText = '$elapsed / $totalDays 天';
      }
    } else {
      final elapsed = now.difference(start).inDays;
      progressText = '已 $elapsed ���';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _kPrimary,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flight, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.name,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(trip.status),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                trip.destination,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (end != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                progressText,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (trip.budget != null) ...[
                const SizedBox(height: 4),
                Text(
                  '预算: ${trip.baseCurrency} ${trip.budget!.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Regular trip card
// ---------------------------------------------------------------------------
class _TripCard extends StatelessWidget {
  final JiveTravelTrip trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateRange = [
      if (trip.startDate != null) _dateFmt.format(trip.startDate!),
      if (trip.endDate != null) _dateFmt.format(trip.endDate!),
    ].join(' ~ ');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _statusColor(trip.status).withAlpha(30),
                child: Icon(Icons.flight_takeoff,
                    color: _statusColor(trip.status), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(trip.destination,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                    if (dateRange.isNotEmpty)
                      Text(dateRange,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(trip.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(trip.status),
                  style: TextStyle(
                    color: _statusColor(trip.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trip detail screen
// ---------------------------------------------------------------------------
class _TripDetailScreen extends StatefulWidget {
  final int tripId;
  final Future<void> Function() onChanged;

  const _TripDetailScreen({
    required this.tripId,
    required this.onChanged,
  });

  @override
  State<_TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<_TripDetailScreen> {
  late final TravelService _service;
  JiveTravelTrip? _trip;
  TripSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = TravelService(Isar.getInstance()!);
    _load();
  }

  Future<void> _load() async {
    final trip = await _service.getTrip(widget.tripId);
    TripSummary? summary;
    if (trip != null) {
      summary = await _service.getTripSummary(widget.tripId);
    }
    if (!mounted) return;
    setState(() {
      _trip = trip;
      _summary = summary;
      _loading = false;
    });
  }

  Future<void> _startTrip() async {
    await _service.startTrip(widget.tripId);
    await _load();
    await widget.onChanged();
  }

  Future<void> _completeTrip() async {
    await _service.completeTrip(widget.tripId);
    await _load();
    await widget.onChanged();
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除旅行'),
        content: const Text('确定要删除此旅行��？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteTrip(widget.tripId);
    await widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('旅行详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final trip = _trip;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('旅行详情')),
        body: const Center(child: Text('旅行不存在')),
      );
    }

    final summary = _summary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          trip.name,
          style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteTrip,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Info card ---
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, color: _kPrimary, size: 20),
                      const SizedBox(width: 6),
                      Text(trip.destination,
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (trip.startDate != null || trip.endDate != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          [
                            if (trip.startDate != null)
                              _dateFmt.format(trip.startDate!),
                            if (trip.endDate != null)
                              _dateFmt.format(trip.endDate!),
                          ].join(' ~ '),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  if (trip.budget != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          '预算: ${trip.baseCurrency} ${trip.budget!.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                  if (trip.note != null && trip.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(trip.note!,
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 16),
                  // Status action buttons
                  if (trip.status == 'planning')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _startTrip,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('开始旅行'),
                      ),
                    ),
                  if (trip.status == 'active')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _completeTrip,
                        icon: const Icon(Icons.check),
                        label: const Text('结束旅行'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- Summary card ---
          if (summary != null) ...[
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('消费概览',
                        style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _SummaryRow(
                        label: '总支出',
                        value:
                            '${trip.baseCurrency} ${summary.totalExpense.toStringAsFixed(2)}'),
                    _SummaryRow(
                        label: '天数', value: '${summary.daysCount} 天'),
                    _SummaryRow(
                        label: '日均',
                        value:
                            '${trip.baseCurrency} ${summary.dailyAverage.toStringAsFixed(2)}'),
                    if (trip.budget != null && trip.budget! > 0) ...[
                      const Divider(height: 20),
                      _SummaryRow(
                        label: '预算使用',
                        value:
                            '${(summary.totalExpense / trip.budget! * 100).toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (summary.totalExpense / trip.budget!)
                              .clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          color: summary.totalExpense > trip.budget!
                              ? Colors.redAccent
                              : _kPrimary,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // --- Category breakdown ---
            if (summary.byCategory.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('分类明细',
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...summary.byCategory.entries.map(
                        (e) => _CategoryBar(
                          category: e.key,
                          amount: e.value,
                          total: summary.totalExpense,
                          currency: trip.baseCurrency,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small widgets
// ---------------------------------------------------------------------------
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final String currency;

  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontSize: 13)),
              Text('$currency ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey[200],
              color: _kPrimary,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
