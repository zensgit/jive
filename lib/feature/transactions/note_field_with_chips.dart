import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system/theme.dart';

class NoteFieldWithChips extends StatelessWidget {
  final TextEditingController controller;
  final bool isLandscape;
  final List<String> suggestions;
  final ValueChanged<String>? onTagSelected;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const NoteFieldWithChips({
    super.key,
    required this.controller,
    required this.isLandscape,
    required this.suggestions,
    this.onTagSelected,
    this.focusNode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isLandscape ? 320 : 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            onTap: onTap,
            textAlign: TextAlign.center,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: '备注（可选）',
              prefixIcon: const Icon(Icons.edit_note, size: 18),
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
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final noteText = value.text;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: suggestions.map((tag) {
                    final selected = _noteHasTag(noteText, tag);
                    return ChoiceChip(
                      label: Text(tag, style: GoogleFonts.lato(fontSize: 11)),
                      selected: selected,
                      onSelected: (_) {
                        final next = _toggleNoteTag(noteText, tag);
                        controller.value = TextEditingValue(
                          text: next,
                          selection: TextSelection.collapsed(
                            offset: next.length,
                          ),
                        );
                        if (!selected && _noteHasTag(next, tag)) {
                          onTagSelected?.call(tag);
                        }
                      },
                      selectedColor: JiveTheme.primaryGreen.withValues(
                        alpha: 0.15,
                      ),
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide(
                        color: selected
                            ? JiveTheme.primaryGreen
                            : Colors.transparent,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

bool _noteHasTag(String note, String tag) {
  if (note.trim().isEmpty) return false;
  final pattern = RegExp('(^|\\s)${RegExp.escape(tag)}(?=\\s|\$)');
  return pattern.hasMatch(note);
}

String _toggleNoteTag(String note, String tag) {
  final trimmed = note.trim();
  if (trimmed.isEmpty) return tag;
  final pattern = RegExp('(^|\\s)${RegExp.escape(tag)}(?=\\s|\$)');
  if (pattern.hasMatch(trimmed)) {
    final withoutTag = trimmed.replaceAll(pattern, ' ');
    return withoutTag.replaceAll(RegExp(r'\\s+'), ' ').trim();
  }
  return '$trimmed $tag';
}
