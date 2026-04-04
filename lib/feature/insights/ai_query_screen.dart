import 'package:flutter/material.dart';

import '../../core/service/ai_prediction_service.dart';

/// Chat-like Q&A interface for AI financial queries and predictions.
class AiQueryScreen extends StatefulWidget {
  const AiQueryScreen({super.key});

  @override
  State<AiQueryScreen> createState() => _AiQueryScreenState();
}

class _AiQueryScreenState extends State<AiQueryScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _qaPairs = <_QAPair>[];

  AiPredictionService? _service;
  SpendingPrediction? _prediction;
  bool _loadingPrediction = true;
  bool _loadingAnswer = false;

  static const _suggestedQuestions = [
    '上个月花了多少？',
    '哪个分类花最多？',
    '今年存了多少？',
    '本月日均支出？',
    '去年收入多少？',
    '餐饮占比多少？',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = await AiPredictionService.create();
    if (!mounted) return;
    setState(() => _service = service);
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    if (_service == null) return;
    try {
      final prediction = await _service!.predictNextMonth();
      if (!mounted) return;
      setState(() {
        _prediction = prediction;
        _loadingPrediction = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPrediction = false);
    }
  }

  Future<void> _askQuestion(String question) async {
    if (_service == null || question.trim().isEmpty) return;

    setState(() => _loadingAnswer = true);
    try {
      final result = await _service!.queryNaturalLanguage(question);
      if (!mounted) return;
      setState(() {
        _qaPairs.add(_QAPair(
          question: question,
          answer: result.answer,
          amount: result.amount,
          chartData: result.chartData,
        ));
        _loadingAnswer = false;
      });
      _controller.clear();
      // Scroll to bottom after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAnswer = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 财务问答')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildPredictionCard(theme, colorScheme),
                const SizedBox(height: 16),
                _buildSuggestedChips(colorScheme),
                const SizedBox(height: 16),
                ..._qaPairs.map((pair) => _buildQAPairCard(pair, theme)),
                if (_loadingAnswer)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildInputBar(colorScheme),
        ],
      ),
    );
  }

  // ── Prediction card ──

  Widget _buildPredictionCard(ThemeData theme, ColorScheme colorScheme) {
    if (_loadingPrediction) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final p = _prediction;
    if (p == null || (p.predictedExpense == 0 && p.predictedIncome == 0)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('暂无足够数据生成预测，请持续记账。'),
              ),
            ],
          ),
        ),
      );
    }

    final trendIcon = switch (p.trend) {
      'increasing' => Icons.trending_up,
      'decreasing' => Icons.trending_down,
      _ => Icons.trending_flat,
    };
    final trendLabel = switch (p.trend) {
      'increasing' => '支出趋势上升',
      'decreasing' => '支出趋势下降',
      _ => '支出趋势平稳',
    };
    final trendColor = switch (p.trend) {
      'increasing' => Colors.red.shade600,
      'decreasing' => Colors.green.shade600,
      _ => Colors.blue.shade600,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '下月预测',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PredictionMetric(
                    label: '预测支出',
                    value: '¥${_formatCompact(p.predictedExpense)}',
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PredictionMetric(
                    label: '预测收入',
                    value: '¥${_formatCompact(p.predictedIncome)}',
                    color: Colors.green.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Confidence bar
            Row(
              children: [
                Text('置信度', style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.confidence,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _confidenceColor(p.confidence),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(p.confidence * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(trendIcon, size: 16, color: trendColor),
                const SizedBox(width: 4),
                Text(
                  trendLabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: trendColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green.shade400;
    if (confidence >= 0.4) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  // ── Suggested question chips ──

  Widget _buildSuggestedChips(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestedQuestions
          .map(
            (q) => ActionChip(
              label: Text(q, style: const TextStyle(fontSize: 13)),
              avatar: Icon(Icons.chat_bubble_outline,
                  size: 16, color: colorScheme.primary),
              onPressed: () => _askQuestion(q),
            ),
          )
          .toList(),
    );
  }

  // ── QA pair card ──

  Widget _buildQAPairCard(_QAPair pair, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question bubble (right-aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                pair.question,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Answer card (left-aligned)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pair.answer, style: const TextStyle(fontSize: 14)),
                  if (pair.amount != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '¥${_formatCompact(pair.amount!.abs())}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: pair.amount! >= 0
                            ? theme.colorScheme.primary
                            : Colors.red.shade400,
                      ),
                    ),
                  ],
                  if (pair.chartData != null && pair.chartData!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildMiniChart(pair.chartData!, theme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(List<ChartDataPoint> data, ThemeData theme) {
    final maxVal =
        data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    if (maxVal == 0) return const SizedBox.shrink();

    return Column(
      children: data.take(5).map((d) {
        final ratio = d.value / maxVal;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  d.label,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 14,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '¥${_formatCompact(d.value)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Input bar ──

  Widget _buildInputBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '问一个财务问题...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _askQuestion,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send_rounded, size: 20),
            onPressed: () => _askQuestion(_controller.text),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──

String _formatCompact(double value) {
  if (value >= 10000) {
    final wan = value / 10000;
    return '${wan.toStringAsFixed(wan.truncateToDouble() == wan ? 0 : 2)}万';
  }
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}

class _PredictionMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PredictionMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QAPair {
  final String question;
  final String answer;
  final double? amount;
  final List<ChartDataPoint>? chartData;

  const _QAPair({
    required this.question,
    required this.answer,
    this.amount,
    this.chartData,
  });
}
