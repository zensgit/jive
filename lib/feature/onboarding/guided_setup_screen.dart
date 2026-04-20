import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/category_model.dart';
import '../../core/database/savings_goal_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/onboarding_progress_service.dart';

/// Multi-step guided setup shown after the initial onboarding carousel.
class GuidedSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const GuidedSetupScreen({super.key, required this.onComplete});

  @override
  State<GuidedSetupScreen> createState() => _GuidedSetupScreenState();
}

class _GuidedSetupScreenState extends State<GuidedSetupScreen> {
  static const _totalSteps = 4;
  static const _kGreen = Color(0xFF2E7D32);

  int _currentStep = 0;
  late final PageController _pageController;

  // Step 1 state
  final _amountController = TextEditingController();
  String? _selectedCategoryKey;
  String? _selectedCategoryName;

  // Step 2 state
  List<JiveCategory> _parentCategories = [];
  final Set<int> _hiddenCategoryIds = {};

  // Step 3 state
  final _budgetController = TextEditingController();

  // Step 4 state
  final _goalNameController = TextEditingController();
  final _goalAmountController = TextEditingController();

  late Isar _isar;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _init();
  }

  Future<void> _init() async {
    _isar = await DatabaseService.getInstance();
    await CategoryService(_isar).initDefaultCategories();
    await _loadCategories();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    final cats = await _isar
        .collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(false)
        .isHiddenEqualTo(false)
        .sortByOrder()
        .findAll();
    if (mounted) {
      setState(() {
        _parentCategories = cats;
        if (_selectedCategoryKey == null && cats.isNotEmpty) {
          _selectedCategoryKey = cats.first.key;
          _selectedCategoryName = cats.first.name;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();
    _budgetController.dispose();
    _goalNameController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  // ---- navigation ----

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  Future<void> _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      await _finish();
    }
  }

  Future<void> _skipStep() async {
    await _nextStep();
  }

  Future<void> _finish() async {
    await OnboardingProgressService.markGuidedSetupComplete();
    widget.onComplete();
  }

  // ---- step handlers ----

  Future<void> _completeStep1() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      await OnboardingProgressService.markStepComplete(0);
      await _nextStep();
      return;
    }

    final fallbackCategory = _parentCategories.isNotEmpty
        ? _parentCategories.first
        : null;
    final categoryKey = _selectedCategoryKey ?? fallbackCategory?.key;
    final categoryName = _selectedCategoryName ?? fallbackCategory?.name;
    if (categoryKey == null) {
      await OnboardingProgressService.markStepComplete(0);
      await _nextStep();
      return;
    }

    final tx = JiveTransaction()
      ..amount = amount
      ..source = 'manual'
      ..timestamp = DateTime.now()
      ..categoryKey = categoryKey
      ..category = categoryName
      ..type = 'expense'
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.put(tx);
    });

    await OnboardingProgressService.markStepComplete(0);
    await _nextStep();
  }

  Future<void> _completeStep2() async {
    final catService = CategoryService(_isar);
    for (final cat in _parentCategories) {
      final shouldHide = _hiddenCategoryIds.contains(cat.id);
      if (shouldHide != cat.isHidden) {
        await catService.setCategoryHidden(cat.id, shouldHide);
      }
    }
    await OnboardingProgressService.markStepComplete(1);
    await _nextStep();
  }

  Future<void> _completeStep3() async {
    final amountText = _budgetController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final now = DateTime.now();
    const currency = 'CNY';
    final budgetService = BudgetService(_isar, CurrencyService(_isar));
    await budgetService.createBudget(
      name: '月预算',
      amount: amount,
      currency: currency,
      startDate: DateTime(now.year, now.month),
      endDate: DateTime(
        now.year,
        now.month + 1,
      ).subtract(const Duration(days: 1)),
      period: 'monthly',
    );

    await OnboardingProgressService.markStepComplete(2);
    await _nextStep();
  }

  Future<void> _completeStep4() async {
    final name = _goalNameController.text.trim();
    final amountText = _goalAmountController.text.trim();
    final amount = double.tryParse(amountText);
    if (name.isEmpty || amount == null || amount <= 0) return;

    final now = DateTime.now();
    final goal = JiveSavingsGoal()
      ..name = name
      ..targetAmount = amount
      ..currentAmount = 0
      ..status = 'active'
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveSavingsGoals.put(goal);
    });

    await OnboardingProgressService.markStepComplete(3);
    await _finish();
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProgressDots(),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (i) {
        final isActive = i == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 14 : 10,
          height: isActive ? 14 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _kGreen : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  // ---- Step 1: 记一笔 ----

  Widget _buildStep1() {
    return _StepShell(
      title: '记一笔',
      subtitle: '快速添加您的第一笔消费',
      onSkip: _skipStep,
      onNext: _completeStep1,
      nextLabel: '下一步',
      child: Column(
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: '¥ ',
              prefixStyle: GoogleFonts.lato(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              hintText: '0.00',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '选择分类',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(selectable: true),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid({required bool selectable}) {
    if (_parentCategories.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('暂无分类'));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _parentCategories.map((cat) {
        final isSelected = selectable && _selectedCategoryKey == cat.key;
        return GestureDetector(
          onTap: selectable
              ? () => setState(() {
                  _selectedCategoryKey = cat.key;
                  _selectedCategoryName = cat.name;
                })
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _kGreen : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? Border.all(color: _kGreen, width: 2) : null,
            ),
            child: Text(
              cat.name,
              style: GoogleFonts.lato(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---- Step 2: 设分类 ----

  Widget _buildStep2() {
    return _StepShell(
      title: '设分类',
      subtitle: '关闭不需要的分类，让记账更清爽',
      onSkip: _skipStep,
      onNext: _completeStep2,
      nextLabel: '下一步',
      child: _buildToggleCategoryList(),
    );
  }

  Widget _buildToggleCategoryList() {
    if (_parentCategories.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('暂无分类'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _parentCategories.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final cat = _parentCategories[index];
        final hidden = _hiddenCategoryIds.contains(cat.id);
        return SwitchListTile(
          title: Text(cat.name, style: GoogleFonts.lato()),
          value: !hidden,
          activeTrackColor: _kGreen.withValues(alpha: 0.5),
          onChanged: (visible) {
            setState(() {
              if (visible) {
                _hiddenCategoryIds.remove(cat.id);
              } else {
                _hiddenCategoryIds.add(cat.id);
              }
            });
          },
        );
      },
    );
  }

  // ---- Step 3: 定预算 ----

  Widget _buildStep3() {
    return _StepShell(
      title: '定预算',
      subtitle: '设定每月预算，轻松管理消费',
      onSkip: _skipStep,
      onNext: _completeStep3,
      nextLabel: '下一步',
      child: Column(
        children: [
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: '¥ ',
              prefixStyle: GoogleFonts.lato(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              hintText: '3000',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '建议从实际月支出出发，后续可随时调整',
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ---- Step 4: 设目标 ----

  Widget _buildStep4() {
    return _StepShell(
      title: '设目标',
      subtitle: '创建第一个存钱目标，积少成多',
      onSkip: () => _finish(),
      onNext: _completeStep4,
      nextLabel: '完成',
      child: Column(
        children: [
          TextField(
            controller: _goalNameController,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 20),
            decoration: InputDecoration(
              hintText: '例如：旅行基金',
              hintStyle: GoogleFonts.lato(color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _goalAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: '¥ ',
              prefixStyle: GoogleFonts.lato(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              hintText: '10000',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '可选步骤，跳过也没关系',
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Shared layout for each guided-setup step.
class _StepShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final String nextLabel;
  final Widget child;

  const _StepShell({
    required this.title,
    required this.subtitle,
    required this.onSkip,
    required this.onNext,
    required this.nextLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(child: SingleChildScrollView(child: child)),
          _buildBottomButtons(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: onSkip,
          child: Text(
            '跳过',
            style: GoogleFonts.lato(color: Colors.grey, fontSize: 16),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            nextLabel,
            style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
