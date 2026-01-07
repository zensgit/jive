import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/service/auto_supported_apps.dart';

class AutoSupportedAppsScreen extends StatefulWidget {
  const AutoSupportedAppsScreen({super.key});

  @override
  State<AutoSupportedAppsScreen> createState() => _AutoSupportedAppsScreenState();
}

class _AutoSupportedAppsScreenState extends State<AutoSupportedAppsScreen> {
  bool _loading = true;
  List<AutoSupportedApp> _apps = [];
  Set<String> _enabledIds = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await AutoSupportedAppsStore.loadApps();
    final enabled = await AutoSupportedAppsStore.loadEnabledIds(apps: apps);
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _enabledIds = enabled;
      _loading = false;
    });
  }

  Future<void> _toggleApp(AutoSupportedApp app, bool enabled) async {
    final next = Set<String>.from(_enabledIds);
    if (enabled) {
      next.add(app.id);
    } else {
      next.remove(app.id);
    }
    setState(() {
      _enabledIds = next;
    });
    await AutoSupportedAppsStore.saveEnabledIds(next);
    _hasChanges = true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text('支持的应用', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildSummary(),
                  const SizedBox(height: 12),
                  ..._apps.map(_buildAppCard),
                ],
              ),
      ),
    );
  }

  Widget _buildSummary() {
    final enabledCount = _enabledIds.length;
    final total = _apps.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.apps, color: Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '已启用 $enabledCount / $total 个应用，可在此关闭不需要的来源。',
              style: GoogleFonts.lato(color: const Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(AutoSupportedApp app) {
    final enabled = _enabledIds.contains(app.id);
    final subtitle = app.description ?? app.packages.join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: enabled,
        onChanged: (value) => _toggleApp(app, value),
        secondary: CircleAvatar(
          backgroundColor: enabled ? const Color(0xFF2E7D32) : Colors.grey.shade300,
          foregroundColor: Colors.white,
          child: Text(app.name.isNotEmpty ? app.name[0] : '?'),
        ),
        title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
