import 'package:isar/isar.dart';
import '../database/tag_model.dart';

class TagService {
  final Isar _isar;

  TagService(this._isar);

  /// 从文本中提取标签
  static List<String> extractTags(String? text) {
    if (text == null || text.isEmpty) return [];
    final regex = RegExp(r'#(\S+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }

  /// 移除文本中的标签，返回纯净备注
  static String removeTagsFromText(String text) {
    return text.replaceAll(RegExp(r'#\S+\s*'), '').trim();
  }

  /// 获取或创建标签
  Future<JiveTag> getOrCreateTag(String name) async {
    var tag = await _isar.jiveTags.filter().nameEqualTo(name).findFirst();
    if (tag != null) return tag;

    tag = JiveTag()
      ..name = name
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveTags.put(tag!);
    });

    return tag;
  }

  /// 获取所有标签（按使用次数排序）
  Future<List<JiveTag>> getAllTags() async {
    return await _isar.jiveTags
        .filter()
        .isHiddenEqualTo(false)
        .sortByUsageCountDesc()
        .findAll();
  }

  /// 增加标签使用次数
  Future<void> incrementUsage(String tagName) async {
    final tag = await _isar.jiveTags.filter().nameEqualTo(tagName).findFirst();
    if (tag == null) return;

    tag.usageCount++;
    tag.lastUsedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveTags.put(tag);
    });
  }

  /// 同步交易中的标签
  Future<void> syncTagsFromNote(String? note) async {
    final tagNames = extractTags(note);
    for (final name in tagNames) {
      await getOrCreateTag(name);
      await incrementUsage(name);
    }
  }

  /// 删除标签
  Future<void> deleteTag(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveTags.delete(id);
    });
  }

  /// 更新标签颜色
  Future<void> updateTagColor(JiveTag tag, String? colorHex) async {
    tag.colorHex = colorHex;
    await _isar.writeTxn(() async {
      await _isar.jiveTags.put(tag);
    });
  }

  /// 隐藏/显示标签
  Future<void> toggleHidden(JiveTag tag) async {
    tag.isHidden = !tag.isHidden;
    await _isar.writeTxn(() async {
      await _isar.jiveTags.put(tag);
    });
  }
}
