import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'monthly_overview_screen.dart';
import 'category_analysis_screen.dart';
import 'trend_chart_screen.dart';
import 'stats_screen.dart';

/// New stats home page with tab navigation.
/// Replaces the old single-page StatsScreen as the entry point.
class StatsHomeScreen extends StatefulWidget {
  final ValueListenable<int>? reloadSignal;

  const StatsHomeScreen({super.key, this.reloadSignal});

  @override
  State<StatsHomeScreen> createState() => _StatsHomeScreenState();
}

class _StatsHomeScreenState extends State<StatsHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('统计', style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: Colors.black87,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: '总览'),
            Tab(text: '分类'),
            Tab(text: '趋势'),
            Tab(text: '详情'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const MonthlyOverviewScreen(),
          const CategoryAnalysisScreen(),
          const TrendChartScreen(),
          StatsScreen(reloadSignal: widget.reloadSignal),
        ],
      ),
    );
  }
}
