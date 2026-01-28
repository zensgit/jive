import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionNoteCard extends StatelessWidget {
  final String note;

  const TransactionNoteCard({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    // 移除标签后的纯备注
    final cleanNote = _removeTagsFromNote(note);
    if (cleanNote.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_outlined, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                '备注',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cleanNote,
            style: GoogleFonts.lato(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  String _removeTagsFromNote(String note) {
    // 移除 #tag 格式的标签
    return note.replaceAll(RegExp(r'#\S+\s*'), '').trim();
  }
}
