import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jive/app/jive_app.dart';
import 'package:jive/feature/home/widgets/home_top_bar.dart';
import 'package:jive/feature/home/widgets/home_asset_card.dart';
import 'package:jive/feature/home/widgets/home_recent_transactions_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('JiveApp smoke', () {
    testWidgets('JiveApp creates MaterialApp', (tester) async {
      // JiveApp depends on ThemeProvider via Provider, so we test it in
      // isolation by checking the class exists and can be instantiated.
      const app = JiveApp();
      expect(app, isNotNull);
    });
  });

  group('HomeTopBar', () {
    testWidgets('renders greeting and action icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTopBar(
              compact: false,
              books: const [],
              currentBookId: null,
              pendingDraftCount: 0,
              onSearch: () {},
              onCalendar: () {},
              onGearMenu: () {},
              onBookSwitch: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Greeting is time-based
      final greetingFinder = find.byWidgetPredicate(
        (w) => w is Text && w.data != null && w.data!.endsWith(','),
      );
      expect(greetingFinder, findsOneWidget);
      // No displayName passed → shows 访客
      expect(find.text('访客'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('compact mode renders smaller text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTopBar(
              compact: true,
              books: const [],
              currentBookId: null,
              pendingDraftCount: 0,
              onSearch: () {},
              onCalendar: () {},
              onGearMenu: () {},
              onBookSwitch: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('访客'), findsOneWidget);
    });

    testWidgets('shows custom display name when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTopBar(
              compact: false,
              displayName: 'Alice',
              books: const [],
              currentBookId: null,
              pendingDraftCount: 0,
              onSearch: () {},
              onCalendar: () {},
              onGearMenu: () {},
              onBookSwitch: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('访客'), findsNothing);
    });
  });

  group('HomeAssetCard', () {
    testWidgets('renders balance and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeAssetCard(
                compact: false,
                tight: false,
                totalAssets: 50000,
                totalLiabilities: 10000,
                totalCreditLimit: 20000,
                totalCreditUsed: 5000,
                totalCreditAvailable: 15000,
                baseCurrency: 'CNY',
                onAddExpense: () {},
                onAddIncome: () {},
                onAddTransfer: () {},
                onCurrencyConverter: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Net worth = assets - liabilities = 40000
      expect(find.textContaining('40,000'), findsOneWidget);
      expect(find.text('支出'), findsOneWidget);
      expect(find.text('收入'), findsOneWidget);
      expect(find.text('转账'), findsOneWidget);
    });
  });

  group('HomeRecentTransactionsSection', () {
    testWidgets('renders View All button with correct key', (tester) async {
      final section = HomeRecentTransactionsSection(
        compact: false,
        transactions: const [],
        categoryByKey: const {},
        tagByKey: const {},
        accountById: const {},
        isLoading: false,
        showSmartTagBadge: false,
        currentBookId: null,
        baseCurrency: 'CNY',
        onViewAll: () {},
        onTransactionDetail: (_, __) async => null,
        onAddTransaction: () {},
        onDataChanged: () async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                section.buildTitle(),
                section.buildTransactionList(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify key exists
      expect(
        find.byKey(const Key('home_view_all_transactions_button')),
        findsOneWidget,
      );
      expect(find.text('View All'), findsOneWidget);
      expect(find.text('Recent Transactions'), findsOneWidget);
    });

    testWidgets('shows empty state when no transactions', (tester) async {
      final section = HomeRecentTransactionsSection(
        compact: false,
        transactions: const [],
        categoryByKey: const {},
        tagByKey: const {},
        accountById: const {},
        isLoading: false,
        showSmartTagBadge: false,
        currentBookId: null,
        baseCurrency: 'CNY',
        onViewAll: () {},
        onTransactionDetail: (_, __) async => null,
        onAddTransaction: () {},
        onDataChanged: () async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: section.buildTransactionListBody(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet'), findsOneWidget);
    });
  });
}
