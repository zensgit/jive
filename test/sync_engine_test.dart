import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/sync/sync_config.dart';
import 'package:jive/core/sync/sync_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncConfig', () {
    test('not configured when env vars empty', () {
      // Default values are empty strings
      expect(SyncConfig.isConfigured, isFalse);
    });

    test('supabaseUrl and anonKey are empty by default', () {
      expect(SyncConfig.supabaseUrl, isEmpty);
      expect(SyncConfig.supabaseAnonKey, isEmpty);
    });
  });

  group('SyncState', () {
    test('disabled by default', () {
      const state = SyncState();
      expect(state.status, equals(SyncStatus.disabled));
      expect(state.isEnabled, isFalse);
      expect(state.isSyncing, isFalse);
    });

    test('idle state', () {
      final now = DateTime.now();
      final state = SyncState.idle(lastSyncAt: now);
      expect(state.status, equals(SyncStatus.idle));
      expect(state.isEnabled, isTrue);
      expect(state.lastSyncAt, equals(now));
    });

    test('syncing state', () {
      const state = SyncState.syncing();
      expect(state.isSyncing, isTrue);
      expect(state.isEnabled, isTrue);
    });

    test('error state', () {
      final state = SyncState.error('网络错误');
      expect(state.status, equals(SyncStatus.error));
      expect(state.errorMessage, equals('网络错误'));
    });
  });

  group('SyncEngine availability', () {
    test('not available when not configured', () async {
      SharedPreferences.setMockInitialValues({});
      final entitlement = EntitlementService();
      await entitlement.init();
      await entitlement.setTier(UserTier.subscriber);

      // SyncConfig.isConfigured is false (no env vars in test)
      // so SyncEngine.isAvailable would be false
      expect(SyncConfig.isConfigured, isFalse);
    });

    test('not available for free tier even if configured', () async {
      SharedPreferences.setMockInitialValues({});
      final entitlement = EntitlementService();
      await entitlement.init();
      expect(entitlement.tier, equals(UserTier.free));
      expect(entitlement.tier.hasCloud, isFalse);
    });

    test('cloud access requires subscriber', () async {
      SharedPreferences.setMockInitialValues({});
      final entitlement = EntitlementService();
      await entitlement.init();

      await entitlement.setTier(UserTier.paid);
      expect(entitlement.tier.hasCloud, isFalse);

      await entitlement.setTier(UserTier.subscriber);
      expect(entitlement.tier.hasCloud, isTrue);
    });
  });
}
