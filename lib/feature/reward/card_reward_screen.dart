import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/card_reward_model.dart';
import '../../core/service/card_reward_service.dart';
import '../../core/service/database_service.dart';

class CardRewardScreen extends StatefulWidget {
  const CardRewardScreen({super.key});

  @override
  State<CardRewardScreen> createState() => _CardRewardScreenState();
}

class _CardRewardScreenState extends State<CardRewardScreen> {
  late Isar _isar;
  late CardRewardService _service;
  bool _isLoading = true;
  List<JiveCardReward> _rewards = [];
  double _totalAllCards = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _isar = await DatabaseService.getInstance();
    _service = CardRewardService(_isar);
    await _load();
  }

  Future<void> _load() async {
    final rewards = await _service.getAllRewards();
    double total = 0;
    for (final r in rewards) {
      total += r.totalEarned;
    }
    if (!mounted) return;
    setState(() {
      _rewards = rewards;
      _totalAllCards = total;
      _isLoading = false;
    });
  }

  String _rewardTypeLabel(String type) {
    switch (type) {
      case RewardType.cashback:
        return '返现';
      case RewardType.points:
        return '积分';
      case RewardType.miles:
        return '里程';
      default:
        return type;
    }
  }

  Future<void> _showCreateEditDialog({JiveCardReward? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.accountName ?? '');
    final rateCtrl = TextEditingController(
      text: existing != null ? (existing.rewardRate * 100).toStringAsFixed(2) : '',
    );
    final capCtrl = TextEditingController(
      text: existing?.monthlyCapAmount?.toStringAsFixed(2) ?? '',
    );
    final accountIdCtrl = TextEditingController(
      text: existing?.accountId.toString() ?? '',
    );
    String rewardType = existing?.rewardType ?? RewardType.cashback;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          title: Text(existing != null ? '编辑奖励配置' : '新建奖励配置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: accountIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '账户 ID *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '信用卡名称 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: RewardType.cashback, label: Text('返现')),
                    ButtonSegment(value: RewardType.points, label: Text('积分')),
                    ButtonSegment(value: RewardType.miles, label: Text('里程')),
                  ],
                  selected: {rewardType},
                  onSelectionChanged: (s) => setLS(() => rewardType = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '回馈比率 (%) *',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '月度上限（留空表示无上限）',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
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
              child: Text(existing != null ? '保存' : '创建'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;

    final rate = (double.tryParse(rateCtrl.text) ?? 0) / 100;
    final cap = double.tryParse(capCtrl.text);
    final accountId = int.tryParse(accountIdCtrl.text) ?? 0;
    if (rate <= 0 || nameCtrl.text.trim().isEmpty || accountId <= 0) return;

    if (existing != null) {
      existing.accountName = nameCtrl.text.trim();
      existing.rewardRate = rate;
      existing.rewardType = rewardType;
      existing.monthlyCapAmount = cap;
      await _service.updateReward(existing);
    } else {
      await _service.createReward(
        accountId: accountId,
        accountName: nameCtrl.text.trim(),
        rewardRate: rate,
        rewardType: rewardType,
        monthlyCapAmount: cap,
      );
    }

    nameCtrl.dispose();
    rateCtrl.dispose();
    capCtrl.dispose();
    accountIdCtrl.dispose();
    await _load();
  }

  Future<void> _showRewardDetail(JiveCardReward reward) async {
    final summary = await _service.getRewardSummary(reward.accountId);
    if (!mounted || summary == null) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(reward.accountName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('奖励类型', _rewardTypeLabel(reward.rewardType)),
            _detailRow('回馈比率', '${(summary.rate * 100).toStringAsFixed(2)}%'),
            _detailRow('累计获得', '¥${summary.totalEarned.toStringAsFixed(2)}'),
            _detailRow('当月获得', '¥${summary.monthEarned.toStringAsFixed(2)}'),
            if (reward.monthlyCapAmount != null) ...[
              _detailRow('月度上限', '¥${reward.monthlyCapAmount!.toStringAsFixed(2)}'),
              _detailRow(
                '当月剩余',
                summary.monthlyRemaining == double.infinity
                    ? '无上限'
                    : '¥${summary.monthlyRemaining.toStringAsFixed(2)}',
              ),
            ],
            _detailRow('状态', reward.isEnabled ? '启用' : '停用'),
            _detailRow('创建于', DateFormat('yyyy-MM-dd').format(reward.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showCreateEditDialog(existing: reward);
            },
            child: const Text('编辑'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _deleteReward(JiveCardReward reward) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除奖励配置'),
        content: Text('确定删除「${reward.accountName}」的奖励配置？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteReward(reward.id);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(
        title: Text('信用卡奖励', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '累计奖励总额',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${fmt.format(_totalAllCards)}',
                        style: GoogleFonts.rubik(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_rewards.length} 张信用卡',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Per-card list
                Expanded(
                  child: _rewards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.credit_card_outlined,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('暂无信用卡奖励配置',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _rewards.length,
                          itemBuilder: (context, index) {
                            final reward = _rewards[index];
                            return _buildRewardCard(reward, fmt);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRewardCard(JiveCardReward reward, NumberFormat fmt) {
    final progress = reward.monthlyCapAmount != null && reward.monthlyCapAmount! > 0
        ? (reward.monthEarned / reward.monthlyCapAmount!).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRewardDetail(reward),
        onLongPress: () => _deleteReward(reward),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                    child: const Icon(Icons.credit_card, color: Color(0xFF6A1B9A), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.accountName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text(
                          '${_rewardTypeLabel(reward.rewardType)} · ${(reward.rewardRate * 100).toStringAsFixed(2)}%',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${fmt.format(reward.totalEarned)}',
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6A1B9A),
                        ),
                      ),
                      Text('累计', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              if (reward.monthlyCapAmount != null) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6A1B9A)),
                ),
                const SizedBox(height: 4),
                Text(
                  '当月 ¥${fmt.format(reward.monthEarned)} / ¥${fmt.format(reward.monthlyCapAmount!)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  '当月 ¥${fmt.format(reward.monthEarned)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
