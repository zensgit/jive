// 预置场景模板数据
//
// 每个场景包含：名称、emoji、分类子集 key、标签、建议预算。

class SceneTemplate {
  final String id;
  final String name;
  final String emoji;
  final String? description;
  final List<String> categoryKeys;
  final List<String> tagKeys;
  final double suggestedBudget;

  const SceneTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    this.description,
    required this.categoryKeys,
    required this.tagKeys,
    required this.suggestedBudget,
  });
}

const List<SceneTemplate> kSceneTemplates = [
  SceneTemplate(
    id: 'daily_life',
    name: '日常生活',
    emoji: '\u{1F3E0}',
    description: '日常开销记录',
    categoryKeys: ['餐饮', '交通', '购物', '住房', '日常'],
    tagKeys: [],
    suggestedBudget: 5000,
  ),
  SceneTemplate(
    id: 'travel',
    name: '旅行出差',
    emoji: '\u{2708}\u{FE0F}',
    description: '旅行与出差费用',
    categoryKeys: ['交通', '住宿', '餐饮', '门票', '购物'],
    tagKeys: ['旅行'],
    suggestedBudget: 10000,
  ),
  SceneTemplate(
    id: 'renovation',
    name: '装修',
    emoji: '\u{1F3D7}\u{FE0F}',
    description: '家装与装修预算',
    categoryKeys: ['材料', '人工', '家电', '家具', '设计'],
    tagKeys: ['装修'],
    suggestedBudget: 50000,
  ),
  SceneTemplate(
    id: 'family',
    name: '情侣家庭',
    emoji: '\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}',
    description: '家庭共同开支',
    categoryKeys: ['餐饮', '礼物', '娱乐', '日用', '医疗'],
    tagKeys: ['家庭'],
    suggestedBudget: 8000,
  ),
  SceneTemplate(
    id: 'pet',
    name: '宠物',
    emoji: '\u{1F43E}',
    description: '宠物日常花销',
    categoryKeys: ['食品', '医疗', '用品', '洗护', '寄养'],
    tagKeys: ['宠物'],
    suggestedBudget: 2000,
  ),
  SceneTemplate(
    id: 'freelance',
    name: '自由职业',
    emoji: '\u{1F4BB}',
    description: '自由职业收支',
    categoryKeys: ['设备', '软件', '办公', '税费', '收入'],
    tagKeys: ['工作'],
    suggestedBudget: 3000,
  ),
];
