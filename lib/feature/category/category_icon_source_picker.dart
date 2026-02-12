import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'category_icon_picker_screen.dart';

enum _CategoryIconSource { system, emoji, gallery, text }

Future<String?> pickCategoryIcon(BuildContext context, {required String initialIcon}) async {
  final action = await showModalBottomSheet<_CategoryIconSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: const Text("系统图标"),
            onTap: () => Navigator.pop(sheetContext, _CategoryIconSource.system),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_emotions_outlined),
            title: const Text("表情符号"),
            onTap: () => Navigator.pop(sheetContext, _CategoryIconSource.emoji),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text("从相册选择"),
            onTap: () => Navigator.pop(sheetContext, _CategoryIconSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text("文字图标"),
            onTap: () => Navigator.pop(sheetContext, _CategoryIconSource.text),
          ),
        ],
      ),
    ),
  );
  if (action == null) return null;
  if (!context.mounted) return null;
  switch (action) {
    case _CategoryIconSource.system:
      return await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryIconPickerScreen(
            initialIcon: initialIcon,
            initialMode: CategoryIconPickerMode.category,
          ),
          fullscreenDialog: true,
        ),
      );
    case _CategoryIconSource.emoji:
      return await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryIconPickerScreen(
            initialIcon: initialIcon,
            initialMode: CategoryIconPickerMode.emoji,
          ),
          fullscreenDialog: true,
        ),
      );
    case _CategoryIconSource.gallery:
      return await _pickImageIcon(context);
    case _CategoryIconSource.text:
      return await _pickTextIcon(context, initialIcon: initialIcon);
  }
}

Future<String?> _pickImageIcon(BuildContext context) async {
  final picker = ImagePicker();
  try {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 92,
    );
    if (picked == null) return null;
    final savedPath = await _persistCustomIcon(picked);
    if (savedPath == null) return null;
    return "file:$savedPath";
  } catch (_) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("无法读取图片，请稍后再试")),
    );
    return null;
  }
}

Future<String?> _pickTextIcon(BuildContext context, {required String initialIcon}) async {
  final initial = _extractTextIcon(initialIcon) ?? "";
  final controller = TextEditingController(text: initial);
  String current = initial;
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setStateDialog) {
        return AlertDialog(
          title: const Text("文字图标"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                onChanged: (value) => setStateDialog(() => current = value.trim()),
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: "输入文字 (1-4字)",
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  current.isEmpty ? "?" : current,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, current.trim()),
              child: const Text("确定"),
            ),
          ],
        );
      },
    ),
  );
  if (result == null || result.trim().isEmpty) return null;
  return "text:${result.trim()}";
}

String? _extractTextIcon(String iconName) {
  if (!iconName.startsWith("text:")) return null;
  return iconName.substring("text:".length);
}

Future<String?> _persistCustomIcon(XFile file) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory("${dir.path}/category_icons");
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  final sourcePath = file.path;
  final dotIndex = sourcePath.lastIndexOf(".");
  final ext = dotIndex == -1 ? ".png" : sourcePath.substring(dotIndex);
  final filename = "category_icon_${DateTime.now().microsecondsSinceEpoch}$ext";
  final targetPath = "${folder.path}/$filename";
  await File(sourcePath).copy(targetPath);
  return targetPath;
}
