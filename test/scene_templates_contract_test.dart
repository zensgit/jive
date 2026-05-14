import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/data/scene_templates.dart';

void main() {
  group('MoneyThings scene template contracts', () {
    const requiredTemplateIds = <String>[
      'daily_life',
      'travel',
      'renovation',
      'family',
      'pet',
      'freelance',
    ];

    test('keeps the required scene ids present and well formed', () {
      final ids = kSceneTemplates.map((template) => template.id).toList();

      expect(ids.toSet(), hasLength(ids.length), reason: 'ids must be unique');
      expect(ids, requiredTemplateIds);

      for (final template in kSceneTemplates) {
        expect(template.id.trim(), isNotEmpty);

        expect(template.name.trim(), isNotEmpty);
        expect(template.emoji.trim(), isNotEmpty);
        expect(template.categoryKeys, isNotEmpty);
        expect(
          template.categoryKeys.every((key) => key.trim().isNotEmpty),
          isTrue,
          reason: '${template.id} categories must not contain empty keys',
        );
        expect(template.suggestedBudget, greaterThan(0));
      }
    });

    test(
      'preserves key daily/travel/family/pet/renovation/freelance semantics',
      () {
        final daily = _templateById('daily_life');
        expect(daily.name, contains('日常'));
        expect(daily.categoryKeys, containsAll(<String>['餐饮', '交通']));
        expect(daily.tagKeys, isEmpty);

        final travel = _templateById('travel');
        expect(travel.name, contains('旅行'));
        expect(travel.tagKeys, contains('旅行'));
        expect(travel.categoryKeys, containsAll(<String>['交通', '住宿']));

        final family = _templateById('family');
        expect(family.tagKeys, contains('家庭'));
        expect(_hasAny(family.categoryKeys, {'日用', '医疗'}), isTrue);

        final pet = _templateById('pet');
        expect(pet.tagKeys, contains('宠物'));
        expect(_hasAny(pet.categoryKeys, {'食品', '医疗', '用品'}), isTrue);

        final renovation = _templateById('renovation');
        expect(renovation.tagKeys, contains('装修'));
        expect(_hasAny(renovation.categoryKeys, {'材料', '人工'}), isTrue);

        final freelance = _templateById('freelance');
        expect(freelance.name, contains('自由职业'));
        expect(freelance.tagKeys, contains('工作'));
        expect(freelance.categoryKeys, contains('收入'));
      },
    );
  });
}

SceneTemplate _templateById(String id) {
  return kSceneTemplates.singleWhere((template) => template.id == id);
}

bool _hasAny(Iterable<String> values, Set<String> expected) {
  return values.any(expected.contains);
}
