// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_action_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveQuickActionCollection on Isar {
  IsarCollection<JiveQuickAction> get jiveQuickActions => this.collection();
}

const JiveQuickActionSchema = CollectionSchema(
  name: r'JiveQuickAction',
  id: 6476775754465961507,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'archived': PropertySchema(
      id: 1,
      name: r'archived',
      type: IsarType.bool,
    ),
    r'bookId': PropertySchema(
      id: 2,
      name: r'bookId',
      type: IsarType.long,
    ),
    r'categoryKey': PropertySchema(
      id: 3,
      name: r'categoryKey',
      type: IsarType.string,
    ),
    r'categoryName': PropertySchema(
      id: 4,
      name: r'categoryName',
      type: IsarType.string,
    ),
    r'colorHex': PropertySchema(
      id: 5,
      name: r'colorHex',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 6,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'defaultAmount': PropertySchema(
      id: 7,
      name: r'defaultAmount',
      type: IsarType.double,
    ),
    r'defaultNote': PropertySchema(
      id: 8,
      name: r'defaultNote',
      type: IsarType.string,
    ),
    r'iconName': PropertySchema(
      id: 9,
      name: r'iconName',
      type: IsarType.string,
    ),
    r'isPinned': PropertySchema(
      id: 10,
      name: r'isPinned',
      type: IsarType.bool,
    ),
    r'lastUsedAt': PropertySchema(
      id: 11,
      name: r'lastUsedAt',
      type: IsarType.dateTime,
    ),
    r'legacyTemplateId': PropertySchema(
      id: 12,
      name: r'legacyTemplateId',
      type: IsarType.long,
    ),
    r'mode': PropertySchema(
      id: 13,
      name: r'mode',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 14,
      name: r'name',
      type: IsarType.string,
    ),
    r'showOnHome': PropertySchema(
      id: 15,
      name: r'showOnHome',
      type: IsarType.bool,
    ),
    r'sortOrder': PropertySchema(
      id: 16,
      name: r'sortOrder',
      type: IsarType.long,
    ),
    r'source': PropertySchema(
      id: 17,
      name: r'source',
      type: IsarType.string,
    ),
    r'stableId': PropertySchema(
      id: 18,
      name: r'stableId',
      type: IsarType.string,
    ),
    r'subCategoryKey': PropertySchema(
      id: 19,
      name: r'subCategoryKey',
      type: IsarType.string,
    ),
    r'subCategoryName': PropertySchema(
      id: 20,
      name: r'subCategoryName',
      type: IsarType.string,
    ),
    r'tagKeys': PropertySchema(
      id: 21,
      name: r'tagKeys',
      type: IsarType.stringList,
    ),
    r'toAccountId': PropertySchema(
      id: 22,
      name: r'toAccountId',
      type: IsarType.long,
    ),
    r'transactionType': PropertySchema(
      id: 23,
      name: r'transactionType',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 24,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'usageCount': PropertySchema(
      id: 25,
      name: r'usageCount',
      type: IsarType.long,
    )
  },
  estimateSize: _jiveQuickActionEstimateSize,
  serialize: _jiveQuickActionSerialize,
  deserialize: _jiveQuickActionDeserialize,
  deserializeProp: _jiveQuickActionDeserializeProp,
  idName: r'id',
  indexes: {
    r'stableId': IndexSchema(
      id: 8172736602419351792,
      name: r'stableId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'stableId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveQuickActionGetId,
  getLinks: _jiveQuickActionGetLinks,
  attach: _jiveQuickActionAttach,
  version: '3.1.0+1',
);

int _jiveQuickActionEstimateSize(
  JiveQuickAction object,
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
  {
    final value = object.categoryName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.colorHex;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.defaultNote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.iconName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mode.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.stableId.length * 3;
  {
    final value = object.subCategoryKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.subCategoryName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tagKeys.length * 3;
  {
    for (var i = 0; i < object.tagKeys.length; i++) {
      final value = object.tagKeys[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.transactionType.length * 3;
  return bytesCount;
}

void _jiveQuickActionSerialize(
  JiveQuickAction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeBool(offsets[1], object.archived);
  writer.writeLong(offsets[2], object.bookId);
  writer.writeString(offsets[3], object.categoryKey);
  writer.writeString(offsets[4], object.categoryName);
  writer.writeString(offsets[5], object.colorHex);
  writer.writeDateTime(offsets[6], object.createdAt);
  writer.writeDouble(offsets[7], object.defaultAmount);
  writer.writeString(offsets[8], object.defaultNote);
  writer.writeString(offsets[9], object.iconName);
  writer.writeBool(offsets[10], object.isPinned);
  writer.writeDateTime(offsets[11], object.lastUsedAt);
  writer.writeLong(offsets[12], object.legacyTemplateId);
  writer.writeString(offsets[13], object.mode);
  writer.writeString(offsets[14], object.name);
  writer.writeBool(offsets[15], object.showOnHome);
  writer.writeLong(offsets[16], object.sortOrder);
  writer.writeString(offsets[17], object.source);
  writer.writeString(offsets[18], object.stableId);
  writer.writeString(offsets[19], object.subCategoryKey);
  writer.writeString(offsets[20], object.subCategoryName);
  writer.writeStringList(offsets[21], object.tagKeys);
  writer.writeLong(offsets[22], object.toAccountId);
  writer.writeString(offsets[23], object.transactionType);
  writer.writeDateTime(offsets[24], object.updatedAt);
  writer.writeLong(offsets[25], object.usageCount);
}

JiveQuickAction _jiveQuickActionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveQuickAction();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.archived = reader.readBool(offsets[1]);
  object.bookId = reader.readLongOrNull(offsets[2]);
  object.categoryKey = reader.readStringOrNull(offsets[3]);
  object.categoryName = reader.readStringOrNull(offsets[4]);
  object.colorHex = reader.readStringOrNull(offsets[5]);
  object.createdAt = reader.readDateTime(offsets[6]);
  object.defaultAmount = reader.readDoubleOrNull(offsets[7]);
  object.defaultNote = reader.readStringOrNull(offsets[8]);
  object.iconName = reader.readStringOrNull(offsets[9]);
  object.id = id;
  object.isPinned = reader.readBool(offsets[10]);
  object.lastUsedAt = reader.readDateTimeOrNull(offsets[11]);
  object.legacyTemplateId = reader.readLongOrNull(offsets[12]);
  object.mode = reader.readString(offsets[13]);
  object.name = reader.readString(offsets[14]);
  object.showOnHome = reader.readBool(offsets[15]);
  object.sortOrder = reader.readLong(offsets[16]);
  object.source = reader.readString(offsets[17]);
  object.stableId = reader.readString(offsets[18]);
  object.subCategoryKey = reader.readStringOrNull(offsets[19]);
  object.subCategoryName = reader.readStringOrNull(offsets[20]);
  object.tagKeys = reader.readStringList(offsets[21]) ?? [];
  object.toAccountId = reader.readLongOrNull(offsets[22]);
  object.transactionType = reader.readString(offsets[23]);
  object.updatedAt = reader.readDateTime(offsets[24]);
  object.usageCount = reader.readLong(offsets[25]);
  return object;
}

P _jiveQuickActionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readStringList(offset) ?? []) as P;
    case 22:
      return (reader.readLongOrNull(offset)) as P;
    case 23:
      return (reader.readString(offset)) as P;
    case 24:
      return (reader.readDateTime(offset)) as P;
    case 25:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveQuickActionGetId(JiveQuickAction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveQuickActionGetLinks(JiveQuickAction object) {
  return [];
}

void _jiveQuickActionAttach(
    IsarCollection<dynamic> col, Id id, JiveQuickAction object) {
  object.id = id;
}

extension JiveQuickActionByIndex on IsarCollection<JiveQuickAction> {
  Future<JiveQuickAction?> getByStableId(String stableId) {
    return getByIndex(r'stableId', [stableId]);
  }

  JiveQuickAction? getByStableIdSync(String stableId) {
    return getByIndexSync(r'stableId', [stableId]);
  }

  Future<bool> deleteByStableId(String stableId) {
    return deleteByIndex(r'stableId', [stableId]);
  }

  bool deleteByStableIdSync(String stableId) {
    return deleteByIndexSync(r'stableId', [stableId]);
  }

  Future<List<JiveQuickAction?>> getAllByStableId(List<String> stableIdValues) {
    final values = stableIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'stableId', values);
  }

  List<JiveQuickAction?> getAllByStableIdSync(List<String> stableIdValues) {
    final values = stableIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'stableId', values);
  }

  Future<int> deleteAllByStableId(List<String> stableIdValues) {
    final values = stableIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'stableId', values);
  }

  int deleteAllByStableIdSync(List<String> stableIdValues) {
    final values = stableIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'stableId', values);
  }

  Future<Id> putByStableId(JiveQuickAction object) {
    return putByIndex(r'stableId', object);
  }

  Id putByStableIdSync(JiveQuickAction object, {bool saveLinks = true}) {
    return putByIndexSync(r'stableId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByStableId(List<JiveQuickAction> objects) {
    return putAllByIndex(r'stableId', objects);
  }

  List<Id> putAllByStableIdSync(List<JiveQuickAction> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'stableId', objects, saveLinks: saveLinks);
  }
}

extension JiveQuickActionQueryWhereSort
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QWhere> {
  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveQuickActionQueryWhere
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QWhereClause> {
  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterWhereClause>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterWhereClause>
      stableIdEqualTo(String stableId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'stableId',
        value: [stableId],
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterWhereClause>
      stableIdNotEqualTo(String stableId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'stableId',
              lower: [],
              upper: [stableId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'stableId',
              lower: [stableId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'stableId',
              lower: [stableId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'stableId',
              lower: [],
              upper: [stableId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveQuickActionQueryFilter
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QFilterCondition> {
  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      accountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      archivedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'archived',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      bookIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bookId',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      bookIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bookId',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      bookIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      bookIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      bookIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      bookIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryKey',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryKey',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryName',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryName',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      categoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      colorHexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorHex',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      colorHexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorHex',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      colorHexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      colorHexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorHex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      colorHexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      colorHexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'defaultAmount',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'defaultAmount',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'defaultNote',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'defaultNote',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'defaultNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'defaultNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'defaultNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'defaultNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultNote',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      defaultNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'defaultNote',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'iconName',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'iconName',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameEqualTo(
    String? value, {
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameGreaterThan(
    String? value, {
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameLessThan(
    String? value, {
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'iconName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      iconNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'iconName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      isPinnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPinned',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      lastUsedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUsedAt',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      lastUsedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUsedAt',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      lastUsedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      lastUsedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      lastUsedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      lastUsedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUsedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      legacyTemplateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'legacyTemplateId',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      legacyTemplateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'legacyTemplateId',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      legacyTemplateIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'legacyTemplateId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      legacyTemplateIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'legacyTemplateId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      legacyTemplateIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'legacyTemplateId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      legacyTemplateIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'legacyTemplateId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mode',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      showOnHomeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'showOnHome',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sortOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sortOrderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sortOrderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sortOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sortOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stableId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stableId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stableId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stableId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stableId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stableId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stableId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stableId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stableId',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      stableIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stableId',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subCategoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subCategoryName',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subCategoryName',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subCategoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subCategoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      subCategoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subCategoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      tagKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      tagKeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagKeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      tagKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      tagKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      toAccountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'toAccountId',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      toAccountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'toAccountId',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      toAccountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transactionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transactionType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      transactionTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transactionType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
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

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      usageCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      usageCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      usageCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterFilterCondition>
      usageCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usageCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveQuickActionQueryObject
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QFilterCondition> {}

extension JiveQuickActionQueryLinks
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QFilterCondition> {}

extension JiveQuickActionQuerySortBy
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QSortBy> {
  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'archived', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'archived', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> sortByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByDefaultAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByDefaultAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByDefaultNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultNote', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByDefaultNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultNote', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByIconName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByIconNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByLastUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByLegacyTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'legacyTemplateId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByLegacyTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'legacyTemplateId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByShowOnHome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnHome', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByShowOnHomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnHome', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByStableId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stableId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByStableIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stableId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortBySubCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryName', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortBySubCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryName', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByToAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByUsageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageCount', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      sortByUsageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageCount', Sort.desc);
    });
  }
}

extension JiveQuickActionQuerySortThenBy
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QSortThenBy> {
  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'archived', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'archived', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> thenByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByDefaultAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByDefaultAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByDefaultNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultNote', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByDefaultNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultNote', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByIconName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByIconNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByLastUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByLegacyTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'legacyTemplateId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByLegacyTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'legacyTemplateId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByShowOnHome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnHome', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByShowOnHomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnHome', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByStableId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stableId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByStableIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stableId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenBySubCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryName', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenBySubCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryName', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByToAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByUsageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageCount', Sort.asc);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QAfterSortBy>
      thenByUsageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageCount', Sort.desc);
    });
  }
}

extension JiveQuickActionQueryWhereDistinct
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct> {
  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'archived');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct> distinctByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookId');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByCategoryName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct> distinctByColorHex(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorHex', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByDefaultAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultAmount');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByDefaultNote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultNote', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct> distinctByIconName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUsedAt');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByLegacyTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'legacyTemplateId');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct> distinctByMode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByShowOnHome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showOnHome');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortOrder');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct> distinctByStableId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stableId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctBySubCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCategoryKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctBySubCategoryName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCategoryName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByTagKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagKeys');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toAccountId');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByTransactionType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<JiveQuickAction, JiveQuickAction, QDistinct>
      distinctByUsageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usageCount');
    });
  }
}

extension JiveQuickActionQueryProperty
    on QueryBuilder<JiveQuickAction, JiveQuickAction, QQueryProperty> {
  QueryBuilder<JiveQuickAction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveQuickAction, int?, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveQuickAction, bool, QQueryOperations> archivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'archived');
    });
  }

  QueryBuilder<JiveQuickAction, int?, QQueryOperations> bookIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookId');
    });
  }

  QueryBuilder<JiveQuickAction, String?, QQueryOperations>
      categoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryKey');
    });
  }

  QueryBuilder<JiveQuickAction, String?, QQueryOperations>
      categoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryName');
    });
  }

  QueryBuilder<JiveQuickAction, String?, QQueryOperations> colorHexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorHex');
    });
  }

  QueryBuilder<JiveQuickAction, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveQuickAction, double?, QQueryOperations>
      defaultAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultAmount');
    });
  }

  QueryBuilder<JiveQuickAction, String?, QQueryOperations>
      defaultNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultNote');
    });
  }

  QueryBuilder<JiveQuickAction, String?, QQueryOperations> iconNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconName');
    });
  }

  QueryBuilder<JiveQuickAction, bool, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<JiveQuickAction, DateTime?, QQueryOperations>
      lastUsedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsedAt');
    });
  }

  QueryBuilder<JiveQuickAction, int?, QQueryOperations>
      legacyTemplateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'legacyTemplateId');
    });
  }

  QueryBuilder<JiveQuickAction, String, QQueryOperations> modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<JiveQuickAction, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<JiveQuickAction, bool, QQueryOperations> showOnHomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showOnHome');
    });
  }

  QueryBuilder<JiveQuickAction, int, QQueryOperations> sortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortOrder');
    });
  }

  QueryBuilder<JiveQuickAction, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<JiveQuickAction, String, QQueryOperations> stableIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stableId');
    });
  }

  QueryBuilder<JiveQuickAction, String?, QQueryOperations>
      subCategoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategoryKey');
    });
  }

  QueryBuilder<JiveQuickAction, String?, QQueryOperations>
      subCategoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategoryName');
    });
  }

  QueryBuilder<JiveQuickAction, List<String>, QQueryOperations>
      tagKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagKeys');
    });
  }

  QueryBuilder<JiveQuickAction, int?, QQueryOperations> toAccountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toAccountId');
    });
  }

  QueryBuilder<JiveQuickAction, String, QQueryOperations>
      transactionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionType');
    });
  }

  QueryBuilder<JiveQuickAction, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<JiveQuickAction, int, QQueryOperations> usageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usageCount');
    });
  }
}
