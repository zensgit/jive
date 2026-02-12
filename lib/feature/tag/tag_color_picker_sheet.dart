import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/service/tag_color_palette_store.dart';

Color _colorFromHex(String hex, {Color fallback = const Color(0xFF4D7CFE)}) {
  final normalized = _normalizeHex(hex);
  if (normalized == null) return fallback;
  final cleaned = normalized.substring(1);
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  if (cleaned.length == 6) {
    return Color(0xFF000000 | value);
  }
  return Color(value);
}

String _hexFromColor(Color color) {
  final value = color.toARGB32();
  if (_alpha8(color) == 255) {
    final rgb = value & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
  return '#${value.toRadixString(16).padLeft(8, '0')}';
}

int _alpha8(Color color) {
  final value = (color.a * 255.0).round();
  if (value < 0) return 0;
  if (value > 255) return 255;
  return value;
}

String _rgbHexFromColor(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return value.toRadixString(16).padLeft(6, '0').toUpperCase();
}

String? _normalizeHex(String hex) {
  final cleaned = hex.trim().replaceAll('#', '');
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return '#${cleaned.toLowerCase()}';
}

class TagColorPickerPlatform {
  static const MethodChannel _channel = MethodChannel('com.jive.app/color_picker');

  static Future<Color?> pickSystemColor(Color initialColor) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    try {
      final result = await _channel.invokeMethod<String>('pickColor', {
        'hex': '#${_rgbHexFromColor(initialColor)}',
      });
      if (result == null) return null;
      return _colorFromHex(result, fallback: initialColor);
    } on PlatformException {
      return null;
    }
  }
}

class TagColorPickerSheet extends StatefulWidget {
  final String initialColorHex;
  final List<String> swatchHexes;
  final ScrollController? scrollController;

  const TagColorPickerSheet({
    super.key,
    required this.initialColorHex,
    required this.swatchHexes,
    this.scrollController,
  });

  static Future<String?> show(
    BuildContext context, {
    required String initialColorHex,
    required List<String> swatchHexes,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, controller) {
            return TagColorPickerSheet(
              initialColorHex: initialColorHex,
              swatchHexes: swatchHexes,
              scrollController: controller,
            );
          },
        );
      },
    );
  }

  @override
  State<TagColorPickerSheet> createState() => _TagColorPickerSheetState();
}

