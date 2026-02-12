import 'package:flutter/services.dart';

class EmojiEntry {
  final String sequence;
  final String emoji;
  final String name;
  final String group;
  final String subgroup;
  final String searchKey;

  const EmojiEntry({
    required this.sequence,
    required this.emoji,
    required this.name,
    required this.group,
    required this.subgroup,
    required this.searchKey,
  });

  String get assetPath => 'assets/emoji/emoji_u$sequence.png';
}

class EmojiGroup {
  final String name;
  final List<EmojiEntry> entries;

  const EmojiGroup({required this.name, required this.entries});
}

class EmojiCatalog {
  final List<EmojiGroup> groups;
  final List<EmojiEntry> entries;

  const EmojiCatalog({required this.groups, required this.entries});
}

class EmojiLibrary {
  static const String _assetPath = 'assets/emoji/emoji-test.txt';
  static EmojiCatalog? _cached;
  static const Map<String, String> _groupAliases = {
    'Smileys & Emotion': '表情 情绪 笑脸 心情 开心 难过',
    'People & Body': '人物 身体 手势 手部',
    'Animals & Nature': '动物 自然 花 草 天气',
    'Food & Drink': '食物 饮料 餐饮',
    'Travel & Places': '旅行 地点 交通 出行 建筑',
    'Activities': '活动 运动 娱乐 游戏',
    'Objects': '物体 物品 工具 日用',
    'Symbols': '符号 标识 标记',
    'Flags': '旗帜 国旗 地区',
  };
  static const Map<String, List<String>> _keywordAliases = {
    'face': ['脸', '表情'],
    'smile': ['笑', '微笑'],
    'smiling': ['笑', '微笑'],
    'grin': ['咧嘴'],
    'grinning': ['咧嘴'],
    'laugh': ['笑', '哈哈'],
    'joy': ['喜悦', '哈哈'],
    'tear': ['泪', '眼泪'],
    'tears': ['泪', '眼泪'],
    'cry': ['哭', '眼泪'],
    'crying': ['哭', '哭泣'],
    'sad': ['难过'],
    'angry': ['生气', '愤怒'],
    'rage': ['愤怒', '暴走'],
    'mad': ['生气'],
    'happy': ['开心', '高兴'],
    'surprised': ['惊讶', '震惊'],
    'shock': ['震惊'],
    'fear': ['害怕', '恐惧'],
    'scream': ['尖叫'],
    'confused': ['困惑'],
    'dizzy': ['晕', '眩晕'],
    'sweat': ['冷汗'],
    'sleep': ['睡觉', '困'],
    'sleepy': ['困', '想睡'],
    'tired': ['累', '疲惫'],
    'sick': ['生病', '不舒服'],
    'ill': ['生病'],
    'vomit': ['呕吐'],
    'mask': ['口罩'],
    'cool': ['酷'],
    'sunglasses': ['墨镜'],
    'party': ['派对', '庆祝'],
    'skull': ['骷髅'],
    'ghost': ['幽灵'],
    'robot': ['机器人'],
    'clown': ['小丑'],
    'poop': ['便便', '粑粑'],
    'kiss': ['亲吻', '亲亲'],
    'heart': ['爱心', '心'],
    'love': ['爱', '爱心'],
    'hug': ['拥抱'],
    'clap': ['鼓掌'],
    'fist': ['拳头'],
    'punch': ['拳击'],
    'thumb': ['拇指', '点赞'],
    'hand': ['手'],
    'finger': ['手指'],
    'handshake': ['握手'],
    'victory': ['胜利', '耶'],
    'peace': ['和平', '耶'],
    'wave': ['挥手'],
    'ok': ['OK', '好的'],
    'pray': ['祈祷', '合十'],
    'person': ['人物'],
    'man': ['男人', '男性'],
    'woman': ['女人', '女性'],
    'boy': ['男孩'],
    'girl': ['女孩'],
    'baby': ['婴儿'],
    'family': ['家庭'],
    'couple': ['情侣'],
    'bride': ['新娘'],
    'groom': ['新郎'],
    'cat': ['猫'],
    'dog': ['狗'],
    'monkey': ['猴子'],
    'bear': ['熊'],
    'panda': ['熊猫'],
    'lion': ['狮子'],
    'tiger': ['老虎'],
    'horse': ['马'],
    'cow': ['牛'],
    'pig': ['猪'],
    'sheep': ['羊'],
    'goat': ['山羊'],
    'rabbit': ['兔子'],
    'mouse': ['老鼠'],
    'rat': ['老鼠'],
    'bird': ['鸟'],
    'chicken': ['鸡'],
    'duck': ['鸭子'],
    'fish': ['鱼'],
    'whale': ['鲸'],
    'dolphin': ['海豚'],
    'shark': ['鲨鱼'],
    'snake': ['蛇'],
    'dragon': ['龙'],
    'turtle': ['乌龟'],
    'frog': ['青蛙'],
    'bee': ['蜜蜂'],
    'butterfly': ['蝴蝶'],
    'spider': ['蜘蛛'],
    'flower': ['花'],
    'rose': ['玫瑰'],
    'sunflower': ['向日葵'],
    'tree': ['树'],
    'leaf': ['叶子'],
    'cactus': ['仙人掌'],
    'sun': ['太阳'],
    'moon': ['月亮'],
    'star': ['星星'],
    'sparkles': ['闪光'],
    'cloud': ['云'],
    'rain': ['雨'],
    'snow': ['雪'],
    'lightning': ['闪电'],
    'fire': ['火'],
    'water': ['水'],
    'food': ['食物'],
    'drink': ['饮料'],
    'coffee': ['咖啡'],
    'tea': ['茶'],
    'milk': ['牛奶'],
    'beer': ['啤酒'],
    'wine': ['红酒'],
    'cocktail': ['鸡尾酒'],
    'juice': ['果汁'],
    'soda': ['汽水'],
    'pizza': ['披萨'],
    'burger': ['汉堡'],
    'fries': ['薯条'],
    'cake': ['蛋糕'],
    'bread': ['面包'],
    'rice': ['米饭'],
    'noodles': ['面条'],
    'dumpling': ['饺子'],
    'sushi': ['寿司'],
    'steak': ['牛排'],
    'bacon': ['培根'],
    'egg': ['鸡蛋'],
    'shrimp': ['虾'],
    'crab': ['螃蟹'],
    'ice': ['冰', '雪'],
    'icecream': ['冰淇淋'],
    'chocolate': ['巧克力'],
    'cookie': ['饼干'],
    'candy': ['糖果'],
    'fruit': ['水果'],
    'apple': ['苹果'],
    'banana': ['香蕉'],
    'grapes': ['葡萄'],
    'lemon': ['柠檬'],
    'peach': ['桃子'],
    'pear': ['梨'],
    'pineapple': ['菠萝'],
    'strawberry': ['草莓'],
    'cherry': ['樱桃'],
    'watermelon': ['西瓜'],
    'car': ['汽车'],
    'bus': ['公交'],
    'train': ['火车'],
    'subway': ['地铁'],
    'airplane': ['飞机'],
    'plane': ['飞机'],
    'ship': ['船'],
    'boat': ['船'],
    'bicycle': ['自行车'],
    'bike': ['自行车'],
    'motorcycle': ['摩托车'],
    'rocket': ['火箭'],
    'taxi': ['出租车'],
    'map': ['地图'],
    'mountain': ['山'],
    'beach': ['沙滩'],
    'house': ['房子'],
    'building': ['建筑'],
    'hotel': ['酒店'],
    'hospital': ['医院'],
    'school': ['学校'],
    'phone': ['手机'],
    'computer': ['电脑'],
    'laptop': ['笔记本'],
    'camera': ['相机'],
    'book': ['书'],
    'gift': ['礼物'],
    'money': ['钱'],
    'coin': ['硬币'],
    'credit': ['信用卡'],
    'card': ['卡片'],
    'bag': ['包'],
    'shopping': ['购物'],
    'lock': ['锁'],
    'key': ['钥匙'],
    'light': ['灯'],
    'bulb': ['灯泡'],
    'music': ['音乐'],
    'note': ['音符'],
    'ball': ['球'],
    'game': ['游戏'],
    'flag': ['旗帜'],
    'symbol': ['符号'],
    'check': ['对勾'],
    'cross': ['叉'],
    'warning': ['警告'],
    'question': ['问号'],
    'exclamation': ['感叹号'],
    'plus': ['加号'],
    'minus': ['减号'],
    'arrow': ['箭头'],
  };

