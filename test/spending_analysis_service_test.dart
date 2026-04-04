import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/spending_analysis_service.dart';

void main() {
  group('SpendingAnalysis data classes', () {
    group('SpendingInsight', () {
      test('can be created with tip type', () {
        const insight = SpendingInsight(
          title: '周末消费偏高',
          description: '周末笔均支出是工作日的 2.0x，注意周末消费习惯。',
          type: InsightType.tip,
          iconName: 'calendar_today',
        );

        expect(insight.title, '周末消费偏高');
        expect(insight.description, contains('2.0x'));
        expect(insight.type, InsightType.tip);
        expect(insight.iconName, 'calendar_today');
      });

      test('can be created with warning type', () {
        const insight = SpendingInsight(
          title: '餐饮 支出异常',
          description: '本月 餐饮 支出是月均的 3.0x，请留意是否合理。',
          type: InsightType.warning,
          iconName: 'warning_amber',
        );

        expect(insight.type, InsightType.warning);
        expect(insight.title, contains('支出异常'));
      });

      test('can be created with achievement type', () {
        const insight = SpendingInsight(
          title: '支出下降',
          description: '本月支出比上月减少了 15.0%，继续保持！',
          type: InsightType.achievement,
          iconName: 'trending_down',
        );

        expect(insight.type, InsightType.achievement);
        expect(insight.description, contains('15.0%'));
      });
    });

    group('InsightType', () {
      test('has three values', () {
        expect(InsightType.values.length, 3);
        expect(InsightType.values, contains(InsightType.tip));
        expect(InsightType.values, contains(InsightType.warning));
        expect(InsightType.values, contains(InsightType.achievement));
      });
    });

    group('SpendingAnalysis', () {
      test('holds a list of insights correctly', () {
        final insights = [
          const SpendingInsight(
            title: 'Tip insight',
            description: 'A tip',
            type: InsightType.tip,
            iconName: 'lightbulb',
          ),
          const SpendingInsight(
            title: 'Warning insight',
            description: 'A warning',
            type: InsightType.warning,
            iconName: 'warning',
          ),
          const SpendingInsight(
            title: 'Achievement insight',
            description: 'An achievement',
            type: InsightType.achievement,
            iconName: 'star',
          ),
        ];

        final now = DateTime.now();
        final analysis = SpendingAnalysis(
          insights: insights,
          generatedAt: now,
        );

        expect(analysis.insights.length, 3);
        expect(analysis.insights[0].type, InsightType.tip);
        expect(analysis.insights[1].type, InsightType.warning);
        expect(analysis.insights[2].type, InsightType.achievement);
        expect(analysis.generatedAt, now);
      });

      test('can hold empty insights list', () {
        final analysis = SpendingAnalysis(
          insights: const [],
          generatedAt: DateTime(2025, 4, 1),
        );

        expect(analysis.insights, isEmpty);
        expect(analysis.generatedAt, DateTime(2025, 4, 1));
      });
    });
  });
}
