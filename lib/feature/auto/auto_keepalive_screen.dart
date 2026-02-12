import 'package:flutter/material.dart';

import '../../core/service/auto_permission_service.dart';

class AutoKeepAliveScreen extends StatelessWidget {
  const AutoKeepAliveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('稳定运行设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '不同品牌系统可能会限制后台运行，请按机型设置，避免自动记账被系统清理。',
              style: TextStyle(color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(height: 16),
          Text('常用入口', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: AutoPermissionService.openAppDetails,
                child: const Text('应用详情'),
              ),
              OutlinedButton(
                onPressed: AutoPermissionService.requestIgnoreBatteryOptimizations,
                child: const Text('电池优化'),
              ),
              OutlinedButton(
                onPressed: AutoPermissionService.openOverlaySettings,
                child: const Text('悬浮窗权限'),
              ),
              OutlinedButton(
                onPressed: AutoPermissionService.openNotificationSettings,
                child: const Text('通知设置'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('厂商指引', style: sectionTitleStyle),
          const SizedBox(height: 8),
          const _GuideSection(
            title: '小米 MIUI',
            steps: [
              '后台配置改为「无限制」',
              '应用信息中开启「自启动」',
              '允许「悬浮窗」',
              '后台管理中锁定应用',
              '关闭省电模式',
            ],
          ),
          const _GuideSection(
            title: 'OPPO / OnePlus / realme',
            steps: [
              '耗电管理中允许后台运行',
              '允许应用自启动/关联启动',
              '允许「悬浮窗」',
              '后台管理中锁定应用',
              '关闭省电模式',
            ],
          ),
          const _GuideSection(
            title: 'vivo',
            steps: [
              '允许后台高耗电',
              '允许自启动',
              '允许「悬浮窗」',
              '后台管理中锁定应用',
              '关闭省电模式',
            ],
          ),
          const _GuideSection(
            title: '华为 / 荣耀',
            steps: [
              '应用启动管理中关闭自动管理',
              '允许自启动、后台活动、关联启动',
              '允许「悬浮窗」',
              '后台管理中锁定应用',
              '关闭省电模式',
            ],
          ),
          const _GuideSection(
            title: '三星 / 魅族 / 其他',
            steps: [
              '允许后台运行',
              '允许自启动',
              '允许「悬浮窗」',
              '后台管理中锁定应用',
              '关闭省电模式',
            ],
          ),
          const SizedBox(height: 20),
          Text('支付保护', style: sectionTitleStyle),
          const SizedBox(height: 8),
          const _GuideSection(
            title: '支付保护入口参考',
            steps: [
              '小米：系统设置中搜索「支付安全检测」或「支付保险箱」',
              'OPPO：系统设置中搜索「支付保护」',
              '华为：系统设置中搜索「支付保护中心」',
              'vivo：i管家 → 实用工具 → 支付保险箱',
              '其他：在系统设置或手机管家中查找类似入口',
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.title,
    required this.steps,
  });

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFF64748B))),
                    Expanded(child: Text(step)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
