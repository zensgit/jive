import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/budget_pref_service.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  bool _isLoading = true;
  bool _saveAlertEnabled = true;
  bool _trendChartEnabled = true;
  bool _pullToExcludeEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saveAlert = await BudgetPrefService.getBudgetSaveAlertEnabled();
    final trend = await BudgetPrefService.getBudgetTrendChartEnabled();
    final pull = await BudgetPrefService.getBudgetPullToExcludeEnabled();
    if (!mounted) return;
    setState(() {
      _saveAlertEnabled = saveAlert;
      _trendChartEnabled = trend;
      _pullToExcludeEnabled = pull;
      _isLoading = false;
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          '预算设置',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _sectionCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '提醒与展示',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('保存支出时提示预算预警/超支'),
                        subtitle: const Text('新增/编辑支出时，若会触发预算预警或超支，将在保存前提示确认。'),
                        value: _saveAlertEnabled,
                        activeThumbColor: JiveTheme.primaryGreen,
                        onChanged: (value) async {
                          setState(() => _saveAlertEnabled = value);
                          await BudgetPrefService.setBudgetSaveAlertEnabled(
                            value,
                          );
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('预算详情显示支出趋势图'),
                        subtitle: const Text('在预算详情中显示近14天支出趋势（每日/累计）。'),
                        value: _trendChartEnabled,
                        activeThumbColor: JiveTheme.primaryGreen,
                        onChanged: (value) async {
                          setState(() => _trendChartEnabled = value);
                          await BudgetPrefService.setBudgetTrendChartEnabled(
                            value,
                          );
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('预算管理下拉打开预算排除'),
                        subtitle: const Text('在预算管理页下拉快速进入「预算排除」。'),
                        value: _pullToExcludeEnabled,
                        activeThumbColor: JiveTheme.primaryGreen,
                        onChanged: (value) async {
                          setState(() => _pullToExcludeEnabled = value);
                          await BudgetPrefService.setBudgetPullToExcludeEnabled(
                            value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