  static Future<EmojiCatalog> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString(_assetPath);
    final entries = <EmojiEntry>[];
    final groupOrder = <String>[];
    final groupBuckets = <String, List<EmojiEntry>>{};
    var currentGroup = '';
    var currentSubgroup = '';

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('# group:')) {
        currentGroup = trimmed.substring('# group:'.length).trim();
        if (currentGroup == 'Component') {
          continue;
        }
        if (currentGroup.isNotEmpty && !groupBuckets.containsKey(currentGroup)) {
          groupOrder.add(currentGroup);
          groupBuckets[currentGroup] = <EmojiEntry>[];
        }
        continue;
      }
      if (trimmed.startsWith('# subgroup:')) {
        currentSubgroup = trimmed.substring('# subgroup:'.length).trim();
        continue;
      }
      if (trimmed.startsWith('#')) continue;
      if (!trimmed.contains('; fully-qualified')) continue;
      if (currentGroup == 'Component') continue;

      final hashParts = trimmed.split('#');
      if (hashParts.length < 2) continue;
      final left = hashParts[0].trim();
      final codePart = left.split(';').first.trim();
      final codes = codePart.split(' ').where((part) => part.isNotEmpty).toList();
      if (codes.isEmpty) continue;
      final sequence = codes.map((part) => part.toLowerCase()).join('_');
      final emoji = String.fromCharCodes(
        codes.map((part) => int.parse(part, radix: 16)),
      );
      final comment = hashParts[1].trim();
      final spaceIndex = comment.indexOf(' ');
      if (spaceIndex == -1) continue;
      final name = comment.substring(spaceIndex + 1).trim();
      final searchKey = _buildSearchKey(name, currentGroup, currentSubgroup);

      final entry = EmojiEntry(
        sequence: sequence,
        emoji: emoji,
        name: name,
        group: currentGroup,
        subgroup: currentSubgroup,
        searchKey: searchKey,
      );
      entries.add(entry);
      groupBuckets[currentGroup]?.add(entry);
    }

    final groups = groupOrder
        .map(
          (name) => EmojiGroup(
            name: name,
            entries: List.unmodifiable(groupBuckets[name] ?? const []),
          ),
        )
        .toList();

    _cached = EmojiCatalog(groups: groups, entries: entries);
    return _cached!;
  }

  static List<EmojiEntry> filter(List<EmojiEntry> entries, String query) {
    final raw = query.trim();
    if (raw.isEmpty) return entries;
    final normalized = _normalizeSearch(raw);
    final normalizedFlat = normalized.replaceAll(' ', '');
    return entries
        .where(
          (entry) =>
              entry.emoji.contains(raw) ||
              entry.searchKey.contains(normalized) ||
              entry.searchKey.replaceAll(' ', '').contains(normalizedFlat),
        )
        .toList();
  }

  static String _buildSearchKey(String name, String group, String subgroup) {
    final tokens = <String>[
      name,
      group,
      subgroup,
      _groupAliases[group] ?? '',
      ...name.split(RegExp(r'[\\s_-]+')),
    ];
    tokens.addAll(_chineseAliasesForName(name));
    final cleaned = tokens.where((value) => value.trim().isNotEmpty);
    return cleaned.map(_normalizeSearch).join(' ');
  }

  static List<String> _chineseAliasesForName(String name) {
    final lower = name.toLowerCase();
    final tokens = lower.split(RegExp(r'[\\s_-]+')).where((value) => value.isNotEmpty);
    final aliases = <String>{};
    for (final token in tokens) {
      final mapped = _keywordAliases[token];
      if (mapped != null) {
        aliases.addAll(mapped);
      }
    }
    if (lower.contains('face')) {
      aliases.add('脸');
      aliases.add('表情');
    }
    if (lower.contains('smile') || lower.contains('grin') || lower.contains('laugh')) {
      aliases.add('笑');
      aliases.add('笑脸');
    }
    if (lower.contains('cry') || lower.contains('tear')) {
      aliases.add('哭');
      aliases.add('哭脸');
    }
    if (lower.contains('heart')) {
      aliases.add('爱');
      aliases.add('爱心');
    }
    if (lower.contains('flag')) {
      aliases.add('旗帜');
    }
    return aliases.toList();
  }

  static String _normalizeSearch(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\\s_-]+'), '');
  }
}
