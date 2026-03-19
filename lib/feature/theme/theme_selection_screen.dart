import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_presets.dart';
import 'theme_provider.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('深色模式'),
              subtitle: Text(
                themeProvider.isDarkMode ? '已启用深色主题' : '当前使用浅色主题',
              ),
              secondary: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
              ),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                if (value != themeProvider.isDarkMode) {
                  themeProvider.toggleDarkMode();
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '主题预设',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '轻触卡片即可立即应用配色',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: themeProvider.presets.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.92,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final preset = themeProvider.presets[index];
              final isSelected =
                  preset.name == themeProvider.selectedPresetName;

              return _ThemePresetCard(
                preset: preset,
                isSelected: isSelected,
                highlightColor: colorScheme.primary,
                onTap: () {
                  themeProvider.setTheme(preset.name);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemePresetCard extends StatelessWidget {
  const _ThemePresetCard({
    required this.preset,
    required this.isSelected,
    required this.highlightColor,
    required this.onTap,
  });

  final ThemePreset preset;
  final bool isSelected;
  final Color highlightColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = isSelected
        ? highlightColor.withValues(alpha: theme.brightness == Brightness.dark
              ? 0.22
              : 0.10)
        : theme.cardColor;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? highlightColor
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            preset.primaryColor,
                            preset.seedColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: preset.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      preset.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _ColorDot(color: preset.primaryColor),
                        const SizedBox(width: 8),
                        _ColorDot(color: preset.accentColor),
                        const SizedBox(width: 8),
                        _ColorDot(color: preset.seedColor),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: highlightColor.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
