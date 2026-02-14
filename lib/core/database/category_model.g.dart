// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveCategoryCollection on Isar {
  IsarCollection<JiveCategory> get jiveCategorys => this.collection();
}

const JiveCategorySchema = CollectionSchema(
  name: r'JiveCategory',
  id: -3553793504067536997,
  properties: {
    r'colorHex': PropertySchema(
      id: 0,
      name: r'colorHex',
      type: IsarType.string,
    ),
    r'excludeFromBudget': PropertySchema(
      id: 1,
      name: r'excludeFromBudget',
      type: IsarType.bool,
    ),
    r'iconForceTinted': PropertySchema(
      id: 2,
      name: r'iconForceTinted',
      type: IsarType.bool,
    ),
    r'iconName': PropertySchema(
      id: 3,
      name: r'iconName',
      type: IsarType.string,
    ),
    r'isHidden': PropertySchema(
      id: 4,
      name: r'isHidden',
      type: IsarType.bool,
    ),
    r'isIncome': PropertySchema(
      id: 5,
      name: r'isIncome',
      type: IsarType.bool,
    ),
    r'isSystem': PropertySchema(
      id: 6,
      name: r'isSystem',
      type: IsarType.bool,
    ),
    r'key': PropertySchema(
      id: 7,
      name: r'key',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 8,
      name: r'name',
      type: IsarType.string,
    ),
    r'order': PropertySchema(
      id: 9,
      name: r'order',
      type: IsarType.long,
    ),
    r'parentKey': PropertySchema(
      id: 10,
      name: r'parentKey',
      type: IsarType.string,
    ),
    r'sourceTagKey': PropertySchema(
      id: 11,
      name: r'sourceTagKey',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveCategoryEstimateSize,
  serialize: _jiveCategorySerialize,
  deserialize: _jiveCategoryDeserialize,
  deserializeProp: _jiveCategoryDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'parentKey': IndexSchema(
      id: -4059840480139009881,
      name: r'parentKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'parentKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'sourceTagKey': IndexSchema(
      id: 1396240213232614003,
      name: r'sourceTagKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sourceTagKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveCategoryGetId,
  getLinks: _jiveCategoryGetLinks,
  attach: _jiveCategoryAttach,
  version: '3.1.0+1',
);

int _jiveCategoryEstimateSize(
  JiveCategory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.colorHex;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.iconName.length * 3;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.parentKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sourceTagKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _jiveCategorySerialize(
  JiveCategory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.colorHex);
  writer.writeBool(offsets[1], object.excludeFromBudget);
  writer.writeBool(offsets[2], object.iconForceTinted);
  writer.writeString(offsets[3], object.iconName);
  writer.writeBool(offsets[4], object.isHidden);
  writer.writeBool(offsets[5], object.isIncome);
  writer.writeBool(offsets[6], object.isSystem);
  writer.writeString(offsets[7], object.key);
  writer.writeString(offsets[8], object.name);
  writer.writeLong(offsets[9], object.order);
  writer.writeString(offsets[10], object.parentKey);
  writer.writeString(offsets[11], object.sourceTagKey);
  writer.writeDateTime(offsets[12], object.updatedAt);
}

JiveCategory _jiveCategoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveCategory();
  object.colorHex = reader.readStringOrNull(offsets[0]);
  object.excludeFromBudget = reader.readBool(offsets[1]);
  object.iconForceTinted = reader.readBool(offsets[2]);
  object.iconName = reader.readString(offsets[3]);
  object.id = id;
  object.isHidden = reader.readBool(offsets[4]);
  object.isIncome = reader.readBool(offsets[5]);
  object.isSystem = reader.readBool(offsets[6]);
  object.key = reader.readString(offsets[7]);
  object.name = reader.readString(offsets[8]);
  object.order = reader.readLong(offsets[9]);
  object.parentKey = reader.readStringOrNull(offsets[10]);
  object.sourceTagKey = reader.readStringOrNull(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  return object;
}

P _jiveCategoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveCategoryGetId(JiveCategory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveCategoryGetLinks(JiveCategory object) {
  return [];
}

void _jiveCategoryAttach(
    IsarCollection<dynamic> col, Id id, JiveCategory object) {
  object.id = id;
}

extension JiveCategoryByIndex on IsarCollection<JiveCategory> {
  Future<JiveCategory?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  JiveCategory? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<JiveCategory?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<JiveCategory?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(JiveCategory object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(JiveCategory object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<JiveCategory> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<JiveCategory> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension JiveCategoryQueryWhereSort
    on QueryBuilder<JiveCategory, JiveCategory, QWhere> {
  QueryBuilder<JiveCategory, JiveCategory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveCategoryQueryWhere
    on QueryBuilder<JiveCategory, JiveCategory, QWhereClause> {
  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause> keyEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause> keyNotEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause>
      parentKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'parentKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause>
      parentKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'parentKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause> parentKeyEqualTo(
      String? parentKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'parentKey',
        value: [parentKey],
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause>
      parentKeyNotEqualTo(String? parentKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'parentKey',
              lower: [],
              upper: [parentKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'parentKey',
              lower: [parentKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'parentKey',
              lower: [parentKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'parentKey',
              lower: [],
              upper: [parentKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause>
      sourceTagKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sourceTagKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause>
      sourceTagKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sourceTagKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause>
      sourceTagKeyEqualTo(String? sourceTagKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sourceTagKey',
        value: [sourceTagKey],
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterWhereClause>
      sourceTagKeyNotEqualTo(String? sourceTagKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceTagKey',
              lower: [],
              upper: [sourceTagKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceTagKey',
              lower: [sourceTagKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceTagKey',
              lower: [sourceTagKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceTagKey',
              lower: [],
              upper: [sourceTagKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveCategoryQueryFilter
    on QueryBuilder<JiveCategory, JiveCategory, QFilterCondition> {
  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorHex',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorHex',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorHex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorHex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      colorHexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      excludeFromBudgetEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'excludeFromBudget',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconForceTintedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconForceTinted',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iconName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'iconName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      iconNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'iconName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      isHiddenEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isHidden',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      isIncomeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isIncome',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      isSystemEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSystem',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> keyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> keyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> orderEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      orderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> orderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition> orderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'order',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentKey',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentKey',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parentKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parentKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parentKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parentKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      parentKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parentKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceTagKey',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceTagKey',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceTagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceTagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceTagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceTagKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceTagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceTagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceTagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceTagKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceTagKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      sourceTagKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceTagKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveCategoryQueryObject
    on QueryBuilder<JiveCategory, JiveCategory, QFilterCondition> {}

extension JiveCategoryQueryLinks
    on QueryBuilder<JiveCategory, JiveCategory, QFilterCondition> {}

extension JiveCategoryQuerySortBy
    on QueryBuilder<JiveCategory, JiveCategory, QSortBy> {
  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      sortByExcludeFromBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudget', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      sortByExcludeFromBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudget', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      sortByIconForceTinted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconForceTinted', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      sortByIconForceTintedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconForceTinted', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByIconName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByIconNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByIsHiddenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncome', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByIsIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncome', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByIsSystem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSystem', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByIsSystemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSystem', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByParentKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentKey', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByParentKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentKey', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortBySourceTagKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceTagKey', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      sortBySourceTagKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceTagKey', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveCategoryQuerySortThenBy
    on QueryBuilder<JiveCategory, JiveCategory, QSortThenBy> {
  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      thenByExcludeFromBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudget', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      thenByExcludeFromBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudget', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      thenByIconForceTinted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconForceTinted', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      thenByIconForceTintedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconForceTinted', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIconName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIconNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIsHiddenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncome', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIsIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncome', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIsSystem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSystem', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByIsSystemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSystem', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByParentKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentKey', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByParentKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentKey', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenBySourceTagKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceTagKey', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy>
      thenBySourceTagKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceTagKey', Sort.desc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveCategoryQueryWhereDistinct
    on QueryBuilder<JiveCategory, JiveCategory, QDistinct> {
  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByColorHex(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorHex', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct>
      distinctByExcludeFromBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'excludeFromBudget');
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct>
      distinctByIconForceTinted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconForceTinted');
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByIconName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isHidden');
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isIncome');
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByIsSystem() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSystem');
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'order');
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByParentKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctBySourceTagKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceTagKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategory, JiveCategory, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveCategoryQueryProperty
    on QueryBuilder<JiveCategory, JiveCategory, QQueryProperty> {
  QueryBuilder<JiveCategory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveCategory, String?, QQueryOperations> colorHexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorHex');
    });
  }

  QueryBuilder<JiveCategory, bool, QQueryOperations>
      excludeFromBudgetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'excludeFromBudget');
    });
  }

  QueryBuilder<JiveCategory, bool, QQueryOperations> iconForceTintedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconForceTinted');
    });
  }

  QueryBuilder<JiveCategory, String, QQueryOperations> iconNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconName');
    });
  }

  QueryBuilder<JiveCategory, bool, QQueryOperations> isHiddenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isHidden');
    });
  }

  QueryBuilder<JiveCategory, bool, QQueryOperations> isIncomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isIncome');
    });
  }

  QueryBuilder<JiveCategory, bool, QQueryOperations> isSystemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSystem');
    });
  }

  QueryBuilder<JiveCategory, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<JiveCategory, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<JiveCategory, int, QQueryOperations> orderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'order');
    });
  }

  QueryBuilder<JiveCategory, String?, QQueryOperations> parentKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentKey');
    });
  }

  QueryBuilder<JiveCategory, String?, QQueryOperations> sourceTagKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceTagKey');
    });
  }

  QueryBuilder<JiveCategory, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveCategoryOverrideCollection on Isar {
  IsarCollection<JiveCategoryOverride> get jiveCategoryOverrides =>
      this.collection();
}

