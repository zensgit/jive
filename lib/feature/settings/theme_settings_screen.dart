import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  static const _keyPrimaryColor = 'theme_primary_color';
  static const _keyThemeMode = 'theme_mode';
  static const _keyFont = 'theme_font';

  String _selectedColor = '#2E7D32';
  String _selectedMode = 'system';
  String _selectedFont = 'default';

  static const List<Map<String, String>> _colorSwatches = [
    {'hex': '#2E7D32', 'name': '森林绿'},
    {'hex': '#1565C0', 'name': '深蓝'},
    {'hex': '#AD1457', 'name': '玫瑰红'},
    {'hex': '#E65100', 'name': '活力橙'},
    {'hex': '#6A1B9A', 'name': '深紫'},
    {'hex': '#00695C', 'name': '青绿'},
    {'hex': '#37474F', 'name': '深灰'},
    {'hex': '#BF360C', 'name': '砖红'},
    {'hex': '#00838F', 'name': '青蓝'},
    {'hex': '#558B2F', 'name': '草绿'},
    {'hex': '#F57F17', 'name': '琥珀'},
    {'hex': '#4E342E', 'name': '深棕'},
  ];

  static const List<Map<String, dynamic>> _themeModes = [
    {'value': 'system', 'label': '跟随系统', 'icon': Icons.brightness_auto},
    {'value': 'light', 'label': '浅色', 'icon': Icons.light_mode},
    {'value': 'dark', 'label': '深色', 'icon': Icons.dark_mode},
  ];

  static const List<Map<String, String>> _fonts = [
    {'value': 'default', 'label': '系统默认'},
    {'value': 'lato', 'label': 'Lato（现代）'},
    {'value': 'rubik', 'label': 'Rubik（圆润）'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedColor = prefs.getString(_keyPrimaryColor) ?? '#2E7D32';
      _selectedMode = prefs.getString(_keyThemeMode) ?? 'system';
      _selectedFont = prefs.getString(_keyFont) ?? 'default';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrimaryColor, _selectedColor);
    await prefs.setString(_keyThemeMode, _selectedMode);
    await prefs.setString(_keyFont, _selectedFont);
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  TextStyle _previewTextStyle(double size, FontWeight weight, Color color) {
    switch (_selectedFont) {
      case 'lato':
        return GoogleFonts.lato(fontSize: size, fontWeight: weight, color: color);
      case 'rubik':
        return GoogleFonts.rubik(fontSize: size, fontWeight: weight, color: color);
      default:
        return TextStyle(fontSize: size, fontWeight: weight, color: color);
    }
  }

  Widget _buildColorSection() {
    final primaryColor = _hexToColor(_selectedColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            '颜色主题',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _colorSwatches.length,
            itemBuilder: (context, index) {
              final swatch = _colorSwatches[index];
              final color = _hexToColor(swatch['hex']!);
              final isSelected = _selectedColor == swatch['hex'];
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = swatch['hex']!),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 4,
              childAspectRatio: 2.5,
            ),
            itemCount: _colorSwatches.length,
            itemBuilder: (context, index) {
              final swatch = _colorSwatches[index];
              final isSelected = _selectedColor == swatch['hex'];
              return Text(
                swatch['name']!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? primaryColor : null,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            '显示模式',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            children: _themeModes.map((mode) {
              final isSelected = _selectedMode == mode['value'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? _hexToColor(_selectedColor)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(mode['label'] as String),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedMode = mode['value'] as String),
                selectedColor: _hexToColor(_selectedColor).withValues(alpha: 0.15),
                checkmarkColor: _hexToColor(_selectedColor),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            '字体',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ..._fonts.map((font) {
          return RadioListTile<String>(
            title: Text(font['label']!),
            value: font['value']!,
            groupValue: _selectedFont,
            activeColor: _hexToColor(_selectedColor),
            onChanged: (val) {
              if (val != null) setState(() => _selectedFont = val);
            },
          );
        }),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final primaryColor = _hexToColor(_selectedColor);
    final isDark = _selectedMode == 'dark' ||
        (_selectedMode == 'system' &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '预览',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.coffee, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '星巴克咖啡',
                            style: _previewTextStyle(15, FontWeight.w600, textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '餐饮 · 今天',
                            style: _previewTextStyle(12, FontWeight.normal, textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-¥38.00',
                      style: _previewTextStyle(
                        16,
                        FontWeight.w700,
                        const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: textSecondary.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '本月支出',
                      style: _previewTextStyle(12, FontWeight.normal, textSecondary),
                    ),
                    Text(
                      '¥2,480.00',
                      style: _previewTextStyle(12, FontWeight.w600, textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.62,
                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _hexToColor(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildColorSection(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildModeSection(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildFontSection(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildPreviewCard(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: () async {
                await _savePrefs();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已保存，重启后生效'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '应用',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
