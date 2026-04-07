import 'package:flutter/material.dart';

import '../../core/model/scene.dart';
import '../../core/service/scene_service.dart';

/// Compact chip widget that shows the current scene and allows switching.
///
/// Designed to be placed in the home screen top bar. Tap opens a dropdown of
/// all available scenes; selecting one calls [SceneService.switchScene].
class SceneSwitcher extends StatelessWidget {
  final SceneService sceneService;

  /// Callback fired after a scene switch completes.
  final VoidCallback? onSwitch;

  /// Callback fired when the user taps "New Scene".
  final VoidCallback? onCreateScene;

  const SceneSwitcher({
    super.key,
    required this.sceneService,
    this.onSwitch,
    this.onCreateScene,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sceneService,
      builder: (context, _) {
        return FutureBuilder<Scene?>(
          future: sceneService.getCurrentScene(),
          builder: (context, currentSnap) {
            final current = currentSnap.data;
            if (current == null) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () => _showSceneMenu(context, current),
              child: Chip(
                avatar: current.emoji != null
                    ? Text(current.emoji!, style: const TextStyle(fontSize: 16))
                    : null,
                label: Text(
                  current.name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSceneMenu(BuildContext context, Scene current) async {
    final scenes = await sceneService.getScenes();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '切换场景',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              ...scenes.map((scene) {
                final isActive = scene.bookId == current.bookId;
                return ListTile(
                  leading: Text(
                    scene.emoji ?? '📖',
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(scene.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (scene.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '默认',
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                        ),
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check_circle,
                            color: Theme.of(ctx).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!isActive) {
                      await sceneService.switchScene(scene.bookId);
                      onSwitch?.call();
                    }
                  },
                );
              }),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('新建场景'),
                onTap: () {
                  Navigator.pop(ctx);
                  onCreateScene?.call();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
