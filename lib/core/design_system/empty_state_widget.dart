import 'package:flutter/material.dart';

import 'theme.dart';

/// Reusable empty state widget with animated entrance and optional action.
class JiveEmptyState extends StatefulWidget {
  /// The icon to display prominently.
  final IconData icon;

  /// Primary title text.
  final String title;

  /// Optional descriptive subtitle.
  final String? subtitle;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback when the action button is tapped.
  final VoidCallback? onAction;

  const JiveEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  // ---------------------------------------------------------------------------
  // Preset constructors
  // ---------------------------------------------------------------------------

  /// 交易记录为空
  factory JiveEmptyState.transactions({Key? key, VoidCallback? onAction}) {
    return JiveEmptyState(
      key: key,
      icon: Icons.receipt_long_outlined,
      title: '还没有交易记录',
      subtitle: '点击下方按钮开始记录你的第一笔交易',
      actionLabel: '记一笔',
      onAction: onAction,
    );
  }

  /// 预算为空
  factory JiveEmptyState.budgets({Key? key, VoidCallback? onAction}) {
    return JiveEmptyState(
      key: key,
      icon: Icons.account_balance_wallet_outlined,
      title: '还没有预算',
      subtitle: '制定预算帮助你更好地管理支出',
      actionLabel: '创建预算',
      onAction: onAction,
    );
  }

  /// 储蓄目标为空
  factory JiveEmptyState.goals({Key? key, VoidCallback? onAction}) {
    return JiveEmptyState(
      key: key,
      icon: Icons.flag_outlined,
      title: '还没有储蓄目标',
      subtitle: '设定一个目标，开始你的储蓄计划',
      actionLabel: '设定目标',
      onAction: onAction,
    );
  }

  /// 统计数据不足
  factory JiveEmptyState.stats({Key? key, VoidCallback? onAction}) {
    return JiveEmptyState(
      key: key,
      icon: Icons.bar_chart_outlined,
      title: '数据不足',
      subtitle: '记录更多交易后即可查看统计分析',
      actionLabel: '开始记账',
      onAction: onAction,
    );
  }

  /// 搜索无结果
  factory JiveEmptyState.search({Key? key}) {
    return JiveEmptyState(
      key: key,
      icon: Icons.search_off_outlined,
      title: '未找到结果',
      subtitle: '试试其他关键词吧',
    );
  }

  /// 共享账本为空
  factory JiveEmptyState.shared({Key? key, VoidCallback? onAction}) {
    return JiveEmptyState(
      key: key,
      icon: Icons.people_outline,
      title: '还没有共享账本',
      subtitle: '邀请家人或朋友一起记账',
      actionLabel: '创建或加入',
      onAction: onAction,
    );
  }

  @override
  State<JiveEmptyState> createState() => _JiveEmptyStateState();
}

class _JiveEmptyStateState extends State<JiveEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance: fade + slide up over 300ms.
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    ));

    // Subtle bounce on the icon (repeats).
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    _entranceController.forward();
    _bounceController.repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secondaryText = JiveTheme.secondaryTextColor(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                ScaleTransition(
                  scale: _bounceAnimation,
                  child: Icon(
                    widget.icon,
                    size: 64,
                    color: secondaryText.withAlpha(153), // ~60 %
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),

                // Subtitle
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: secondaryText,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Action button
                if (widget.actionLabel != null) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: widget.onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: JiveTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
