// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_memory_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveMerchantMemoryCollection on Isar {
  IsarCollection<JiveMerchantMemory> get jiveMerchantMemorys =>
      this.collection();
}

const JiveMerchantMemorySchema = CollectionSchema(
  name: r'JiveMerchantMemory',
  id: -5291471945846380362,
  properties: {
    r'accountFrequencyJson': PropertySchema(
      id: 0,
      name: r'accountFrequencyJson',
      type: IsarType.string,
    ),
    r'aliases': PropertySchema(
      id: 1,
      name: r'aliases',
      type: IsarType.stringList,
    ),
    r'averageAmount': PropertySchema(
      id: 2,
      name: r'averageAmount',
      type: IsarType.double,
    ),
    r'categoryFrequencyJson': PropertySchema(
      id: 3,
      name: r'categoryFrequencyJson',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'displayName': PropertySchema(
      id: 5,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'isUserConfirmed': PropertySchema(
      id: 6,
      name: r'isUserConfirmed',
      type: IsarType.bool,
    ),
    r'lastTransactionAt': PropertySchema(
      id: 7,
      name: r'lastTransactionAt',
      type: IsarType.dateTime,
    ),
    r'normalizedName': PropertySchema(
      id: 8,
      name: r'normalizedName',
      type: IsarType.string,
    ),
    r'preferredAccountId': PropertySchema(
      id: 9,
      name: r'preferredAccountId',
      type: IsarType.long,
    ),
    r'primarySource': PropertySchema(
      id: 10,
      name: r'primarySource',
      type: IsarType.string,
    ),
    r'recentRemarks': PropertySchema(
      id: 11,
      name: r'recentRemarks',
      type: IsarType.stringList,
    ),
    r'tagKeys': PropertySchema(
      id: 12,
      name: r'tagKeys',
      type: IsarType.stringList,
    ),
    r'topCategoryKey': PropertySchema(
      id: 13,
      name: r'topCategoryKey',
      type: IsarType.string,
    ),
    r'topSubCategoryKey': PropertySchema(
      id: 14,
      name: r'topSubCategoryKey',
      type: IsarType.string,
    ),
    r'transactionCount': PropertySchema(
      id: 15,
      name: r'transactionCount',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 16,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveMerchantMemoryEstimateSize,
  serialize: _jiveMerchantMemorySerialize,
  deserialize: _jiveMerchantMemoryDeserialize,
  deserializeProp: _jiveMerchantMemoryDeserializeProp,
  idName: r'id',
  indexes: {
    r'normalizedName': IndexSchema(
      id: -9115371092206571671,
      name: r'normalizedName',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'normalizedName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveMerchantMemoryGetId,
  getLinks: _jiveMerchantMemoryGetLinks,
  attach: _jiveMerchantMemoryAttach,
  version: '3.1.0+1',
);

int _jiveMerchantMemoryEstimateSize(
  JiveMerchantMemory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accountFrequencyJson.length * 3;
  bytesCount += 3 + object.aliases.length * 3;
  {
    for (var i = 0; i < object.aliases.length; i++) {
      final value = object.aliases[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.categoryFrequencyJson.length * 3;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.normalizedName.length * 3;
  {
    final value = object.primarySource;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.recentRemarks.length * 3;
  {
    for (var i = 0; i < object.recentRemarks.length; i++) {
      final value = object.recentRemarks[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.tagKeys.length * 3;
  {
    for (var i = 0; i < object.tagKeys.length; i++) {
      final value = object.tagKeys[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.topCategoryKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.topSubCategoryKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _jiveMerchantMemorySerialize(
  JiveMerchantMemory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accountFrequencyJson);
  writer.writeStringList(offsets[1], object.aliases);
  writer.writeDouble(offsets[2], object.averageAmount);
  writer.writeString(offsets[3], object.categoryFrequencyJson);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.displayName);
  writer.writeBool(offsets[6], object.isUserConfirmed);
  writer.writeDateTime(offsets[7], object.lastTransactionAt);
  writer.writeString(offsets[8], object.normalizedName);
  writer.writeLong(offsets[9], object.preferredAccountId);
  writer.writeString(offsets[10], object.primarySource);
  writer.writeStringList(offsets[11], object.recentRemarks);
  writer.writeStringList(offsets[12], object.tagKeys);
  writer.writeString(offsets[13], object.topCategoryKey);
  writer.writeString(offsets[14], object.topSubCategoryKey);
  writer.writeLong(offsets[15], object.transactionCount);
  writer.writeDateTime(offsets[16], object.updatedAt);
}

JiveMerchantMemory _jiveMerchantMemoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveMerchantMemory();
  object.accountFrequencyJson = reader.readString(offsets[0]);
  object.aliases = reader.readStringList(offsets[1]) ?? [];
  object.averageAmount = reader.readDouble(offsets[2]);
  object.categoryFrequencyJson = reader.readString(offsets[3]);
  object.createdAt = reader.readDateTime(offsets[4]);
  object.displayName = reader.readString(offsets[5]);
  object.id = id;
  object.isUserConfirmed = reader.readBool(offsets[6]);
  object.lastTransactionAt = reader.readDateTimeOrNull(offsets[7]);
  object.normalizedName = reader.readString(offsets[8]);
  object.preferredAccountId = reader.readLongOrNull(offsets[9]);
  object.primarySource = reader.readStringOrNull(offsets[10]);
  object.recentRemarks = reader.readStringList(offsets[11]) ?? [];
  object.tagKeys = reader.readStringList(offsets[12]) ?? [];
  object.topCategoryKey = reader.readStringOrNull(offsets[13]);
  object.topSubCategoryKey = reader.readStringOrNull(offsets[14]);
  object.transactionCount = reader.readLong(offsets[15]);
  object.updatedAt = reader.readDateTime(offsets[16]);
  return object;
}

P _jiveMerchantMemoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringList(offset) ?? []) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveMerchantMemoryGetId(JiveMerchantMemory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveMerchantMemoryGetLinks(
    JiveMerchantMemory object) {
  return [];
}

void _jiveMerchantMemoryAttach(
    IsarCollection<dynamic> col, Id id, JiveMerchantMemory object) {
  object.id = id;
}

extension JiveMerchantMemoryByIndex on IsarCollection<JiveMerchantMemory> {
  Future<JiveMerchantMemory?> getByNormalizedName(String normalizedName) {
    return getByIndex(r'normalizedName', [normalizedName]);
  }

  JiveMerchantMemory? getByNormalizedNameSync(String normalizedName) {
    return getByIndexSync(r'normalizedName', [normalizedName]);
  }

  Future<bool> deleteByNormalizedName(String normalizedName) {
    return deleteByIndex(r'normalizedName', [normalizedName]);
  }

  bool deleteByNormalizedNameSync(String normalizedName) {
    return deleteByIndexSync(r'normalizedName', [normalizedName]);
  }

  Future<List<JiveMerchantMemory?>> getAllByNormalizedName(
      List<String> normalizedNameValues) {
    final values = normalizedNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'normalizedName', values);
  }

  List<JiveMerchantMemory?> getAllByNormalizedNameSync(
      List<String> normalizedNameValues) {
    final values = normalizedNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'normalizedName', values);
  }

  Future<int> deleteAllByNormalizedName(List<String> normalizedNameValues) {
    final values = normalizedNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'normalizedName', values);
  }

  int deleteAllByNormalizedNameSync(List<String> normalizedNameValues) {
    final values = normalizedNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'normalizedName', values);
  }

  Future<Id> putByNormalizedName(JiveMerchantMemory object) {
    return putByIndex(r'normalizedName', object);
  }

  Id putByNormalizedNameSync(JiveMerchantMemory object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'normalizedName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNormalizedName(List<JiveMerchantMemory> objects) {
    return putAllByIndex(r'normalizedName', objects);
  }

  List<Id> putAllByNormalizedNameSync(List<JiveMerchantMemory> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'normalizedName', objects, saveLinks: saveLinks);
  }
}

extension JiveMerchantMemoryQueryWhereSort
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QWhere> {
  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveMerchantMemoryQueryWhere
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QWhereClause> {
  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterWhereClause>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterWhereClause>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterWhereClause>
      normalizedNameEqualTo(String normalizedName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'normalizedName',
        value: [normalizedName],
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterWhereClause>
      normalizedNameNotEqualTo(String normalizedName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedName',
              lower: [],
              upper: [normalizedName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedName',
              lower: [normalizedName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedName',
              lower: [normalizedName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'normalizedName',
              lower: [],
              upper: [normalizedName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveMerchantMemoryQueryFilter
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QFilterCondition> {
  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accountFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accountFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accountFrequencyJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accountFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accountFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accountFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accountFrequencyJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountFrequencyJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      accountFrequencyJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accountFrequencyJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aliases',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aliases',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aliases',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aliases',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      aliasesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      averageAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'averageAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      averageAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'averageAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      averageAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'averageAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      averageAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'averageAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryFrequencyJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryFrequencyJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryFrequencyJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryFrequencyJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      categoryFrequencyJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryFrequencyJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      isUserConfirmedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUserConfirmed',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      lastTransactionAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastTransactionAt',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      lastTransactionAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastTransactionAt',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      lastTransactionAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastTransactionAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      lastTransactionAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastTransactionAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      lastTransactionAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastTransactionAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      lastTransactionAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastTransactionAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'normalizedName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'normalizedName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'normalizedName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      normalizedNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'normalizedName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      preferredAccountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'preferredAccountId',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      preferredAccountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'preferredAccountId',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      preferredAccountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      preferredAccountIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preferredAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      preferredAccountIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preferredAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      preferredAccountIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preferredAccountId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'primarySource',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'primarySource',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'primarySource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'primarySource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'primarySource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'primarySource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'primarySource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'primarySource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'primarySource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'primarySource',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'primarySource',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      primarySourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'primarySource',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recentRemarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recentRemarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recentRemarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recentRemarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recentRemarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recentRemarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recentRemarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recentRemarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recentRemarks',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recentRemarks',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recentRemarks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recentRemarks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recentRemarks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recentRemarks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recentRemarks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      recentRemarksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recentRemarks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      tagKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      tagKeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagKeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      tagKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      tagKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topCategoryKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topCategoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topCategoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topSubCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topSubCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topSubCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topSubCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topSubCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topSubCategoryKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topSubCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topSubCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topSubCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topSubCategoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topSubCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      topSubCategoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topSubCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      transactionCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      transactionCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      transactionCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      transactionCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transactionCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterFilterCondition>
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

extension JiveMerchantMemoryQueryObject
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QFilterCondition> {}

extension JiveMerchantMemoryQueryLinks
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QFilterCondition> {}

extension JiveMerchantMemoryQuerySortBy
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QSortBy> {
  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByAccountFrequencyJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountFrequencyJson', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByAccountFrequencyJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountFrequencyJson', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByAverageAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByAverageAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByCategoryFrequencyJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryFrequencyJson', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByCategoryFrequencyJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryFrequencyJson', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByIsUserConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUserConfirmed', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByIsUserConfirmedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUserConfirmed', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByLastTransactionAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTransactionAt', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByLastTransactionAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTransactionAt', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByNormalizedName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedName', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByNormalizedNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedName', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByPreferredAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByPreferredAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByPrimarySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySource', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByPrimarySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySource', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByTopCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByTopCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByTopSubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topSubCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByTopSubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topSubCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionCount', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByTransactionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionCount', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveMerchantMemoryQuerySortThenBy
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QSortThenBy> {
  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByAccountFrequencyJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountFrequencyJson', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByAccountFrequencyJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountFrequencyJson', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByAverageAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByAverageAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByCategoryFrequencyJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryFrequencyJson', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByCategoryFrequencyJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryFrequencyJson', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByIsUserConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUserConfirmed', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByIsUserConfirmedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUserConfirmed', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByLastTransactionAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTransactionAt', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByLastTransactionAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTransactionAt', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByNormalizedName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedName', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByNormalizedNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedName', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByPreferredAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByPreferredAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByPrimarySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySource', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByPrimarySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySource', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByTopCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByTopCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByTopSubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topSubCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByTopSubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topSubCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionCount', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByTransactionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionCount', Sort.desc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveMerchantMemoryQueryWhereDistinct
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct> {
  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByAccountFrequencyJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountFrequencyJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByAliases() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aliases');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByAverageAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'averageAmount');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByCategoryFrequencyJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryFrequencyJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByIsUserConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUserConfirmed');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByLastTransactionAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastTransactionAt');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByNormalizedName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'normalizedName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByPreferredAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferredAccountId');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByPrimarySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'primarySource',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByRecentRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recentRemarks');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByTagKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagKeys');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByTopCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topCategoryKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByTopSubCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topSubCategoryKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionCount');
    });
  }

  QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveMerchantMemoryQueryProperty
    on QueryBuilder<JiveMerchantMemory, JiveMerchantMemory, QQueryProperty> {
  QueryBuilder<JiveMerchantMemory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveMerchantMemory, String, QQueryOperations>
      accountFrequencyJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountFrequencyJson');
    });
  }

  QueryBuilder<JiveMerchantMemory, List<String>, QQueryOperations>
      aliasesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aliases');
    });
  }

  QueryBuilder<JiveMerchantMemory, double, QQueryOperations>
      averageAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'averageAmount');
    });
  }

  QueryBuilder<JiveMerchantMemory, String, QQueryOperations>
      categoryFrequencyJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryFrequencyJson');
    });
  }

  QueryBuilder<JiveMerchantMemory, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveMerchantMemory, String, QQueryOperations>
      displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<JiveMerchantMemory, bool, QQueryOperations>
      isUserConfirmedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUserConfirmed');
    });
  }

  QueryBuilder<JiveMerchantMemory, DateTime?, QQueryOperations>
      lastTransactionAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastTransactionAt');
    });
  }

  QueryBuilder<JiveMerchantMemory, String, QQueryOperations>
      normalizedNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'normalizedName');
    });
  }

  QueryBuilder<JiveMerchantMemory, int?, QQueryOperations>
      preferredAccountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredAccountId');
    });
  }

  QueryBuilder<JiveMerchantMemory, String?, QQueryOperations>
      primarySourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primarySource');
    });
  }

  QueryBuilder<JiveMerchantMemory, List<String>, QQueryOperations>
      recentRemarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recentRemarks');
    });
  }

  QueryBuilder<JiveMerchantMemory, List<String>, QQueryOperations>
      tagKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagKeys');
    });
  }

  QueryBuilder<JiveMerchantMemory, String?, QQueryOperations>
      topCategoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topCategoryKey');
    });
  }

  QueryBuilder<JiveMerchantMemory, String?, QQueryOperations>
      topSubCategoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topSubCategoryKey');
    });
  }

  QueryBuilder<JiveMerchantMemory, int, QQueryOperations>
      transactionCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionCount');
    });
  }

  QueryBuilder<JiveMerchantMemory, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
