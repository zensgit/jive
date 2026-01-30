import 'package:flutter/material.dart';

/// 应用内通知服务（无需原生依赖）
class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  final List<InAppNotification> _pendingNotifications = [];

  /// 添加待显示的通知
  void addNotification(InAppNotification notification) {
    _pendingNotifications.add(notification);
  }

  /// 获取并清除待显示的通知
  List<InAppNotification> consumePendingNotifications() {
    final notifications = List<InAppNotification>.from(_pendingNotifications);
    _pendingNotifications.clear();
    return notifications;
  }

  /// 是否有待显示的通知
  bool get hasPendingNotifications => _pendingNotifications.isNotEmpty;

  /// 显示汇率变动通知
  static void showRateChangeNotification(
    BuildContext context, {
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _RateChangeNotificationWidget(
        title: title,
        body: body,
        onTap: onTap,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // 5秒后自动移除
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  /// 显示简单的 SnackBar 通知
  static void showSnackBarNotification(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }
}

/// 应用内通知数据模型
class InAppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationType type;
  final Map<String, dynamic>? data;

  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    DateTime? createdAt,
    this.data,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// 通知类型
enum NotificationType {
  rateChange,
  rateUpdate,
  alert,
  info,
}

/// 汇率变动通知组件
class _RateChangeNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _RateChangeNotificationWidget({
    required this.title,
    required this.body,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<_RateChangeNotificationWidget> createState() => _RateChangeNotificationWidgetState();
}

class _RateChangeNotificationWidgetState extends State<_RateChangeNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: InkWell(
              onTap: () {
                widget.onTap?.call();
                _dismiss();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.currency_exchange,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.body,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _dismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 汇率变动通知管理器
class RateChangeNotificationManager {
  /// 检查并显示汇率变动通知
  static void checkAndShowNotifications(
    BuildContext context,
    List<RateChangeNotification> changes,
  ) {
    if (changes.isEmpty) return;

    final significantChanges = changes.where((c) => c.isSignificant).toList();
    if (significantChanges.isEmpty) return;

    // 显示第一个显著变动的通知
    final firstChange = significantChanges.first;
    InAppNotificationService.showRateChangeNotification(
      context,
      title: '汇率变动提醒',
      body: '${firstChange.fromCurrency}/${firstChange.toCurrency} ${firstChange.changeText}',
      onTap: () {
        // 可以导航到汇率详情页
      },
    );

    // 如果有多个变动，显示汇总
    if (significantChanges.length > 1) {
      Future.delayed(const Duration(seconds: 6), () {
        if (context.mounted) {
          InAppNotificationService.showSnackBarNotification(
            context,
            message: '共有 ${significantChanges.length} 个货币对发生显著变动',
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: '查看',
              textColor: Colors.white,
              onPressed: () {
                // 可以导航到汇率列表
              },
            ),
          );
        }
      });
    }
  }
}

/// 汇率变动通知数据
class RateChangeNotification {
  final String fromCurrency;
  final String toCurrency;
  final double oldRate;
  final double newRate;
  final double threshold;

  RateChangeNotification({
    required this.fromCurrency,
    required this.toCurrency,
    required this.oldRate,
    required this.newRate,
    this.threshold = 1.0,
  });

  double get changePercent => ((newRate - oldRate) / oldRate * 100).abs();

  bool get isIncrease => newRate > oldRate;

  bool get isSignificant => changePercent >= threshold;

  String get changeText {
    final sign = isIncrease ? '+' : '-';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }
}
