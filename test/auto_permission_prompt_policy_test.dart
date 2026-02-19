import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/service/auto_permission_prompt_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('snooze lasts for 24h by default', () async {
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2026, 2, 20, 12);
    final policy = AutoPermissionPromptPolicy(prefs, now: () => now);

    expect(await policy.isPromptSnoozed(), isFalse);

    await policy.snoozePrompt();
    expect(await policy.isPromptSnoozed(), isTrue);

    now = now.add(const Duration(hours: 23, minutes: 59));
    expect(await policy.isPromptSnoozed(), isTrue);

    now = now.add(const Duration(minutes: 2));
    expect(await policy.isPromptSnoozed(), isFalse);
    expect(
      prefs.getInt(AutoPermissionPromptPolicy.prefKeySnoozeUntilMs),
      isNull,
    );
  });

  test('dismiss path enters snooze cooldown', () async {
    final prefs = await SharedPreferences.getInstance();
    final policy = AutoPermissionPromptPolicy(prefs, now: () => DateTime(2026));

    expect(
      await policy.shouldPrompt(
        autoEnabled: true,
        allRequiredPermissionsGranted: false,
        dialogVisible: false,
      ),
      isTrue,
    );

    await policy.snoozePrompt();
    expect(
      await policy.shouldPrompt(
        autoEnabled: true,
        allRequiredPermissionsGranted: false,
        dialogVisible: false,
      ),
      isFalse,
    );
  });

  test('open settings path also prevents immediate re-prompt', () async {
    final prefs = await SharedPreferences.getInstance();
    final policy = AutoPermissionPromptPolicy(prefs, now: () => DateTime(2026));

    await policy.snoozePrompt();
    expect(
      await policy.shouldPrompt(
        autoEnabled: true,
        allRequiredPermissionsGranted: false,
        dialogVisible: false,
      ),
      isFalse,
    );
  });

  test('granted permissions clear snooze and suppress prompt', () async {
    final prefs = await SharedPreferences.getInstance();
    final policy = AutoPermissionPromptPolicy(prefs, now: () => DateTime(2026));
    await policy.snoozePrompt();

    expect(
      await policy.shouldPrompt(
        autoEnabled: true,
        allRequiredPermissionsGranted: true,
        dialogVisible: false,
      ),
      isFalse,
    );
    expect(
      prefs.getInt(AutoPermissionPromptPolicy.prefKeySnoozeUntilMs),
      isNull,
    );
  });
}
