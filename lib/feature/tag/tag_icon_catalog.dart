import 'package:flutter/material.dart';
import '../../core/database/tag_model.dart';

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
  return tagIconMap[key] ?? Icons.label;
}

String tagDisplayName(JiveTag tag) {
  return tag.name;
}

Widget tagIconWidget(
  JiveTag tag, {
  double size = 16,
  Color? color,
}) {
  final iconText = tag.iconText?.trim();
  if (iconText != null && iconText.isNotEmpty) {
    return Text(iconText, style: TextStyle(fontSize: size));
  }
  return Icon(tagIconFor(tag.iconName), size: size, color: color);
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
    return Text(iconText, style: TextStyle(fontSize: size));
  }
  return Icon(tagIconFor(group.iconName), size: size, color: color);
}

String groupDisplayName(JiveTagGroup group) {
  final iconText = group.iconText?.trim();
  if (iconText != null && iconText.isNotEmpty) {
    return '$iconText ${group.name}';
  }
  return group.name;
}
