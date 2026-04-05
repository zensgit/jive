// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveRecurringRuleCollection on Isar {
  IsarCollection<JiveRecurringRule> get jiveRecurringRules => this.collection();
}

const JiveRecurringRuleSchema = CollectionSchema(
  name: r'JiveRecurringRule',
  id: 2685857197661587846,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.double,
    ),
    r'categoryKey': PropertySchema(
      id: 2,
      name: r'categoryKey',
      type: IsarType.string,
    ),
    r'commitMode': PropertySchema(
      id: 3,
      name: r'commitMode',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dayOfMonth': PropertySchema(
      id: 5,
      name: r'dayOfMonth',
      type: IsarType.long,
    ),
    r'dayOfWeek': PropertySchema(
      id: 6,
      name: r'dayOfWeek',
      type: IsarType.long,
    ),
    r'endDate': PropertySchema(
      id: 7,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'intervalType': PropertySchema(
      id: 8,
      name: r'intervalType',
      type: IsarType.string,
    ),
    r'intervalValue': PropertySchema(
      id: 9,
      name: r'intervalValue',
      type: IsarType.long,
    ),
    r'isActive': PropertySchema(
      id: 10,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'lastRunAt': PropertySchema(
      id: 11,
      name: r'lastRunAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 12,
      name: r'name',
      type: IsarType.string,
    ),
    r'nextRunAt': PropertySchema(
      id: 13,
      name: r'nextRunAt',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(
      id: 14,
      name: r'note',
      type: IsarType.string,
    ),
    r'projectId': PropertySchema(
      id: 15,
      name: r'projectId',
      type: IsarType.long,
    ),
    r'startDate': PropertySchema(
      id: 16,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'subCategoryKey': PropertySchema(
      id: 17,
      name: r'subCategoryKey',
      type: IsarType.string,
    ),
    r'syncKey': PropertySchema(
      id: 18,
      name: r'syncKey',
      type: IsarType.string,
    ),
    r'tagKeys': PropertySchema(
      id: 19,
      name: r'tagKeys',
      type: IsarType.stringList,
    ),
    r'toAccountId': PropertySchema(
      id: 20,
      name: r'toAccountId',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 21,
      name: r'type',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 22,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveRecurringRuleEstimateSize,
  serialize: _jiveRecurringRuleSerialize,
  deserialize: _jiveRecurringRuleDeserialize,
  deserializeProp: _jiveRecurringRuleDeserializeProp,
  idName: r'id',
  indexes: {
    r'nextRunAt': IndexSchema(
      id: 5802913242414580897,
      name: r'nextRunAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nextRunAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'syncKey': IndexSchema(
      id: -4971009725215132130,
      name: r'syncKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveRecurringRuleGetId,
  getLinks: _jiveRecurringRuleGetLinks,
  attach: _jiveRecurringRuleAttach,
  version: '3.1.0+1',
);

int _jiveRecurringRuleEstimateSize(
  JiveRecurringRule object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.categoryKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.commitMode.length * 3;
  bytesCount += 3 + object.intervalType.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.subCategoryKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.syncKey.length * 3;
  bytesCount += 3 + object.tagKeys.length * 3;
  {
    for (var i = 0; i < object.tagKeys.length; i++) {
      final value = object.tagKeys[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _jiveRecurringRuleSerialize(
  JiveRecurringRule object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeString(offsets[2], object.categoryKey);
  writer.writeString(offsets[3], object.commitMode);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeLong(offsets[5], object.dayOfMonth);
  writer.writeLong(offsets[6], object.dayOfWeek);
  writer.writeDateTime(offsets[7], object.endDate);
  writer.writeString(offsets[8], object.intervalType);
  writer.writeLong(offsets[9], object.intervalValue);
  writer.writeBool(offsets[10], object.isActive);
  writer.writeDateTime(offsets[11], object.lastRunAt);
  writer.writeString(offsets[12], object.name);
  writer.writeDateTime(offsets[13], object.nextRunAt);
  writer.writeString(offsets[14], object.note);
  writer.writeLong(offsets[15], object.projectId);
  writer.writeDateTime(offsets[16], object.startDate);
  writer.writeString(offsets[17], object.subCategoryKey);
  writer.writeString(offsets[18], object.syncKey);
  writer.writeStringList(offsets[19], object.tagKeys);
  writer.writeLong(offsets[20], object.toAccountId);
  writer.writeString(offsets[21], object.type);
  writer.writeDateTime(offsets[22], object.updatedAt);
}

JiveRecurringRule _jiveRecurringRuleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveRecurringRule();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.amount = reader.readDouble(offsets[1]);
  object.categoryKey = reader.readStringOrNull(offsets[2]);
  object.commitMode = reader.readString(offsets[3]);
  object.createdAt = reader.readDateTime(offsets[4]);
  object.dayOfMonth = reader.readLongOrNull(offsets[5]);
  object.dayOfWeek = reader.readLongOrNull(offsets[6]);
  object.endDate = reader.readDateTimeOrNull(offsets[7]);
  object.id = id;
  object.intervalType = reader.readString(offsets[8]);
  object.intervalValue = reader.readLong(offsets[9]);
  object.isActive = reader.readBool(offsets[10]);
  object.lastRunAt = reader.readDateTimeOrNull(offsets[11]);
  object.name = reader.readString(offsets[12]);
  object.nextRunAt = reader.readDateTime(offsets[13]);
  object.note = reader.readStringOrNull(offsets[14]);
  object.projectId = reader.readLongOrNull(offsets[15]);
  object.startDate = reader.readDateTime(offsets[16]);
  object.subCategoryKey = reader.readStringOrNull(offsets[17]);
  object.syncKey = reader.readString(offsets[18]);
  object.tagKeys = reader.readStringList(offsets[19]) ?? [];
  object.toAccountId = reader.readLongOrNull(offsets[20]);
  object.type = reader.readString(offsets[21]);
  object.updatedAt = reader.readDateTime(offsets[22]);
  return object;
}

P _jiveRecurringRuleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readStringList(offset) ?? []) as P;
    case 20:
      return (reader.readLongOrNull(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveRecurringRuleGetId(JiveRecurringRule object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveRecurringRuleGetLinks(
    JiveRecurringRule object) {
  return [];
}

void _jiveRecurringRuleAttach(
    IsarCollection<dynamic> col, Id id, JiveRecurringRule object) {
  object.id = id;
}

extension JiveRecurringRuleByIndex on IsarCollection<JiveRecurringRule> {
  Future<JiveRecurringRule?> getBySyncKey(String syncKey) {
    return getByIndex(r'syncKey', [syncKey]);
  }

  JiveRecurringRule? getBySyncKeySync(String syncKey) {
    return getByIndexSync(r'syncKey', [syncKey]);
  }

  Future<bool> deleteBySyncKey(String syncKey) {
    return deleteByIndex(r'syncKey', [syncKey]);
  }

  bool deleteBySyncKeySync(String syncKey) {
    return deleteByIndexSync(r'syncKey', [syncKey]);
  }

  Future<List<JiveRecurringRule?>> getAllBySyncKey(List<String> syncKeyValues) {
    final values = syncKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'syncKey', values);
  }

  List<JiveRecurringRule?> getAllBySyncKeySync(List<String> syncKeyValues) {
    final values = syncKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'syncKey', values);
  }

  Future<int> deleteAllBySyncKey(List<String> syncKeyValues) {
    final values = syncKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'syncKey', values);
  }

  int deleteAllBySyncKeySync(List<String> syncKeyValues) {
    final values = syncKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'syncKey', values);
  }

  Future<Id> putBySyncKey(JiveRecurringRule object) {
    return putByIndex(r'syncKey', object);
  }

  Id putBySyncKeySync(JiveRecurringRule object, {bool saveLinks = true}) {
    return putByIndexSync(r'syncKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySyncKey(List<JiveRecurringRule> objects) {
    return putAllByIndex(r'syncKey', objects);
  }

  List<Id> putAllBySyncKeySync(List<JiveRecurringRule> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'syncKey', objects, saveLinks: saveLinks);
  }
}

extension JiveRecurringRuleQueryWhereSort
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QWhere> {
  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhere>
      anyNextRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'nextRunAt'),
      );
    });
  }
}

extension JiveRecurringRuleQueryWhere
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QWhereClause> {
  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      nextRunAtEqualTo(DateTime nextRunAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nextRunAt',
        value: [nextRunAt],
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      nextRunAtNotEqualTo(DateTime nextRunAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextRunAt',
              lower: [],
              upper: [nextRunAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextRunAt',
              lower: [nextRunAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextRunAt',
              lower: [nextRunAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextRunAt',
              lower: [],
              upper: [nextRunAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      nextRunAtGreaterThan(
    DateTime nextRunAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextRunAt',
        lower: [nextRunAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      nextRunAtLessThan(
    DateTime nextRunAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextRunAt',
        lower: [],
        upper: [nextRunAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      nextRunAtBetween(
    DateTime lowerNextRunAt,
    DateTime upperNextRunAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextRunAt',
        lower: [lowerNextRunAt],
        includeLower: includeLower,
        upper: [upperNextRunAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      syncKeyEqualTo(String syncKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncKey',
        value: [syncKey],
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterWhereClause>
      syncKeyNotEqualTo(String syncKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncKey',
              lower: [],
              upper: [syncKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncKey',
              lower: [syncKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncKey',
              lower: [syncKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncKey',
              lower: [],
              upper: [syncKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveRecurringRuleQueryFilter
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QFilterCondition> {
  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      accountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      accountIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      accountIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      accountIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accountId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryKey',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryKey',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      categoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'commitMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'commitMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'commitMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'commitMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'commitMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'commitMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'commitMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'commitMode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'commitMode',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      commitModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'commitMode',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfMonthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dayOfMonth',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfMonthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dayOfMonth',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfMonthEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayOfMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfMonthGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayOfMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfMonthLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayOfMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfMonthBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayOfMonth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfWeekIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dayOfWeek',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfWeekIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dayOfWeek',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfWeekEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfWeekGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfWeekLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      dayOfWeekBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayOfWeek',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      endDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      endDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      endDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      endDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intervalType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intervalType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intervalType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intervalType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'intervalType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'intervalType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'intervalType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'intervalType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intervalType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'intervalType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intervalValue',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intervalValue',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intervalValue',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      intervalValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intervalValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      lastRunAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastRunAt',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      lastRunAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastRunAt',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      lastRunAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      lastRunAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      lastRunAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      lastRunAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastRunAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nameEqualTo(
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nameLessThan(
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nameBetween(
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nameEndsWith(
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nextRunAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nextRunAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nextRunAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextRunAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      nextRunAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextRunAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      projectIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'projectId',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      projectIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'projectId',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      projectIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      projectIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      projectIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      projectIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      startDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      startDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      startDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      startDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subCategoryKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subCategoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      subCategoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      syncKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tagKeys',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagKeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tagKeys',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tagKeys',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tagKeys',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tagKeys',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tagKeys',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      tagKeysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tagKeys',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      toAccountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'toAccountId',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      toAccountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'toAccountId',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      toAccountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      toAccountIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      toAccountIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      toAccountIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toAccountId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
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

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterFilterCondition>
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

extension JiveRecurringRuleQueryObject
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QFilterCondition> {}

extension JiveRecurringRuleQueryLinks
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QFilterCondition> {}

extension JiveRecurringRuleQuerySortBy
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QSortBy> {
  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByCommitMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commitMode', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByCommitModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commitMode', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfMonth', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByDayOfMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfMonth', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByIntervalType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalType', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByIntervalTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalType', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByIntervalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalValue', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByIntervalValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalValue', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByLastRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRunAt', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByLastRunAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRunAt', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByNextRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRunAt', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByNextRunAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRunAt', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortBySyncKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncKey', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortBySyncKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncKey', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByToAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveRecurringRuleQuerySortThenBy
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QSortThenBy> {
  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByCommitMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commitMode', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByCommitModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commitMode', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfMonth', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByDayOfMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfMonth', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByIntervalType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalType', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByIntervalTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalType', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByIntervalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalValue', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByIntervalValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalValue', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByLastRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRunAt', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByLastRunAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRunAt', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByNextRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRunAt', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByNextRunAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRunAt', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenBySyncKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncKey', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenBySyncKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncKey', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByToAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveRecurringRuleQueryWhereDistinct
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct> {
  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByCommitMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'commitMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayOfMonth');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayOfWeek');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByIntervalType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intervalType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByIntervalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intervalValue');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByLastRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastRunAt');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByNextRunAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextRunAt');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectId');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctBySubCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCategoryKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctBySyncKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByTagKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagKeys');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toAccountId');
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveRecurringRule, JiveRecurringRule, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveRecurringRuleQueryProperty
    on QueryBuilder<JiveRecurringRule, JiveRecurringRule, QQueryProperty> {
  QueryBuilder<JiveRecurringRule, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveRecurringRule, int?, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveRecurringRule, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<JiveRecurringRule, String?, QQueryOperations>
      categoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryKey');
    });
  }

  QueryBuilder<JiveRecurringRule, String, QQueryOperations>
      commitModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'commitMode');
    });
  }

  QueryBuilder<JiveRecurringRule, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveRecurringRule, int?, QQueryOperations> dayOfMonthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayOfMonth');
    });
  }

  QueryBuilder<JiveRecurringRule, int?, QQueryOperations> dayOfWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayOfWeek');
    });
  }

  QueryBuilder<JiveRecurringRule, DateTime?, QQueryOperations>
      endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<JiveRecurringRule, String, QQueryOperations>
      intervalTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intervalType');
    });
  }

  QueryBuilder<JiveRecurringRule, int, QQueryOperations>
      intervalValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intervalValue');
    });
  }

  QueryBuilder<JiveRecurringRule, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<JiveRecurringRule, DateTime?, QQueryOperations>
      lastRunAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastRunAt');
    });
  }

  QueryBuilder<JiveRecurringRule, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<JiveRecurringRule, DateTime, QQueryOperations>
      nextRunAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextRunAt');
    });
  }

  QueryBuilder<JiveRecurringRule, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<JiveRecurringRule, int?, QQueryOperations> projectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectId');
    });
  }

  QueryBuilder<JiveRecurringRule, DateTime, QQueryOperations>
      startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<JiveRecurringRule, String?, QQueryOperations>
      subCategoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategoryKey');
    });
  }

  QueryBuilder<JiveRecurringRule, String, QQueryOperations> syncKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncKey');
    });
  }

  QueryBuilder<JiveRecurringRule, List<String>, QQueryOperations>
      tagKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagKeys');
    });
  }

  QueryBuilder<JiveRecurringRule, int?, QQueryOperations>
      toAccountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toAccountId');
    });
  }

  QueryBuilder<JiveRecurringRule, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<JiveRecurringRule, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
