import 'package:flutter/material.dart';

import '../../core/data/scene_templates.dart';

/// 场景模板选择器 — 以网格形式展示 6 个预置场景。
///
/// [onApply] 在用户点击「应用场景」时回调所选模板。
/// 可嵌入 GuidedSetupScreen 或独立使用。
class SceneTemplatePicker extends StatefulWidget {
  final ValueChanged<SceneTemplate> onApply;

  const SceneTemplatePicker({super.key, required this.onApply});

  @override
  State<SceneTemplatePicker> createState() => _SceneTemplatePickerState();
}

class _SceneTemplatePickerState extends State<SceneTemplatePicker> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final templates = kSceneTemplates;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '选择一个场景模板',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            '我们会根据场景自动配置分类、标签和预算',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              final selected = _selectedId == t.id;
              return _SceneCard(
                template: t,
                selected: selected,
                onTap: () => setState(() => _selectedId = t.id),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _selectedId == null
                ? null
                : () {
                    final template = templates.firstWhere(
                      (t) => t.id == _selectedId,
                    );
                    widget.onApply(template);
                  },
            child: const Text('应用场景'),
          ),
        ),
      ],
    );
  }
}

class _SceneCard extends StatelessWidget {
  final SceneTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _SceneCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        selected ? const Color(0xFF2E7D32) : theme.colorScheme.outlineVariant;
    final borderWidth = selected ? 2.0 : 1.0;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                template.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                template.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (template.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  template.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
