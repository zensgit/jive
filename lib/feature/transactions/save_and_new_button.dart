import 'package:flutter/material.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/continuous_recording_service.dart';

/// A compact bottom-bar button group for the transaction form.
///
/// Shows the normal "保存" button alongside a "保存并新建" button.
/// Includes a "连续记账模式" toggle switch that persists its state.
class SaveAndNewButton extends StatefulWidget {
  /// Called when the user taps "保存" (normal save).
  final VoidCallback? onSave;

  /// Called when the user taps "保存并新建".
  /// The parent should save the transaction, reset the form (keeping account +
  /// date), and show a success toast.
  final VoidCallback? onSaveAndNew;

  /// Whether the save buttons should be enabled.
  final bool enabled;

  const SaveAndNewButton({
    super.key,
    this.onSave,
    this.onSaveAndNew,
    this.enabled = true,
  });

  @override
  State<SaveAndNewButton> createState() => _SaveAndNewButtonState();
}

class _SaveAndNewButtonState extends State<SaveAndNewButton> {
  bool _continuousMode = false;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final mode = await ContinuousRecordingService.isContinuousMode();
    if (mounted) setState(() => _continuousMode = mode);
  }

  Future<void> _toggleMode(bool value) async {
    await ContinuousRecordingService.setContinuousMode(value);
    if (mounted) setState(() => _continuousMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Continuous-mode toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '连续记账模式',
                  style: TextStyle(
                    fontSize: 12,
                    color: JiveTheme.secondaryTextColor(context),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 24,
                  child: Switch.adaptive(
                    value: _continuousMode,
                    onChanged: _toggleMode,
                    activeTrackColor: JiveTheme.primaryGreen.withAlpha(100),
                    activeThumbColor: JiveTheme.primaryGreen,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Button row
            Row(
              children: [
                // Save & New
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.enabled ? widget.onSaveAndNew : null,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('保存并新建'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JiveTheme.primaryGreen,
                      side: const BorderSide(color: JiveTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Normal save
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: widget.enabled ? widget.onSave : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('保存'),
                    style: FilledButton.styleFrom(
                      backgroundColor: JiveTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
