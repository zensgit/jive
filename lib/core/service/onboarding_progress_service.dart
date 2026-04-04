import 'package:shared_preferences/shared_preferences.dart';

/// Tracks guided-setup progress after the initial onboarding carousel.
class OnboardingProgressService {
  static const _keyGuidedSetupComplete = 'guided_setup_complete';
  static const _keyCompletedSteps = 'guided_setup_completed_steps';

  const OnboardingProgressService._();

  /// Whether the user has finished (or skipped past) the guided setup.
  static Future<bool> isGuidedSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGuidedSetupComplete) ?? false;
  }

  /// Marks the entire guided setup as complete.
  static Future<void> markGuidedSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGuidedSetupComplete, true);
  }

  /// Returns indices of steps the user actually completed (vs skipped).
  static Future<Set<int>> getCompletedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyCompletedSteps) ?? [];
    return list.map(int.parse).toSet();
  }

  /// Records that [step] was completed (not skipped).
  static Future<void> markStepComplete(int step) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyCompletedSteps) ?? [];
    final steps = list.map(int.parse).toSet()..add(step);
    await prefs.setStringList(
      _keyCompletedSteps,
      steps.map((s) => s.toString()).toList(),
    );
  }
}
