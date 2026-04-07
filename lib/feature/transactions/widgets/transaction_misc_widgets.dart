import 'package:flutter/material.dart';

import '../../../core/database/category_model.dart';
import '../../../core/database/tag_model.dart';
import '../../../core/service/account_service.dart';
import '../../../core/service/merchant_memory_service.dart';
import '../../tag/tag_icon_catalog.dart';

/// Inline banner that appears at the top of the transaction editor when a
/// merchant memory match suggests a category. Has Apply / Dismiss actions.
///
/// Extracted from `add_transaction_screen.dart` to reduce monolith size.
class MerchantSuggestionBanner extends StatelessWidget {
  final MerchantSuggestion? suggestion;
  final List<JiveCategory> parentCategories;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const MerchantSuggestionBanner({
    super.key,
    required this.suggestion,
    required this.parentCategories,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    if (s == null) return const SizedBox.shrink();
    final categoryName = parentCategories
            .where((c) => c.key == s.categoryKey)
            .map((c) => c.name)
            .firstOrNull ??
        '未知';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.store, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '建议分类: $categoryName',
              style: TextStyle(fontSize: 12, color: Colors.green.shade800),
            ),
          ),
          GestureDetector(
            onTap: onApply,
            child: Text(
              '应用',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 14, color: Colors.green.shade400),
          ),
        ],
      ),
    );
  }
}

/// Wrap of selected tag chips with an "添加标签 / 编辑标签" action chip.
class TagSelectorWrap extends StatelessWidget {
  final List<JiveTag> tags;
  final List<String> selectedKeys;
  final bool isLandscape;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onPickTags;

  const TagSelectorWrap({
    super.key,
    required this.tags,
    required this.selectedKeys,
    required this.isLandscape,
    required this.onRemoveTag,
    required this.onPickTags,
  });

  @override
  Widget build(BuildContext context) {
    final textSize = isLandscape ? 10.0 : 12.0;
    final selectedTags =
        tags.where((tag) => selectedKeys.contains(tag.key)).toList();
    return Align(
      alignment: Alignment.center,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          for (final tag in selectedTags) _SelectedTagChip(
            tag: tag,
            textSize: textSize,
            onRemove: () => onRemoveTag(tag.key),
          ),
          ActionChip(
            label: Text(
              selectedTags.isEmpty ? '添加标签' : '编辑标签',
              style: TextStyle(fontSize: textSize),
            ),
            avatar: const Icon(
              Icons.label_outline,
              size: 14,
              color: Colors.black54,
            ),
            onPressed: onPickTags,
          ),
        ],
      ),
    );
  }
}

class _SelectedTagChip extends StatelessWidget {
  final JiveTag tag;
  final double textSize;
  final VoidCallback onRemove;

  const _SelectedTagChip({
    required this.tag,
    required this.textSize,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = AccountService.parseColorHex(tag.colorHex) ?? Colors.blueGrey;
    return InputChip(
      label: Text(
        tagDisplayName(tag),
        style: TextStyle(
          fontSize: textSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      onDeleted: onRemove,
    );
  }
}

/// Inline category-search field with prefix search icon and a clear button.
class InlineCategorySearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String currentQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const InlineCategorySearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.currentQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: '搜索分类',
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: currentQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
        filled: true,
        isDense: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Centered placeholder shown in place of the category grid when the user
/// switches to transfer mode (transfers don't have a category).
class TransferModeHint extends StatelessWidget {
  const TransferModeHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 28, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('转账无需分类', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

/// Floating overlay shown at the top of the screen while the user is holding
/// the mic button to record voice. Pure visual feedback — does not capture
/// touches.
class VoiceListeningOverlay extends StatelessWidget {
  const VoiceListeningOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              '正在聆听，松开结束',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single label/value row used in the speech-recognition preview dialog.
class SpeechPreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const SpeechPreviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
