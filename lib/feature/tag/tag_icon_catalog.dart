import 'package:flutter/material.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/category_service.dart';

const Map<String, IconData> tagIconMap = {
  'work': Icons.work,
  'home': Icons.home,
  'restaurant': Icons.restaurant,
  'shopping_cart': Icons.shopping_cart,
  'directions_car': Icons.directions_car,
  'flight': Icons.flight,
  'medical_services': Icons.medical_services,
  'school': Icons.school,
  'sports': Icons.sports_soccer,
  'movie': Icons.movie,
  'flag': Icons.flag,
  'person': Icons.person,
  'lifestyle': Icons.spa,
  'travel': Icons.explore,
  'education': Icons.menu_book,
  'health': Icons.favorite,
  'finance': Icons.savings,
};

IconData tagIconFor(String? key) {
  if (key == null || key.isEmpty) return Icons.label;
  return tagIconMap[key] ?? CategoryService.getIcon(key);
}

String tagDisplayName(JiveTag tag) {
  return tag.name;
}

bool hasTagIcon(JiveTag tag) {
  final iconText = tag.iconText?.trim() ?? '';
  final iconName = tag.iconName?.trim() ?? '';
  return iconText.isNotEmpty || iconName.isNotEmpty;
}

Widget iconWidgetForName(
  String? iconName, {
  double size = 16,
  Color? color,
}) {
  final trimmed = iconName?.trim() ?? '';
  if (trimmed.isEmpty) {
    return Icon(Icons.label, size: size, color: color);
  }
  final mapped = tagIconMap[trimmed];
  if (mapped != null) {
    return Icon(mapped, size: size, color: color);
  }
  return CategoryService.buildIcon(trimmed, size: size, color: color);
}

String? _iconTextFromName(String? iconName) {
  final trimmed = iconName?.trim() ?? '';
  if (trimmed.startsWith('text:')) {
    final value = trimmed.substring('text:'.length).trim();
    if (value.isNotEmpty) return value;
  }
  return null;
}

Widget tagIconWidget(
  JiveTag tag, {
  double size = 16,
  Color? color,
}) {
  final iconText = tag.iconText?.trim();
  if (iconText != null && iconText.isNotEmpty) {
    return Text(iconText, style: TextStyle(fontSize: size, color: color));
  }
  return iconWidgetForName(tag.iconName, size: size, color: color);
}


Widget groupIconWidget(
  JiveTagGroup? group, {
  double size = 16,
  Color? color,
}) {
  if (group == null) {
    return Icon(Icons.label_outline, size: size, color: color);
  }
  final iconText = group.iconText?.trim();
  if (iconText != null && iconText.isNotEmpty) {
    return Text(iconText, style: TextStyle(fontSize: size, color: color));
  }
  return iconWidgetForName(group.iconName, size: size, color: color);
}

String groupDisplayName(JiveTagGroup group) {
  final iconText = group.iconText?.trim();
  if (iconText != null && iconText.isNotEmpty) {
    return '$iconText ${group.name}';
  }
  final textIcon = _iconTextFromName(group.iconName);
  if (textIcon != null) {
    return '$textIcon ${group.name}';
  }
  return group.name;
}
