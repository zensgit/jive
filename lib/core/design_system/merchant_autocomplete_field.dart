import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../database/merchant_memory_model.dart';
import '../service/merchant_memory_service.dart';

/// A [TextField] wrapper that shows autocomplete suggestions from
/// [MerchantMemoryService] as the user types.
///
/// Queries Isar for [JiveMerchantMemory] records, debounced at 300 ms,
/// and displays the top 5 matching merchant names in a dropdown overlay.
class MerchantAutocompleteField extends StatefulWidget {
  /// Called when a suggestion is tapped.
  final ValueChanged<String> onMerchantSelected;

  /// Optional external controller. If not provided one is created internally.
  final TextEditingController? controller;

  /// Placeholder / hint text.
  final String hintText;

  /// Isar instance used for querying merchant memory.
  final Isar isar;

  const MerchantAutocompleteField({
    super.key,
    required this.onMerchantSelected,
    required this.isar,
    this.controller,
    this.hintText = '商户名称',
  });

  @override
  State<MerchantAutocompleteField> createState() =>
      _MerchantAutocompleteFieldState();
}

class _MerchantAutocompleteFieldState extends State<MerchantAutocompleteField> {
  late final TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<String> _suggestions = [];
  late final MerchantMemoryService _service;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _service = MerchantMemoryService(widget.isar);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(_controller.text);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _updateSuggestions([]);
      return;
    }

    final normalized = MerchantMemoryService.normalize(query);
    final all = await _service.getAllMemories();
    final matches = <String>[];

    for (final m in all) {
      if (m.normalizedName.contains(normalized) ||
          normalized.contains(m.normalizedName) ||
          m.displayName.toLowerCase().contains(query.toLowerCase())) {
        matches.add(m.displayName);
        if (matches.length >= 5) break;
      }
    }

    _updateSuggestions(matches);
  }

  void _updateSuggestions(List<String> suggestions) {
    if (!mounted) return;
    setState(() => _suggestions = suggestions);
    if (suggestions.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectMerchant(String name) {
    _controller.text = name;
    _controller.selection =
        TextSelection.collapsed(offset: name.length);
    _removeOverlay();
    widget.onMerchantSelected(name);
  }

  Widget _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 200;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, renderBox?.size.height ?? 48),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final name = _suggestions[index];
                return InkWell(
                  onTap: () => _selectMerchant(name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.store, size: 20),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
