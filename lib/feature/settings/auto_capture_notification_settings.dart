import 'package:flutter/material.dart';

import '../../core/service/auto_capture_notification_service.dart';

/// A self-contained settings section widget that lets the user toggle the
/// auto-capture persistent notification and see a preview of what it looks
/// like.
class AutoCaptureNotificationSettings extends StatefulWidget {
  const AutoCaptureNotificationSettings({super.key});

  @override
  State<AutoCaptureNotificationSettings> createState() =>
      _AutoCaptureNotificationSettingsState();
}

class _AutoCaptureNotificationSettingsState
    extends State<AutoCaptureNotificationSettings> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await AutoCaptureNotificationService.instance
        .isStatusNotificationEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await AutoCaptureNotificationService.instance
        .setStatusNotificationEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              '通知栏状态',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('显示通知栏状态'),
            subtitle: const Text('在通知栏显示自动记账运行状态'),
            value: _enabled,
            onChanged: _toggle,
            activeTrackColor: const Color(0xFF2E7D32),
          ),
          if (_enabled) ...[
            const Divider(height: 24),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '预览',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            _NotificationPreview(),
            const SizedBox(height: 8),
            Text(
              '开启后可在通知栏快速查看自动记账状态',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

/// A simple mock of the Android persistent notification for preview purposes.
class _NotificationPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded,
              size: 20, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jive',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '自动记账运行中',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Text(
            '现在',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