const JiveCategoryOverrideSchema = CollectionSchema(
  name: r'JiveCategoryOverride',
  id: -1839205628893422052,
  properties: {
    r'colorHexOverride': PropertySchema(
      id: 0,
      name: r'colorHexOverride',
      type: IsarType.string,
    ),
    r'excludeFromBudgetOverride': PropertySchema(
      id: 1,
      name: r'excludeFromBudgetOverride',
      type: IsarType.bool,
    ),
    r'iconOverride': PropertySchema(
      id: 2,
      name: r'iconOverride',
      type: IsarType.string,
    ),
    r'isHiddenOverride': PropertySchema(
      id: 3,
      name: r'isHiddenOverride',
      type: IsarType.bool,
    ),
    r'nameOverride': PropertySchema(
      id: 4,
      name: r'nameOverride',
      type: IsarType.string,
    ),
    r'orderOverride': PropertySchema(
      id: 5,
      name: r'orderOverride',
      type: IsarType.long,
    ),
    r'parentOverrideKey': PropertySchema(
      id: 6,
      name: r'parentOverrideKey',
      type: IsarType.string,
    ),
    r'systemKey': PropertySchema(
      id: 7,
      name: r'systemKey',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveCategoryOverrideEstimateSize,
  serialize: _jiveCategoryOverrideSerialize,
  deserialize: _jiveCategoryOverrideDeserialize,
  deserializeProp: _jiveCategoryOverrideDeserializeProp,
  idName: r'id',
  indexes: {
    r'systemKey': IndexSchema(
      id: -165220230884495247,
      name: r'systemKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'systemKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveCategoryOverrideGetId,
  getLinks: _jiveCategoryOverrideGetLinks,
  attach: _jiveCategoryOverrideAttach,
  version: '3.1.0+1',
);

int _jiveCategoryOverrideEstimateSize(
  JiveCategoryOverride object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.colorHexOverride;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.iconOverride;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.nameOverride;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.parentOverrideKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.systemKey.length * 3;
  return bytesCount;
}

void _jiveCategoryOverrideSerialize(
  JiveCategoryOverride object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.colorHexOverride);
  writer.writeBool(offsets[1], object.excludeFromBudgetOverride);
  writer.writeString(offsets[2], object.iconOverride);
  writer.writeBool(offsets[3], object.isHiddenOverride);
  writer.writeString(offsets[4], object.nameOverride);
  writer.writeLong(offsets[5], object.orderOverride);
  writer.writeString(offsets[6], object.parentOverrideKey);
  writer.writeString(offsets[7], object.systemKey);
  writer.writeDateTime(offsets[8], object.updatedAt);
}

JiveCategoryOverride _jiveCategoryOverrideDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveCategoryOverride();
  object.colorHexOverride = reader.readStringOrNull(offsets[0]);
  object.excludeFromBudgetOverride = reader.readBoolOrNull(offsets[1]);
  object.iconOverride = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.isHiddenOverride = reader.readBoolOrNull(offsets[3]);
  object.nameOverride = reader.readStringOrNull(offsets[4]);
  object.orderOverride = reader.readLongOrNull(offsets[5]);
  object.parentOverrideKey = reader.readStringOrNull(offsets[6]);
  object.systemKey = reader.readString(offsets[7]);
  object.updatedAt = reader.readDateTime(offsets[8]);
  return object;
}

P _jiveCategoryOverrideDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveCategoryOverrideGetId(JiveCategoryOverride object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveCategoryOverrideGetLinks(
    JiveCategoryOverride object) {
  return [];
}

void _jiveCategoryOverrideAttach(
    IsarCollection<dynamic> col, Id id, JiveCategoryOverride object) {
  object.id = id;
}

extension JiveCategoryOverrideByIndex on IsarCollection<JiveCategoryOverride> {
  Future<JiveCategoryOverride?> getBySystemKey(String systemKey) {
    return getByIndex(r'systemKey', [systemKey]);
  }

  JiveCategoryOverride? getBySystemKeySync(String systemKey) {
    return getByIndexSync(r'systemKey', [systemKey]);
  }

  Future<bool> deleteBySystemKey(String systemKey) {
    return deleteByIndex(r'systemKey', [systemKey]);
  }

  bool deleteBySystemKeySync(String systemKey) {
    return deleteByIndexSync(r'systemKey', [systemKey]);
  }

  Future<List<JiveCategoryOverride?>> getAllBySystemKey(
      List<String> systemKeyValues) {
    final values = systemKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'systemKey', values);
  }

  List<JiveCategoryOverride?> getAllBySystemKeySync(
      List<String> systemKeyValues) {
    final values = systemKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'systemKey', values);
  }

  Future<int> deleteAllBySystemKey(List<String> systemKeyValues) {
    final values = systemKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'systemKey', values);
  }

  int deleteAllBySystemKeySync(List<String> systemKeyValues) {
    final values = systemKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'systemKey', values);
  }

  Future<Id> putBySystemKey(JiveCategoryOverride object) {
    return putByIndex(r'systemKey', object);
  }

  Id putBySystemKeySync(JiveCategoryOverride object, {bool saveLinks = true}) {
    return putByIndexSync(r'systemKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySystemKey(List<JiveCategoryOverride> objects) {
    return putAllByIndex(r'systemKey', objects);
  }

  List<Id> putAllBySystemKeySync(List<JiveCategoryOverride> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'systemKey', objects, saveLinks: saveLinks);
  }
}