class _TagColorPickerSheetState extends State<TagColorPickerSheet>
    with SingleTickerProviderStateMixin {
  static const _sheetColor = Colors.white;
  static const _panelText = Color(0xFF1F2329);
  static const _panelTextMuted = Color(0xFF6B7280);
  static const _segmentBackground = Color(0xFFF3F4F6);
  static const _segmentSelected = Colors.white;
  static const _segmentTextMuted = Color(0xFF67707B);
  static const _segmentDivider = Color(0xFFE3E6EC);
  static const _segmentBorder = Color(0xFFE3E6EC);
  static const _inputFill = Color(0xFFF3F4F6);
  static const _inputBorder = Color(0xFFE2E4EA);
  static const _inputBorderFocus = Color(0xFFB9BEC7);
  static const _contentBorder = Color(0xFFE5E7EB);
  static const _paletteItemSize = 26.0;
  static const _paletteItemSpacing = 8.0;
  static const _tabContentHeight = 260.0;

  late Color _currentColor;
  late TabController _tabController;
  late List<Color> _gridColors;
  List<String> _paletteHexes = [];
  bool _paletteEditMode = false;
  bool _isPickingSystemColor = false;
  final ScrollController _paletteScrollController = ScrollController();

  final TextEditingController _redController = TextEditingController();
  final TextEditingController _greenController = TextEditingController();
  final TextEditingController _blueController = TextEditingController();
  final TextEditingController _alphaController = TextEditingController();
  final TextEditingController _hexController = TextEditingController();

  final FocusNode _redFocus = FocusNode();
  final FocusNode _greenFocus = FocusNode();
  final FocusNode _blueFocus = FocusNode();
  final FocusNode _alphaFocus = FocusNode();
  final FocusNode _hexFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentColor = _colorFromHex(widget.initialColorHex);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _gridColors = _buildGridColors();
    _paletteHexes = _normalizePalette(widget.swatchHexes);
    _syncControllers();
    _loadPalette();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paletteScrollController.dispose();
    _redController.dispose();
    _greenController.dispose();
    _blueController.dispose();
    _alphaController.dispose();
    _hexController.dispose();
    _redFocus.dispose();
    _greenFocus.dispose();
    _blueFocus.dispose();
    _alphaFocus.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showEyedropper = defaultTargetPlatform == TargetPlatform.iOS;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabHeight = math.min(_tabContentHeight, constraints.maxHeight * 0.46);
        final paletteRows = constraints.maxHeight > 700 ? 3 : (constraints.maxHeight > 560 ? 2 : 1);
        return Material(
          color: _sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              children: [
                _buildSheetHandle(),
                _buildHeader(showEyedropper),
                const SizedBox(height: 3),
                _buildPickerPanel(context, tabHeight),
                const SizedBox(height: 8),
                _buildPaletteSection(paletteRows: paletteRows),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE1E4EA),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(bool showEyedropper) {
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            '颜色',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _panelText),
          ),
          Positioned(
            left: 0,
            child: showEyedropper
                ? _buildHeaderAction(
                    icon: Icons.colorize_outlined,
                    onTap: _isPickingSystemColor ? null : _pickSystemColor,
                  )
                : const SizedBox(width: 28, height: 28),
          ),
          Positioned(
            right: 0,
            child: _buildHeaderAction(
              icon: Icons.close,
              onTap: () => Navigator.pop(context, _hexFromColor(_currentColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({required IconData icon, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          border: Border.all(color: _inputBorder),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: _panelText),
      ),
    );
  }

  Widget _buildPickerPanel(BuildContext context, double tabHeight) {
    return Column(
      children: [
        _buildSegmentTabs(),
        const SizedBox(height: 4),
        _buildOpacityRow(),
        const SizedBox(height: 6),
        SizedBox(
          height: tabHeight,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGridPicker(),
              _buildSpectrumPicker(),
              _buildSliderPicker(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentTabs() {
    const labels = ['网格', '光谱', '滑块'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _segmentBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _segmentBorder),
      ),
      child: Row(
        children: [
          _buildSegment(labels[0], 0, showDivider: true),
          _buildSegment(labels[1], 1, showDivider: true),
          _buildSegment(labels[2], 2, showDivider: false),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, int index, {required bool showDivider}) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: selected ? _segmentSelected : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? _panelText : _segmentTextMuted,
                  ),
                ),
              ),
            ),
            if (showDivider)
              Positioned(
                right: 0,
                top: 6,
                bottom: 6,
                child: Container(width: 1, color: _segmentDivider),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridPicker() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _contentBorder),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GridView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 12,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: _gridColors.length,
          itemBuilder: (context, index) {
            final color = _gridColors[index];
            final isSelected = _currentColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => _setColor(color, preserveAlpha: true),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  border: isSelected ? Border.all(color: _panelText, width: 2) : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpectrumPicker() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _contentBorder),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _handleSpectrumGesture(details.localPosition, constraints.biggest),
              onPanDown: (details) =>
                  _handleSpectrumGesture(details.localPosition, constraints.biggest),
              onPanUpdate: (details) =>
                  _handleSpectrumGesture(details.localPosition, constraints.biggest),
              child: CustomPaint(
                painter: const _SpectrumPainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSpectrumGesture(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = (position.dx / size.width).clamp(0.0, 1.0);
    final dy = (position.dy / size.height).clamp(0.0, 1.0);
    final hue = dx * 360.0;
    final value = 1.0 - dy;
    final color = HSVColor.fromAHSV(_alpha8(_currentColor) / 255.0, hue, 1.0, value).toColor();
    _setColor(color, preserveAlpha: false);
  }

  Widget _buildSliderPicker() {
    final labelStyle = const TextStyle(color: _panelTextMuted, fontSize: 12);
    return Column(
      children: [
        _buildChannelRow(
          label: '红',
          value: _channelValue(_currentColor.r),
          controller: _redController,
          focusNode: _redFocus,
          activeColor: const Color(0xFFE53935),
          max: 255,
          onChanged: (value) => _setRgb(red: value),
        ),
        const SizedBox(height: 6),
        _buildChannelRow(
          label: '绿',
          value: _channelValue(_currentColor.g),
          controller: _greenController,
          focusNode: _greenFocus,
          activeColor: const Color(0xFF43A047),
          max: 255,
          onChanged: (value) => _setRgb(green: value),
        ),
        const SizedBox(height: 6),
        _buildChannelRow(
          label: '蓝',
          value: _channelValue(_currentColor.b),
          controller: _blueController,
          focusNode: _blueFocus,
          activeColor: const Color(0xFF1E88E5),
          max: 255,
          onChanged: (value) => _setRgb(blue: value),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('sRGB HEX 颜色 #', style: labelStyle),
            const SizedBox(width: 6),
            SizedBox(
              width: 110,
              child: _buildHexField(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelRow({
    required String label,
    required int value,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color activeColor,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label, style: const TextStyle(color: _panelTextMuted, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 16,
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withValues(alpha: 0.2),
              thumbColor: Colors.white,
              overlayColor: activeColor.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: max.toDouble(),
              onChanged: (val) => onChanged(val.round()),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: _buildNumberField(
            controller: controller,
            focusNode: focusNode,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildOpacityRow() {
    final alphaPercent = _alphaPercent();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('不透明度', style: TextStyle(color: _panelTextMuted, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomPaint(
                        painter: _CheckerboardPainter(
                          light: Colors.white,
                          dark: const Color(0xFFE8EBF1),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            _currentColor.withAlpha(0),
                            _currentColor.withAlpha(255),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 16,
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.white,
                      overlayColor: Colors.black.withValues(alpha: 0.06),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    ),
                    child: Slider(
                      value: alphaPercent.toDouble(),
                      min: 0,
                      max: 100,
                      onChanged: (value) => _setAlphaPercent(value.round()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 54,
              child: _buildNumberField(
                controller: _alphaController,
                focusNode: _alphaFocus,
                max: 100,
                suffix: '%',
                onChanged: _setAlphaPercent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHexField() {
    return TextField(
      controller: _hexController,
      focusNode: _hexFocus,
      maxLength: 6,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
        LengthLimitingTextInputFormatter(6),
        _UpperCaseTextFormatter(),
      ],
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: _inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _inputBorderFocus),
        ),
      ),
      style: const TextStyle(color: _panelText, fontSize: 12, fontWeight: FontWeight.w600),
      onChanged: _onHexChanged,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required int max,
    required ValueChanged<int> onChanged,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _inputBorderFocus),
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _panelTextMuted, fontSize: 10),
      ),
      style: const TextStyle(color: _panelText, fontSize: 12, fontWeight: FontWeight.w600),
      onChanged: (value) => _handleNumberChanged(value, max, controller, onChanged),
    );
  }

  Widget _buildPaletteSection({required int paletteRows}) {
    final captionStyle = const TextStyle(color: _panelTextMuted, fontSize: 11);
    final rows = _paletteEditMode ? 1 : paletteRows;
    final itemSize = rows == 2 ? 24.0 : _paletteItemSize;
    final itemSpacing = _paletteItemSpacing;
    final paletteHeight = rows * itemSize + (rows - 1) * itemSpacing;
    const previewSize = 38.0;
    const addSize = 34.0;
    const sideGap = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth = constraints.maxWidth - previewSize - addSize - sideGap * 2;
        final paletteWidth = math.max(120.0, rawWidth);
        final itemsPerRow =
            math.max(1, ((paletteWidth + itemSpacing) / (itemSize + itemSpacing)).floor());
        final itemsPerPage = itemsPerRow * rows;
        final pageCount = math.max(1, (_paletteHexes.length / itemsPerPage).ceil());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '色卡',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _panelText),
                ),
                const SizedBox(width: 8),
                Text('长按排序/删除', style: captionStyle),
                const Spacer(),
                if (_paletteEditMode)
                  TextButton(
                    onPressed: () => setState(() => _paletteEditMode = false),
                    style: TextButton.styleFrom(foregroundColor: _panelText),
                    child: const Text('完成'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSelectedPreview(previewSize),
                const SizedBox(width: sideGap),
                SizedBox(
                  width: paletteWidth,
                  height: paletteHeight,
                  child: _paletteEditMode
                      ? _buildPaletteReorderList(itemSize, itemSpacing)
                      : _buildPaletteGrid(rows, itemSize, itemSpacing),
                ),
                const SizedBox(width: sideGap),
                _buildPaletteAddButton(size: addSize),
              ],
            ),
            const SizedBox(height: 6),
            if (!_paletteEditMode && pageCount > 1)
              _buildPaletteIndicator(
                pageCount: pageCount,
                itemsPerRow: itemsPerRow,
                itemSize: itemSize,
                itemSpacing: itemSpacing,
              ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedPreview(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _inputBorder, width: 1),
      ),
      child: ClipOval(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CheckerboardPainter(
                  light: Colors.white,
                  dark: const Color(0xFFE8EBF1),
                  square: 6,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(color: _currentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteGrid(int rows, double itemSize, double itemSpacing) {
    return GridView.builder(
      controller: _paletteScrollController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: rows,
        mainAxisSpacing: itemSpacing,
        crossAxisSpacing: itemSpacing,
        childAspectRatio: 1,
      ),
      itemCount: _paletteHexes.length,
      itemBuilder: (context, index) => _buildPaletteSwatch(index, size: itemSize),
    );
  }

  Widget _buildPaletteReorderList(double itemSize, double itemSpacing) {
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: false,
      onReorder: _reorderPalette,
      itemCount: _paletteHexes.length,
      itemBuilder: (context, index) {
        return ReorderableDelayedDragStartListener(
          key: ValueKey('palette_${_paletteHexes[index]}_$index'),
          index: index,
          child: Padding(
            padding: EdgeInsets.only(right: itemSpacing),
            child: _buildPaletteSwatch(index, size: itemSize),
          ),
        );
      },
    );
  }

  Widget _buildPaletteIndicator({
    required int pageCount,
    required int itemsPerRow,
    required double itemSize,
    required double itemSpacing,
  }) {
    final pageWidth = itemsPerRow * (itemSize + itemSpacing);
    return AnimatedBuilder(
      animation: _paletteScrollController,
      builder: (context, child) {
        final offset = _paletteScrollController.hasClients ? _paletteScrollController.offset : 0.0;
        final rawIndex = pageWidth > 0 ? (offset / pageWidth).round() : 0;
        final activeIndex = rawIndex.clamp(0, pageCount - 1);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (index) {
            final isActive = index == activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 10 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? _panelText : _inputBorder,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPaletteSwatch(int index, {required double size}) {
    final hex = _paletteHexes[index];
    final color = _colorFromHex(hex);
    final isSelected = _currentColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => _selectPaletteColor(hex),
      onLongPress: _paletteEditMode
          ? null
          : () {
              setState(() => _paletteEditMode = true);
            },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _panelText : Colors.black.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          if (_paletteEditMode)
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () => _removePaletteColor(index),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(Icons.remove, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaletteAddButton({required double size}) {
    return GestureDetector(
      onTap: _addPaletteColor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _inputFill,
          shape: BoxShape.circle,
          border: Border.all(color: _inputBorder, width: 1),
        ),
        child: const Icon(Icons.add, size: 18, color: _panelTextMuted),
      ),
    );
  }

  void _selectPaletteColor(String hex) {
    final normalized = _normalizeHex(hex);
    if (normalized == null) return;
    final cleaned = normalized.substring(1);
    final hasAlpha = cleaned.length == 8;
    final color = _colorFromHex(normalized, fallback: _currentColor);
    _setColor(color, preserveAlpha: !hasAlpha);
  }

  void _addPaletteColor() {
    final normalized = _normalizeHex(_hexFromColor(_currentColor)) ?? _hexFromColor(_currentColor);
    setState(() {
      _paletteHexes.removeWhere((item) => item.toLowerCase() == normalized.toLowerCase());
      _paletteHexes.add(normalized);
    });
    _savePalette();
    _scrollPaletteToEnd();
  }

  void _scrollPaletteToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_paletteScrollController.hasClients) return;
      final maxScroll = _paletteScrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;
      _paletteScrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _removePaletteColor(int index) {
    if (index < 0 || index >= _paletteHexes.length) return;
    setState(() {
      _paletteHexes.removeAt(index);
      if (_paletteHexes.isEmpty) {
        _paletteEditMode = false;
      }
    });
    _savePalette();
  }

  void _reorderPalette(int oldIndex, int newIndex) {
    final paletteLength = _paletteHexes.length;
    if (oldIndex >= paletteLength) return;
    var target = newIndex;
    if (target > paletteLength) {
      target = paletteLength;
    }
    setState(() {
      if (target > oldIndex) {
        target -= 1;
      }
      final item = _paletteHexes.removeAt(oldIndex);
      _paletteHexes.insert(target.clamp(0, _paletteHexes.length), item);
    });
    _savePalette();
  }

  void _handleNumberChanged(
    String value,
    int max,
    TextEditingController controller,
    ValueChanged<int> onChanged,
  ) {
    if (value.isEmpty) return;
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    final clamped = parsed.clamp(0, max).toInt();
    if (clamped.toString() != controller.text) {
      _setControllerText(controller, null, clamped.toString());
    }
    onChanged(clamped);
  }

  void _syncControllers() {
    _setControllerText(_redController, _redFocus, _channelValue(_currentColor.r).toString());
    _setControllerText(_greenController, _greenFocus, _channelValue(_currentColor.g).toString());
    _setControllerText(_blueController, _blueFocus, _channelValue(_currentColor.b).toString());
    _setControllerText(_alphaController, _alphaFocus, _alphaPercent().toString());
    _setControllerText(_hexController, _hexFocus, _rgbHexFromColor(_currentColor));
  }

  void _setControllerText(TextEditingController controller, FocusNode? focusNode, String text) {
    if (focusNode != null && focusNode.hasFocus) return;
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onHexChanged(String value) {
    final cleaned = value.trim().replaceAll('#', '');
    if (cleaned.length != 6) return;
    final candidate = _normalizeHex(cleaned);
    if (candidate == null) return;
    final color = _colorFromHex(candidate, fallback: _currentColor);
    _setColor(color, preserveAlpha: true);
  }

  void _setColor(Color color, {bool preserveAlpha = true}) {
    final updated = preserveAlpha ? color.withAlpha(_alpha8(_currentColor)) : color;
    setState(() => _currentColor = updated);
    _syncControllers();
  }

  void _setRgb({int? red, int? green, int? blue}) {
    final updated = Color.fromARGB(
      _alpha8(_currentColor),
      red ?? _channelValue(_currentColor.r),
      green ?? _channelValue(_currentColor.g),
      blue ?? _channelValue(_currentColor.b),
    );
    _setColor(updated, preserveAlpha: false);
  }

  void _setAlphaPercent(int percent) {
    final clamped = percent.clamp(0, 100).toInt();
    final alpha = (clamped / 100.0 * 255).round();
    final updated = Color.fromARGB(
      alpha,
      _channelValue(_currentColor.r),
      _channelValue(_currentColor.g),
      _channelValue(_currentColor.b),
    );
    _setColor(updated, preserveAlpha: false);
  }

  int _alphaPercent() {
    return ((_alpha8(_currentColor) / 255.0) * 100).round();
  }

  int _channelValue(double channel) {
    final value = (channel * 255.0).round();
    if (value < 0) return 0;
    if (value > 255) return 255;
    return value;
  }

  Future<void> _pickSystemColor() async {
    setState(() => _isPickingSystemColor = true);
    final result = await TagColorPickerPlatform.pickSystemColor(_currentColor);
    if (!mounted) return;
    setState(() => _isPickingSystemColor = false);
    if (result != null) {
      _setColor(result, preserveAlpha: false);
    }
  }

  Future<void> _loadPalette() async {
    final stored = await TagColorPaletteStore.load(fallback: widget.swatchHexes);
    if (!mounted) return;
    setState(() {
      _paletteHexes = _normalizePalette(stored);
    });
  }

  Future<void> _savePalette() async {
    await TagColorPaletteStore.save(_paletteHexes);
  }

  List<String> _normalizePalette(List<String> items) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final item in items) {
      final value = _normalizeHex(item);
      if (value == null) continue;
      if (seen.add(value)) {
        normalized.add(value);
      }
    }
    return normalized;
  }

  List<Color> _buildGridColors() {
    const rows = 8;
    const cols = 12;
    final colors = <Color>[];
    for (var col = 0; col < cols; col++) {
      final t = col / (cols - 1);
      colors.add(Color.lerp(Colors.white, Colors.black, t)!);
    }
    for (var row = 1; row < rows; row++) {
      final value = 1.0 - (row - 1) / (rows - 2) * 0.7;
      for (var col = 0; col < cols; col++) {
        final hue = (col / (cols - 1)) * 360;
        colors.add(HSVColor.fromAHSV(1, hue, 1, value).toColor());
      }
    }
    return colors;
  }
}

class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({
    required this.light,
    required this.dark,
    this.square = 6,
  });

  final Color light;
  final Color dark;
  final double square;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = light;
    canvas.drawRect(Offset.zero & size, paint);
    paint.color = dark;
    for (var y = 0.0; y < size.height; y += square) {
      for (var x = 0.0; x < size.width; x += square) {
        final isDark = ((x / square).floor() + (y / square).floor()) % 2 == 0;
        if (!isDark) continue;
        canvas.drawRect(Rect.fromLTWH(x, y, square, square), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.light != light || oldDelegate.dark != dark || oldDelegate.square != square;
  }
}

class _SpectrumPainter extends CustomPainter {
  const _SpectrumPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueShader = const LinearGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = hueShader);
    final valueShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = valueShader);
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) => false;
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
