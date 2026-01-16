import 'package:lpinyin/lpinyin.dart';

class CategoryIconEntry {
  final String name;
  final List<String> keywords;

  const CategoryIconEntry(this.name, this.keywords);
}

String normalizeSearch(String input) {
  return input.toLowerCase().replaceAll(RegExp(r'[\\s_-]+'), '');
}

String buildIconSearchKey(CategoryIconEntry entry) {
  final buffer = StringBuffer();
  buffer.write(normalizeSearch(entry.name));
  for (final keyword in entry.keywords) {
    final normalized = normalizeSearch(keyword);
    buffer.write(' $normalized');
    buffer.write(' ${normalizeSearch(PinyinHelper.getPinyinE(keyword))}');
    buffer.write(' ${normalizeSearch(PinyinHelper.getShortPinyin(keyword))}');
  }
  return buffer.toString();
}

const List<CategoryIconEntry> categoryIconEntries = [

  CategoryIconEntry('restaurant', ['餐饮', '美食', 'food', 'restaurant']),
  CategoryIconEntry('bakery_dining', ['早餐', '早饭', 'breakfast']),
  CategoryIconEntry('lunch_dining', ['午餐', '午饭', 'lunch']),
  CategoryIconEntry('dinner_dining', ['晚餐', '晚饭', 'dinner']),
  CategoryIconEntry('tapas', ['夜宵', '宵夜', 'snack']),
  CategoryIconEntry('delivery_dining', ['外卖', 'delivery']),
  CategoryIconEntry('local_cafe', ['饮料', '奶茶', '咖啡', '茶', 'coffee', 'tea']),
  CategoryIconEntry('icecream', ['零食', '甜品', 'icecream']),
  CategoryIconEntry('shopping_basket', ['买菜', '生鲜', 'grocery']),
  CategoryIconEntry('nutrition', ['水果', '果蔬', 'fruit', 'veg']),
  CategoryIconEntry('celebration', ['聚会', 'party']),
  CategoryIconEntry('liquor', ['酒', '酒水', 'liquor', 'wine']),
  CategoryIconEntry('shopping_bag', ['购物', 'shopping']),
  CategoryIconEntry('checkroom', ['服饰', '衣服', 'clothes']),
  CategoryIconEntry('cases', ['鞋包', '包', 'shoes', 'bag']),
  CategoryIconEntry('phone_iphone', ['数码', '手机', 'digital']),
  CategoryIconEntry('kitchen', ['家电', 'appliance']),
  CategoryIconEntry('chair', ['家居', '家具', 'home']),
  CategoryIconEntry('local_shipping', ['快递', '物流', 'delivery']),
  CategoryIconEntry('directions_car', ['交通', '出行', 'car']),
  CategoryIconEntry('local_taxi', ['打车', '出租', 'taxi']),
  CategoryIconEntry('subway', ['地铁', 'subway']),
  CategoryIconEntry('directions_bus', ['公交', 'bus']),
  CategoryIconEntry('local_gas_station', ['加油', 'gas']),
  CategoryIconEntry('local_parking', ['停车', 'parking']),
  CategoryIconEntry('train', ['火车', '高铁', 'train']),
  CategoryIconEntry('flight', ['飞机', '机票', 'flight']),
  CategoryIconEntry('house', ['居住', '住房', 'house']),
  CategoryIconEntry('key', ['房租', '租房', 'rent']),
  CategoryIconEntry('wifi', ['宽带', '网络', 'wifi']),
  CategoryIconEntry('phone_android', ['话费', '手机费', 'phone']),
  CategoryIconEntry('lightbulb', ['水电', '电费', 'water']),
  CategoryIconEntry('business', ['物业', 'property']),
  CategoryIconEntry('sports_esports', ['娱乐', '游戏', 'game']),
  CategoryIconEntry('movie', ['电影', 'movie']),
  CategoryIconEntry('videogame_asset', ['游戏', 'game']),
  CategoryIconEntry('mic', ['KTV', '唱歌', 'karaoke']),
  CategoryIconEntry('sports_basketball', ['运动', '健身', 'sport']),
  CategoryIconEntry('landscape', ['旅行', '旅游', 'travel']),
  CategoryIconEntry('card_membership', ['会员', 'member']),
  CategoryIconEntry('local_hospital', ['医疗', '医院', 'hospital']),
  CategoryIconEntry('medication', ['药品', '药', 'medicine']),
  CategoryIconEntry('local_pharmacy', ['挂号', 'pharmacy']),
  CategoryIconEntry('monitor_heart', ['检查', '体检']),
  CategoryIconEntry('people', ['人情', '社交', 'people']),
  CategoryIconEntry('redeem', ['红包', 'gift', 'bonus']),
  CategoryIconEntry('local_dining', ['请客', '聚餐']),
  CategoryIconEntry('pets', ['宠物', 'pet']),
  CategoryIconEntry('pest_control_rodent', ['猫粮', '狗粮', 'petfood']),
  CategoryIconEntry('trending_up', ['理财', '收益', 'invest']),
  CategoryIconEntry('attach_money', ['工资', '收入', 'salary']),
  CategoryIconEntry('military_tech', ['奖金', 'bonus']),
  CategoryIconEntry('work', ['兼职', '工作', 'job']),
  CategoryIconEntry('sell', ['二手', '卖出', 'sell']),
  CategoryIconEntry('category', ['默认', '分类', 'category']),
];
