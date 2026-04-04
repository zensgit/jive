import 'dart:async';

import 'package:flutter/material.dart';

import 'anomaly_detection_service.dart';

/// 异常通知渠道
enum AnomalyNotificationChannel {
  /// 消费异常通知（高优先级）
  spendingAnomaly,

  /// 预算提醒通知（默认优先级）
  budgetAlert,
}

/// 内部通知数据
class AnomalyNotification {
  final String title;
  final String body;
  final AnomalyNotificationChannel channel;
  final AnomalySeverity severity;
  final DateTime createdAt;

  const AnomalyNotification({
    required this.title,
    required this.body,
    required this.channel,
    required this.severity,
    required this.createdAt,
  });
}

/// 消费异常通知服务
///
/// 使用应用内 Overlay/SnackBar 展示通知（无需 flutter_local_notifications）。
/// 提供全局回调让 UI 层监听并展示通知。
class AnomalyNotificationService {
  AnomalyNotificationService._();

  static final AnomalyNotificationService _instance =
      AnomalyNotificationService._();

  /// 单例实例
  static AnomalyNotificationService get instance => _instance;

  /// 通知事件流，UI 层监听此流来展示通知。
  final StreamController<AnomalyNotification> _notificationController =
      StreamController<AnomalyNotification>.broadcast();

  /// 通知事件流
  Stream<AnomalyNotification> get notifications =>
      _notificationController.stream;

  bool _initialized = false;

  /// 初始化通知服务
  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  /// 释放资源
  void dispose() {
    _notificationController.close();
  }

  /// 发送消费异常通知
  void notifyAnomaly(SpendingAnomaly anomaly) {
    if (!_initialized) return;

    final channel = anomaly.type == AnomalyType.budgetExceeded
        ? AnomalyNotificationChannel.budgetAlert
        : AnomalyNotificationChannel.spendingAnomaly;

    final notification = AnomalyNotification(
      title: anomaly.title,
      body: anomaly.description,
      channel: channel,
      severity: anomaly.severity,
      createdAt: DateTime.now(),
    );

    _notificationController.add(notification);
  }

  /// 发送预算预警通知
  void notifyBudgetWarning(String budgetName, double usedPercent) {
    if (!_initialized) return;

    final severity = usedPercent >= 100
        ? AnomalySeverity.critical
        : usedPercent >= 90
            ? AnomalySeverity.warning
            : AnomalySeverity.info;

    final notification = AnomalyNotification(
      title: '预算预警',
      body: '「$budgetName」已使用 ${usedPercent.toStringAsFixed(0)}%',
      channel: AnomalyNotificationChannel.budgetAlert,
      severity: severity,
      createdAt: DateTime.now(),
    );

    _notificationController.add(notification);
  }

  /// 在 BuildContext 中展示异常通知（SnackBar 形式）
  static void showNotificationSnackBar(
    BuildContext context,
    AnomalyNotification notification,
  ) {
    final Color backgroundColor;
    final IconData icon;

    switch (notification.severity) {
      case AnomalySeverity.critical:
        backgroundColor = Colors.red.shade700;
        icon = Icons.error;
      case AnomalySeverity.warning:
        backgroundColor = Colors.orange.shade700;
        icon = Icons.warning_amber_rounded;
      case AnomalySeverity.info:
        backgroundColor = Colors.blue.shade600;
        icon = Icons.info_outline;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: notification.severity == AnomalySeverity.critical
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