extension JiveCategoryOverrideQueryWhereSort
    on QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QWhere> {
  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveCategoryOverrideQueryWhere
    on QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QWhereClause> {
  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterWhereClause>
      systemKeyEqualTo(String systemKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'systemKey',
        value: [systemKey],
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterWhereClause>
      systemKeyNotEqualTo(String systemKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'systemKey',
              lower: [],
              upper: [systemKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'systemKey',
              lower: [systemKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'systemKey',
              lower: [systemKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'systemKey',
              lower: [],
              upper: [systemKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveCategoryOverrideQueryFilter on QueryBuilder<JiveCategoryOverride,
    JiveCategoryOverride, QFilterCondition> {
  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorHexOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorHexOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHexOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorHexOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorHexOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorHexOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'colorHexOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'colorHexOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      colorHexOverrideContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorHexOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      colorHexOverrideMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorHexOverride',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHexOverride',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> colorHexOverrideIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorHexOverride',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> excludeFromBudgetOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'excludeFromBudgetOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> excludeFromBudgetOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'excludeFromBudgetOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> excludeFromBudgetOverrideEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'excludeFromBudgetOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'iconOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'iconOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iconOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iconOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iconOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'iconOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'iconOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      iconOverrideContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'iconOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      iconOverrideMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'iconOverride',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconOverride',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> iconOverrideIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'iconOverride',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> isHiddenOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isHiddenOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> isHiddenOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isHiddenOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> isHiddenOverrideEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isHiddenOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nameOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nameOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      nameOverrideContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      nameOverrideMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameOverride',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameOverride',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> nameOverrideIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameOverride',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> orderOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> orderOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderOverride',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> orderOverrideEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> orderOverrideGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> orderOverrideLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> orderOverrideBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentOverrideKey',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentOverrideKey',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentOverrideKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentOverrideKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentOverrideKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentOverrideKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parentOverrideKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parentOverrideKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      parentOverrideKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parentOverrideKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      parentOverrideKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parentOverrideKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentOverrideKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> parentOverrideKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parentOverrideKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> systemKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'systemKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> systemKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'systemKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> systemKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'systemKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> systemKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'systemKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> systemKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'systemKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> systemKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'systemKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      systemKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'systemKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
          QAfterFilterCondition>
      systemKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'systemKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> systemKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'systemKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> systemKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'systemKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveCategoryOverrideQueryObject on QueryBuilder<JiveCategoryOverride,
    JiveCategoryOverride, QFilterCondition> {}

extension JiveCategoryOverrideQueryLinks on QueryBuilder<JiveCategoryOverride,
    JiveCategoryOverride, QFilterCondition> {}

extension JiveCategoryOverrideQuerySortBy
    on QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QSortBy> {
  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByColorHexOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHexOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByColorHexOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHexOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByExcludeFromBudgetOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudgetOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByExcludeFromBudgetOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudgetOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByIconOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByIconOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByIsHiddenOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHiddenOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByIsHiddenOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHiddenOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByNameOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByNameOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByOrderOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByOrderOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByParentOverrideKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentOverrideKey', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByParentOverrideKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentOverrideKey', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortBySystemKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systemKey', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortBySystemKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systemKey', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveCategoryOverrideQuerySortThenBy
    on QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QSortThenBy> {
  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByColorHexOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHexOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByColorHexOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHexOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByExcludeFromBudgetOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudgetOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByExcludeFromBudgetOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudgetOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByIconOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByIconOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByIsHiddenOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHiddenOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByIsHiddenOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHiddenOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByNameOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByNameOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByOrderOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderOverride', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByOrderOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderOverride', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByParentOverrideKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentOverrideKey', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByParentOverrideKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentOverrideKey', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenBySystemKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systemKey', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenBySystemKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systemKey', Sort.desc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveCategoryOverrideQueryWhereDistinct
    on QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct> {
  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctByColorHexOverride({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorHexOverride',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctByExcludeFromBudgetOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'excludeFromBudgetOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctByIconOverride({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconOverride', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctByIsHiddenOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isHiddenOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctByNameOverride({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameOverride', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctByOrderOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctByParentOverrideKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentOverrideKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctBySystemKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'systemKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCategoryOverride, JiveCategoryOverride, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveCategoryOverrideQueryProperty on QueryBuilder<
    JiveCategoryOverride, JiveCategoryOverride, QQueryProperty> {
  QueryBuilder<JiveCategoryOverride, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveCategoryOverride, String?, QQueryOperations>
      colorHexOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorHexOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, bool?, QQueryOperations>
      excludeFromBudgetOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'excludeFromBudgetOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, String?, QQueryOperations>
      iconOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, bool?, QQueryOperations>
      isHiddenOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isHiddenOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, String?, QQueryOperations>
      nameOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, int?, QQueryOperations>
      orderOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderOverride');
    });
  }

  QueryBuilder<JiveCategoryOverride, String?, QQueryOperations>
      parentOverrideKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentOverrideKey');
    });
  }

  QueryBuilder<JiveCategoryOverride, String, QQueryOperations>
      systemKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'systemKey');
    });
  }

  QueryBuilder<JiveCategoryOverride, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
