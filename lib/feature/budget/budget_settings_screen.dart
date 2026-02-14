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
  bool _monthlyAutoCopyEnabled = true;
  bool _carryoverAddEnabled = false;
  bool _carryoverReduceEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saveAlert = await BudgetPrefService.getBudgetSaveAlertEnabled();
    final trend = await BudgetPrefService.getBudgetTrendChartEnabled();
    final pull = await BudgetPrefService.getBudgetPullToExcludeEnabled();
    final autoCopy = await BudgetPrefService.getBudgetMonthlyAutoCopyEnabled();
    final carryAdd = await BudgetPrefService.getBudgetCarryoverAddEnabled();
    final carryReduce = await BudgetPrefService.getBudgetCarryoverReduceEnabled();
    if (!mounted) return;
    setState(() {
      _saveAlertEnabled = saveAlert;
      _trendChartEnabled = trend;
      _pullToExcludeEnabled = pull;
      _monthlyAutoCopyEnabled = autoCopy;
      _carryoverAddEnabled = carryAdd;
      _carryoverReduceEnabled = carryReduce;
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
                const SizedBox(height: 12),
                _sectionCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '周期与结转',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('每月自动复制预算'),
                        subtitle: const Text('进入新月份时，自动复制上月的月度预算配置（名称/分类/金额/预警）。'),
                        value: _monthlyAutoCopyEnabled,
                        activeThumbColor: JiveTheme.primaryGreen,
                        onChanged: (value) async {
                          setState(() => _monthlyAutoCopyEnabled = value);
                          await BudgetPrefService.setBudgetMonthlyAutoCopyEnabled(
                            value,
                          );
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('结转正余额'),
                        subtitle: const Text('上期未用完的预算，会增加到下期预算金额。'),
                        value: _carryoverAddEnabled,
                        activeThumbColor: JiveTheme.primaryGreen,
                        onChanged: (value) async {
                          setState(() {
                            _carryoverAddEnabled = value;
                            if (!value) _carryoverReduceEnabled = false;
                          });
                          await BudgetPrefService.setBudgetCarryoverAddEnabled(
                            value,
                          );
                          if (!value) {
                            await BudgetPrefService.setBudgetCarryoverReduceEnabled(
                              false,
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('结转负余额'),
                        subtitle: const Text('上期超支的金额，会从下期预算中扣减。'),
                        value: _carryoverReduceEnabled,
                        activeThumbColor: JiveTheme.primaryGreen,
                        onChanged: (value) async {
                          setState(() {
                            _carryoverReduceEnabled = value;
                            if (value) _carryoverAddEnabled = true;
                          });
                          await BudgetPrefService.setBudgetCarryoverReduceEnabled(
                            value,
                          );
                          if (value) {
                            await BudgetPrefService.setBudgetCarryoverAddEnabled(
                              true,
                            );
                          }
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
