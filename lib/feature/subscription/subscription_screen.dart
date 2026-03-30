import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/theme.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../core/entitlement/user_tier.dart';
import '../../core/payment/payment_service.dart';
import '../../core/payment/product_ids.dart';

/// Subscription comparison screen showing the 3-tier plan.
///
/// Upgrade buttons call [PaymentService.purchase] with the correct product ID.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<EntitlementService>();
    final currentTier = entitlement.tier;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('升级方案', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildCurrentTierBanner(currentTier),
          const SizedBox(height: 20),
          _PlanCard(
            tier: UserTier.free,
            isCurrent: currentTier == UserTier.free,
            price: '免费',
            features: const [
              '手动记账',
              '分类与标签管理',
              '基础统计图表',
              '含广告',
            ],
            lockedFeatures: const [
              '自动记账',
              '多币种',
              'CSV 导出',
              '云同步',
            ],
          ),
          const SizedBox(height: 16),
          _PlanCard(
            tier: UserTier.paid,
            isCurrent: currentTier == UserTier.paid,
            price: '¥28 一次性',
            highlight: true,
            features: const [
              '包含免费版全部功能',
              '无广告',
              '自动记账（通知监听）',
              '多币种与汇率',
              'CSV 导出',
              '预算管理（不限数量）',
              '周期记账',
              '项目追踪',
              'AA 分账',
              '借贷管理',
              '商户记忆',
            ],
            lockedFeatures: const [
              '云同步',
              '多设备',
              '投资追踪',
            ],
          ),
          const SizedBox(height: 16),
          _PlanCard(
            tier: UserTier.subscriber,
            isCurrent: currentTier == UserTier.subscriber,
            price: '¥8/月 或 ¥68/年',
            features: const [
              '包含专业版全部功能',
              '云同步与多设备',
              '投资组合追踪',
              '高级分析与报告',
              '储蓄目标',
              'PDF 年度报告',
              '语音记账',
              '优先客服支持',
            ],
            lockedFeatures: const [],
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () => _restorePurchases(context),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('恢复购买'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases(BuildContext context) async {
    final payment = context.read<PaymentService>();
    if (!payment.isAvailable) {
      _showSnackBar(context, '支付服务暂不可用');
      return;
    }
    final result = await payment.restorePurchases();
    if (!context.mounted) return;
    if (result.success) {
      _showSnackBar(context, '恢复购买成功');
    } else {
      _showSnackBar(context, result.errorMessage ?? '恢复购买失败');
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildCurrentTierBanner(UserTier tier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JiveTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: JiveTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前方案', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  tier.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: JiveTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  final UserTier tier;
  final bool isCurrent;
  final String price;
  final bool highlight;
  final List<String> features;
  final List<String> lockedFeatures;

  const _PlanCard({
    required this.tier,
    required this.isCurrent,
    required this.price,
    this.highlight = false,
    required this.features,
    required this.lockedFeatures,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _loading = false;

  Future<void> _handlePurchase(String productId, String tierLabel) async {
    final payment = context.read<PaymentService>();
    if (!payment.isAvailable) {
      SubscriptionScreen._showSnackBar(context, '支付服务暂不可用');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await payment.purchase(productId);
      if (!mounted) return;
      if (result.success) {
        SubscriptionScreen._showSnackBar(context, '已升级到 $tierLabel');
        Navigator.of(context).pop();
      } else {
        SubscriptionScreen._showSnackBar(
          context,
          result.errorMessage ?? '购买失败',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Look up the store price for [productId], falling back to [fallback].
  String _storePrice(PaymentService payment, String productId, String fallback) {
    if (!payment.isReady) return fallback;
    final products = payment.products;
    for (final p in products) {
      if (p.id == productId) return p.price;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentService>();
    final borderColor = widget.highlight
        ? JiveTheme.primaryGreen
        : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: widget.highlight ? 2 : 1),
      ),
      child: Column(
        children: [
          if (widget.highlight)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Text(
                '最受欢迎',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.tier.label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '当前',
                          style: TextStyle(
                            color: JiveTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.price,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.highlight ? JiveTheme.primaryGreen : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...widget.features.map((f) => _FeatureRow(text: f, included: true)),
                ...widget.lockedFeatures.map((f) => _FeatureRow(text: f, included: false)),
                if (!widget.isCurrent && widget.tier != UserTier.free) ...[
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (widget.tier == UserTier.subscriber)
                    _buildSubscriberButtons(payment)
                  else
                    _buildSingleButton(payment),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleButton(PaymentService payment) {
    final priceLabel = _storePrice(payment, ProductIds.paidUnlock, '¥28');
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => _handlePurchase(
          ProductIds.paidUnlock,
          widget.tier.label,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: widget.highlight
              ? JiveTheme.primaryGreen
              : Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '$priceLabel 升级到${widget.tier.label}',
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildSubscriberButtons(PaymentService payment) {
    final monthlyPrice = _storePrice(
      payment,
      ProductIds.subscriberMonthly,
      '¥8/月',
    );
    final yearlyPrice = _storePrice(
      payment,
      ProductIds.subscriberYearly,
      '¥68/年',
    );

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _handlePurchase(
              ProductIds.subscriberMonthly,
              widget.tier.label,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '$monthlyPrice 订阅',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _handlePurchase(
              ProductIds.subscriberYearly,
              widget.tier.label,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: JiveTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '$yearlyPrice 订阅（推荐）',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final bool included;

  const _FeatureRow({required this.text, required this.included});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: included ? JiveTheme.primaryGreen : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: included ? Colors.black87 : Colors.grey.shade400,
                decoration: included ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
