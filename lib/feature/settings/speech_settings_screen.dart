import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/theme.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../core/entitlement/feature_gate.dart';
import '../../core/entitlement/feature_id.dart';
import '../../core/service/speech_service.dart';
import '../../core/service/speech_settings.dart';
import '../../core/service/voice_quota_service.dart';

class SpeechSettingsScreen extends StatefulWidget {
  const SpeechSettingsScreen({super.key});

  @override
  State<SpeechSettingsScreen> createState() => _SpeechSettingsScreenState();
}

class _SpeechSettingsScreenState extends State<SpeechSettingsScreen> {
  static const _localeOptions = <_SpeechLocaleOption>[
    _SpeechLocaleOption(
      value: 'zh-CN',
      label: '普通话',
      subtitle: '简体中文识别',
    ),
    _SpeechLocaleOption(
      value: 'zh-TW',
      label: '繁體中文',
      subtitle: '繁体中文识别',
    ),
    _SpeechLocaleOption(
      value: 'yue',
      label: '粤语',
      subtitle: '广东话识别',
    ),
  ];

  SpeechSettings? _settings;
  VoiceQuota? _quota;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final settings = await SpeechSettingsStore.load();
    final quota = await VoiceQuotaStore.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _quota = quota;
      _loading = false;
    });
  }

  Future<void> _updateSettings(SpeechSettings next) async {
    setState(() {
      _settings = next;
      _saving = true;
    });
    await SpeechSettingsStore.save(next);
    final refreshedQuota = await VoiceQuotaStore.load();
    if (!mounted) return;
    setState(() {
      _quota = refreshedQuota;
      _saving = false;
    });
  }

  Widget _sectionCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = Provider.of<EntitlementService?>(context);
    final hasVoiceAccess =
        entitlement?.canAccess(FeatureId.voiceBookkeeping) ?? true;
    final settings = _settings;
    final quota = _quota;
    final onlineUsage = quota?.usageRatio ?? 0;

    if (!hasVoiceAccess) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("语音设置", style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.grey.shade100,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: JiveTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "语音记账需要订阅版",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "当前账户暂未解锁语音记账。升级后可使用语音录入、线上增强识别与相关设置。",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          showUpgradePrompt(context, FeatureId.voiceBookkeeping),
                      style: FilledButton.styleFrom(
                        backgroundColor: JiveTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("查看订阅方案"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("语音设置", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: _loading || settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.mic_none_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "语音记账",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              settings.enabled
                                  ? "已启用。默认优先尝试系统识别，开启线上增强后可在本地不可用时回退。"
                                  : "当前已关闭，交易页长按语音按钮时会直接提示不可用。",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _saving
                                  ? Row(
                                      key: const ValueKey('saving'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "正在保存",
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.92),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      settings.enabled ? "当前状态：开启" : "当前状态：关闭",
                                      key: const ValueKey('saved'),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.92),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("基本偏好", style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: JiveTheme.primaryGreen,
                        title: const Text("启用语音记账"),
                        subtitle: const Text("控制交易页语音输入入口是否可用"),
                        value: settings.enabled,
                        onChanged: (value) => _updateSettings(
                          settings.copyWith(enabled: value),
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: JiveTheme.primaryGreen,
                        title: const Text("开启线上增强"),
                        subtitle: Text(
                          settings.enabled
                              ? "允许在本地识别不可用时尝试线上语音方案"
                              : "需先启用语音记账后再开启",
                        ),
                        value: settings.onlineEnhance && settings.enabled,
                        onChanged: settings.enabled
                            ? (value) => _updateSettings(
                                  settings.copyWith(onlineEnhance: value),
                                )
                            : null,
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const Text(
                        "识别语言",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _localeOptions.map((option) {
                          final selected = option.value == settings.locale;
                          return ChoiceChip(
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(option.label),
                                Text(
                                  option.subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected
                                        ? JiveTheme.primaryGreen
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            selected: selected,
                            selectedColor: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                            checkmarkColor: JiveTheme.primaryGreen,
                            side: BorderSide(
                              color: selected
                                  ? JiveTheme.primaryGreen
                                  : Colors.grey.shade300,
                            ),
                            onSelected: (_) => _updateSettings(
                              settings.copyWith(locale: option.value),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("引擎现状", style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _EngineStatusTile(
                        icon: Icons.android_outlined,
                        title: "系统识别",
                        badge: "默认",
                        badgeColor: const Color(0xFFE8F5E9),
                        badgeTextColor: const Color(0xFF1B5E20),
                        description: "依赖设备系统语音识别能力，无需额外密钥。当前交易页会优先尝试这一方案。",
                      ),
                      const SizedBox(height: 10),
                      _EngineStatusTile(
                        icon: Icons.cloud_outlined,
                        title: "讯飞增强",
                        badge: IflytekSpeechService.hasCredentials ? "已配置" : "待配置",
                        badgeColor: IflytekSpeechService.hasCredentials
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFFFFF3E0),
                        badgeTextColor: IflytekSpeechService.hasCredentials
                            ? const Color(0xFF0D47A1)
                            : const Color(0xFFE65100),
                        description: IflytekSpeechService.hasCredentials
                            ? "已检测到构建时注入的讯飞凭据，可作为线上增强方案使用。"
                            : "当前构建未注入讯飞密钥。需要在构建时提供 ${IflytekSpeechService.missingCredentialKeys.join(', ')}。",
                      ),
                      const SizedBox(height: 10),
                      const _EngineStatusTile(
                        icon: Icons.memory_outlined,
                        title: "百度预留",
                        badge: "未启用",
                        badgeColor: Color(0xFFF3E5F5),
                        badgeTextColor: Color(0xFF6A1B9A),
                        description:
                            "Android 原生层已有预留代码，但当前构建未注入凭据，设置页也暂不提供运行时配置入口。",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("线上配额", style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      if (quota == null)
                        const Text("尚未读取到配额信息")
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "今日线上识别 ${quota.onlineCount}/${quota.dailyLimit}",
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              "剩余 ${quota.remaining}",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: onlineUsage.clamp(0, 1),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              onlineUsage >= 1
                                  ? Colors.red.shade400
                                  : onlineUsage >= 0.7
                                      ? Colors.orange.shade400
                                      : JiveTheme.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "线上增强只统计在线方案调用次数；本地系统识别不会占用线上配额。",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SpeechLocaleOption {
  final String value;
  final String label;
  final String subtitle;

  const _SpeechLocaleOption({
    required this.value,
    required this.label,
    required this.subtitle,
  });
}

class _EngineStatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final String description;

  const _EngineStatusTile({
    required this.icon,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: JiveTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.45,
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
