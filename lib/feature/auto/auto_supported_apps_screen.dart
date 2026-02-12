import 'package:flutter/material.dart';

import '../../core/service/auto_app_registry.dart';
import '../../core/service/auto_app_settings.dart';

class AutoSupportedAppsScreen extends StatefulWidget {
  const AutoSupportedAppsScreen({super.key});

  @override
  State<AutoSupportedAppsScreen> createState() => _AutoSupportedAppsScreenState();
}

class _AutoSupportedAppsScreenState extends State<AutoSupportedAppsScreen> {
  Map<String, bool> _enabledMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await AutoAppSettingsStore.loadEnabledMap();
    if (!mounted) return;
    setState(() {
      _enabledMap = map;
      _loading = false;
    });
  }

  Future<void> _toggle(String packageName, bool enabled) async {
    setState(() {
      _enabledMap = Map<String, bool>.from(_enabledMap)
        ..[packageName] = enabled;
    });
    await AutoAppSettingsStore.saveEnabledMap(_enabledMap);
  }

  @override
  Widget build(BuildContext context) {
    final total = AutoAppRegistry.apps.length;
    final enabledCount = AutoAppSettingsStore.enabledCount(_enabledMap);
    return Scaffold(
      appBar: AppBar(
        title: const Text('支持的应用'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '已启用 $enabledCount / $total 个应用，可在此关闭不需要的来源。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                const Divider(height: 1),
                ...AutoAppRegistry.apps.map((app) {
                  final enabled = AutoAppSettingsStore.isEnabled(_enabledMap, app.packageName);
                  return SwitchListTile(
                    title: Text(app.name),
                    subtitle: Text(app.description),
                    value: enabled,
                    onChanged: (value) => _toggle(app.packageName, value),
                  );
                }),
              ],
            ),
    );
  }
}
