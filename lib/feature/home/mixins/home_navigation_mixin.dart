import 'package:flutter/material.dart';

import '../../auto/auto_drafts_screen.dart';
import '../../auto/auto_rule_tester_screen.dart';
import '../../auto/auto_supported_apps_screen.dart';
import '../../auto/auto_settings_screen.dart';
import '../../import/import_center_screen.dart';
import '../../search/global_search_screen.dart';
import '../../calendar/calendar_screen.dart';
import '../../transactions/add_transaction_screen.dart';
import '../../category/category_manager_screen.dart';
import '../../currency/currency_converter_screen.dart';
import '../main_screen_controller.dart';

/// Navigation actions for the home screen.
///
/// Extracted to keep main_screen.dart focused on layout/build.
mixin HomeNavigationMixin on MainScreenController {
  Future<void> openAutoSettings() async {
    if (!dbReady) {
      showMessage("数据库尚未就绪");
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoSettingsScreen(isar: isar)),
    );
    await loadAutoSettings();
    await loadAutoDraftCount();
  }

  Future<void> openGlobalSearch() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const GlobalSearchScreen()),
    );
    if (changed == true) {
      await loadTransactions();
      notifyDataChanged();
    }
  }

  Future<void> openCalendarView() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CalendarScreen()),
    );
    if (changed == true) {
      await loadTransactions();
      notifyDataChanged();
    }
  }

  Future<void> openAutoDrafts() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoDraftsScreen()),
    );
    if (changed == true) {
      await loadTransactions();
      await loadAutoDraftCount();
      notifyDataChanged();
    }
  }

  Future<void> openImportCenter() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportCenterScreen()),
    );
    if (changed == true) {
      await loadTransactions();
      await loadAutoDraftCount();
      notifyDataChanged();
    }
  }

  Future<void> openAutoRuleTester() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoRuleTesterScreen(isar: isar)),
    );
  }

  Future<void> openAutoSupportedApps() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoSupportedAppsScreen()),
    );
    await loadAutoAppSettings();
  }

  Future<void> openCategoryManager() async {
    if (!dbReady) {
      showMessage("数据库尚未就绪");
      return;
    }
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryManagerScreen(
          isar: isar,
          currentBookId: currentBookId,
          onlyUserCategories: true,
        ),
      ),
    );
    if (changed == true) {
      await loadTransactions();
    }
  }

  Future<void> openCurrencyConverter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CurrencyConverterScreen()),
    );
  }

  Future<void> showAddTransaction(String type) async {
    TransactionType txType;
    switch (type) {
      case 'income':
        txType = TransactionType.income;
        break;
      case 'transfer':
        txType = TransactionType.transfer;
        break;
      default:
        txType = TransactionType.expense;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddTransactionScreen(initialType: txType, bookId: currentBookId),
      ),
    );
    if (result == true) {
      await loadTransactions();
      await loadAutoDraftCount();
      notifyDataChanged();
    }
  }
}
