import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 新手引导屏幕 - 首次安装显示
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  static const _prefKeyOnboardingComplete = 'onboarding_complete';

  /// 检查是否已完成引导
  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyOnboardingComplete) ?? false;
  }

  /// 标记引导完成
  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyOnboardingComplete, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.spa,
      title: '欢迎使用积叶',
      subtitle: '简洁高效的跨平台记账工具\n一片片叶子，积累你的财务全貌',
      color: Color(0xFF2E7D32),
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome,
      title: '智能自动记账',
      subtitle: '支持微信、支付宝支付通知自动捕获\n语音记账，说一句话即可入账',
      color: Color(0xFF1565C0),
    ),
    _OnboardingPage(
      icon: Icons.pie_chart_outline,
      title: '可视化统计',
      subtitle: '清晰的图表展示收支趋势\n分类预算管理，轻松控制消费',
      color: Color(0xFF6A1B9A),
    ),
    _OnboardingPage(
      icon: Icons.security,
      title: '隐私至上',
      subtitle: '数据完全离线存储，无需注册\n支持 PIN 码和生物识别保护',
      color: Color(0xFFE65100),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await OnboardingScreen.markComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDots(),
                    const SizedBox(height: 32),
                    _buildButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Container(
      color: page.color,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(page.icon, size: 80, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(height: 40),
              Text(
                page.title,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                page.subtitle,
                style: GoogleFonts.lato(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 100), // space for bottom controls
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildButtons() {
    final isLast = _currentPage == _pages.length - 1;
    return Row(
      children: [
        if (!isLast)
          TextButton(
            onPressed: _complete,
            child: Text(
              '跳过',
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
            ),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _pages[_currentPage].color,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Text(
            isLast ? '开始使用' : '下一步',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
