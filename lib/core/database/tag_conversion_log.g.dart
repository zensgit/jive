// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_conversion_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveTagConversionLogCollection on Isar {
  IsarCollection<JiveTagConversionLog> get jiveTagConversionLogs =>
      this.collection();
}

const JiveTagConversionLogSchema = CollectionSchema(
  name: r'JiveTagConversionLog',
  id: 1262958447738809843,
  properties: {
    r'categoryIsIncome': PropertySchema(
      id: 0,
      name: r'categoryIsIncome',
      type: IsarType.bool,
    ),
    r'categoryKey': PropertySchema(
      id: 1,
      name: r'categoryKey',
      type: IsarType.string,
    ),
    r'categoryName': PropertySchema(
      id: 2,
      name: r'categoryName',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'keepTagActive': PropertySchema(
      id: 4,
      name: r'keepTagActive',
      type: IsarType.bool,
    ),
    r'migratePolicy': PropertySchema(
      id: 5,
      name: r'migratePolicy',
      type: IsarType.string,
    ),
    r'parentCategoryKey': PropertySchema(
      id: 6,
      name: r'parentCategoryKey',
      type: IsarType.string,
    ),
    r'parentCategoryName': PropertySchema(
      id: 7,
      name: r'parentCategoryName',
      type: IsarType.string,
    ),
    r'skippedByPolicyCount': PropertySchema(
      id: 8,
      name: r'skippedByPolicyCount',
      type: IsarType.long,
    ),
    r'skippedExistingCategoryCount': PropertySchema(
      id: 9,
      name: r'skippedExistingCategoryCount',
      type: IsarType.long,
    ),
    r'skippedTypeMismatchCount': PropertySchema(
      id: 10,
      name: r'skippedTypeMismatchCount',
      type: IsarType.long,
    ),
    r'skippedUnknownCategoryCount': PropertySchema(
      id: 11,
      name: r'skippedUnknownCategoryCount',
      type: IsarType.long,
    ),
    r'tagKey': PropertySchema(
      id: 12,
      name: r'tagKey',
      type: IsarType.string,
    ),
    r'tagName': PropertySchema(
      id: 13,
      name: r'tagName',
      type: IsarType.string,
    ),
    r'taggedTransactionCount': PropertySchema(
      id: 14,
      name: r'taggedTransactionCount',
      type: IsarType.long,
    ),
    r'updatedTransactionCount': PropertySchema(
      id: 15,
      name: r'updatedTransactionCount',
      type: IsarType.long,
    ),
    r'updatedTransactionIds': PropertySchema(
      id: 16,
      name: r'updatedTransactionIds',
      type: IsarType.longList,
    )
  },
  estimateSize: _jiveTagConversionLogEstimateSize,
  serialize: _jiveTagConversionLogSerialize,
  deserialize: _jiveTagConversionLogDeserialize,
  deserializeProp: _jiveTagConversionLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'tagKey': IndexSchema(
      id: 6702134639713379914,
      name: r'tagKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tagKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'categoryKey': IndexSchema(
      id: -1260834391558899289,
      name: r'categoryKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'categoryKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveTagConversionLogGetId,
  getLinks: _jiveTagConversionLogGetLinks,
  attach: _jiveTagConversionLogAttach,
  version: '3.1.0+1',
);

int _jiveTagConversionLogEstimateSize(
  JiveTagConversionLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.categoryKey.length * 3;
  bytesCount += 3 + object.categoryName.length * 3;
  bytesCount += 3 + object.migratePolicy.length * 3;
  {
    final value = object.parentCategoryKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.parentCategoryName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tagKey.length * 3;
  bytesCount += 3 + object.tagName.length * 3;
  bytesCount += 3 + object.updatedTransactionIds.length * 8;
  return bytesCount;
}

void _jiveTagConversionLogSerialize(
  JiveTagConversionLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.categoryIsIncome);
  writer.writeString(offsets[1], object.categoryKey);
  writer.writeString(offsets[2], object.categoryName);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeBool(offsets[4], object.keepTagActive);
  writer.writeString(offsets[5], object.migratePolicy);
  writer.writeString(offsets[6], object.parentCategoryKey);
  writer.writeString(offsets[7], object.parentCategoryName);
  writer.writeLong(offsets[8], object.skippedByPolicyCount);
  writer.writeLong(offsets[9], object.skippedExistingCategoryCount);
  writer.writeLong(offsets[10], object.skippedTypeMismatchCount);
  writer.writeLong(offsets[11], object.skippedUnknownCategoryCount);
  writer.writeString(offsets[12], object.tagKey);
  writer.writeString(offsets[13], object.tagName);
  writer.writeLong(offsets[14], object.taggedTransactionCount);
  writer.writeLong(offsets[15], object.updatedTransactionCount);
  writer.writeLongList(offsets[16], object.updatedTransactionIds);
}

JiveTagConversionLog _jiveTagConversionLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveTagConversionLog();
  object.categoryIsIncome = reader.readBool(offsets[0]);
  object.categoryKey = reader.readString(offsets[1]);
  object.categoryName = reader.readString(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.id = id;
  object.keepTagActive = reader.readBool(offsets[4]);
  object.migratePolicy = reader.readString(offsets[5]);
  object.parentCategoryKey = reader.readStringOrNull(offsets[6]);
  object.parentCategoryName = reader.readStringOrNull(offsets[7]);
  object.skippedByPolicyCount = reader.readLong(offsets[8]);
  object.skippedExistingCategoryCount = reader.readLong(offsets[9]);
  object.skippedTypeMismatchCount = reader.readLong(offsets[10]);
  object.skippedUnknownCategoryCount = reader.readLong(offsets[11]);
  object.tagKey = reader.readString(offsets[12]);
  object.tagName = reader.readString(offsets[13]);
  object.taggedTransactionCount = reader.readLong(offsets[14]);
  object.updatedTransactionCount = reader.readLong(offsets[15]);
  object.updatedTransactionIds = reader.readLongList(offsets[16]) ?? [];
  return object;
}

P _jiveTagConversionLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readLongList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveTagConversionLogGetId(JiveTagConversionLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveTagConversionLogGetLinks(
    JiveTagConversionLog object) {
  return [];
}

void _jiveTagConversionLogAttach(
    IsarCollection<dynamic> col, Id id, JiveTagConversionLog object) {
  object.id = id;
}

extension JiveTagConversionLogQueryWhereSort
    on QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QWhere> {
  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveTagConversionLogQueryWhere
    on QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QWhereClause> {
  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
      tagKeyEqualTo(String tagKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'tagKey',
        value: [tagKey],
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
      tagKeyNotEqualTo(String tagKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tagKey',
              lower: [],
              upper: [tagKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tagKey',
              lower: [tagKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tagKey',
              lower: [tagKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tagKey',
              lower: [],
              upper: [tagKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
      categoryKeyEqualTo(String categoryKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'categoryKey',
        value: [categoryKey],
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterWhereClause>
      categoryKeyNotEqualTo(String categoryKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoryKey',
              lower: [],
              upper: [categoryKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoryKey',
              lower: [categoryKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoryKey',
              lower: [categoryKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoryKey',
              lower: [],
              upper: [categoryKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveTagConversionLogQueryFilter on QueryBuilder<JiveTagConversionLog,
    JiveTagConversionLog, QFilterCondition> {
  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryIsIncomeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryIsIncome',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryKeyEqualTo(
    String value, {
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryKeyGreaterThan(
    String value, {
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryKeyLessThan(
    String value, {
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryKeyBetween(
    String lower,
    String upper, {
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryKeyStartsWith(
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryKeyEndsWith(
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      categoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      categoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryNameEqualTo(
    String value, {
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryNameGreaterThan(
    String value, {
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryNameLessThan(
    String value, {
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryNameBetween(
    String lower,
    String upper, {
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryNameStartsWith(
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryNameEndsWith(
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      categoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      categoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> categoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
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

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> keepTagActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keepTagActive',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> migratePolicyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'migratePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> migratePolicyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'migratePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> migratePolicyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'migratePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> migratePolicyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'migratePolicy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> migratePolicyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'migratePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> migratePolicyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'migratePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      migratePolicyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'migratePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      migratePolicyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'migratePolicy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> migratePolicyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'migratePolicy',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> migratePolicyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'migratePolicy',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentCategoryKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parentCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parentCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      parentCategoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parentCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      parentCategoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parentCategoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parentCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentCategoryName',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentCategoryName',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentCategoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parentCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parentCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      parentCategoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parentCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      parentCategoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parentCategoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentCategoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> parentCategoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parentCategoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedByPolicyCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skippedByPolicyCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedByPolicyCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skippedByPolicyCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedByPolicyCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skippedByPolicyCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedByPolicyCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skippedByPolicyCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedExistingCategoryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skippedExistingCategoryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedExistingCategoryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skippedExistingCategoryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedExistingCategoryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skippedExistingCategoryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedExistingCategoryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skippedExistingCategoryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedTypeMismatchCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skippedTypeMismatchCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedTypeMismatchCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skippedTypeMismatchCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedTypeMismatchCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skippedTypeMismatchCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedTypeMismatchCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skippedTypeMismatchCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedUnknownCategoryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skippedUnknownCategoryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedUnknownCategoryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skippedUnknownCategoryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedUnknownCategoryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skippedUnknownCategoryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> skippedUnknownCategoryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skippedUnknownCategoryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tagKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      tagKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      tagKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tagName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tagName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tagName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tagName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tagName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      tagNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
          QAfterFilterCondition>
      tagNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> tagNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> taggedTransactionCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taggedTransactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> taggedTransactionCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taggedTransactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> taggedTransactionCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taggedTransactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> taggedTransactionCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taggedTransactionCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedTransactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedTransactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedTransactionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedTransactionCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedTransactionIds',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedTransactionIds',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedTransactionIds',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedTransactionIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'updatedTransactionIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'updatedTransactionIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'updatedTransactionIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'updatedTransactionIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'updatedTransactionIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog,
      QAfterFilterCondition> updatedTransactionIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'updatedTransactionIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension JiveTagConversionLogQueryObject on QueryBuilder<JiveTagConversionLog,
    JiveTagConversionLog, QFilterCondition> {}

extension JiveTagConversionLogQueryLinks on QueryBuilder<JiveTagConversionLog,
    JiveTagConversionLog, QFilterCondition> {}

extension JiveTagConversionLogQuerySortBy
    on QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QSortBy> {
  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByCategoryIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryIsIncome', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByCategoryIsIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryIsIncome', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByKeepTagActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keepTagActive', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByKeepTagActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keepTagActive', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByMigratePolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'migratePolicy', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByMigratePolicyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'migratePolicy', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByParentCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByParentCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByParentCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCategoryName', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByParentCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCategoryName', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortBySkippedByPolicyCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedByPolicyCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortBySkippedByPolicyCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedByPolicyCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortBySkippedExistingCategoryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedExistingCategoryCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortBySkippedExistingCategoryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedExistingCategoryCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortBySkippedTypeMismatchCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedTypeMismatchCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortBySkippedTypeMismatchCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedTypeMismatchCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortBySkippedUnknownCategoryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedUnknownCategoryCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortBySkippedUnknownCategoryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedUnknownCategoryCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByTagKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByTagKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByTagName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagName', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByTagNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagName', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByTaggedTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taggedTransactionCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByTaggedTransactionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taggedTransactionCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByUpdatedTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedTransactionCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      sortByUpdatedTransactionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedTransactionCount', Sort.desc);
    });
  }
}

extension JiveTagConversionLogQuerySortThenBy
    on QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QSortThenBy> {
  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByCategoryIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryIsIncome', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByCategoryIsIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryIsIncome', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByKeepTagActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keepTagActive', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByKeepTagActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keepTagActive', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByMigratePolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'migratePolicy', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByMigratePolicyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'migratePolicy', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByParentCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByParentCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByParentCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCategoryName', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByParentCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCategoryName', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenBySkippedByPolicyCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedByPolicyCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenBySkippedByPolicyCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedByPolicyCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenBySkippedExistingCategoryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedExistingCategoryCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenBySkippedExistingCategoryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedExistingCategoryCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenBySkippedTypeMismatchCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedTypeMismatchCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenBySkippedTypeMismatchCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedTypeMismatchCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenBySkippedUnknownCategoryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedUnknownCategoryCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenBySkippedUnknownCategoryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedUnknownCategoryCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByTagKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByTagKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByTagName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagName', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByTagNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagName', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByTaggedTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taggedTransactionCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByTaggedTransactionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taggedTransactionCount', Sort.desc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByUpdatedTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedTransactionCount', Sort.asc);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QAfterSortBy>
      thenByUpdatedTransactionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedTransactionCount', Sort.desc);
    });
  }
}

extension JiveTagConversionLogQueryWhereDistinct
    on QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct> {
  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByCategoryIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryIsIncome');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByCategoryName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByKeepTagActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keepTagActive');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByMigratePolicy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'migratePolicy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByParentCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentCategoryKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByParentCategoryName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentCategoryName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctBySkippedByPolicyCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skippedByPolicyCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctBySkippedExistingCategoryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skippedExistingCategoryCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctBySkippedTypeMismatchCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skippedTypeMismatchCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctBySkippedUnknownCategoryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skippedUnknownCategoryCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByTagKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByTagName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByTaggedTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taggedTransactionCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByUpdatedTransactionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedTransactionCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, JiveTagConversionLog, QDistinct>
      distinctByUpdatedTransactionIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedTransactionIds');
    });
  }
}

extension JiveTagConversionLogQueryProperty on QueryBuilder<
    JiveTagConversionLog, JiveTagConversionLog, QQueryProperty> {
  QueryBuilder<JiveTagConversionLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveTagConversionLog, bool, QQueryOperations>
      categoryIsIncomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryIsIncome');
    });
  }

  QueryBuilder<JiveTagConversionLog, String, QQueryOperations>
      categoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryKey');
    });
  }

  QueryBuilder<JiveTagConversionLog, String, QQueryOperations>
      categoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryName');
    });
  }

  QueryBuilder<JiveTagConversionLog, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveTagConversionLog, bool, QQueryOperations>
      keepTagActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keepTagActive');
    });
  }

  QueryBuilder<JiveTagConversionLog, String, QQueryOperations>
      migratePolicyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'migratePolicy');
    });
  }

  QueryBuilder<JiveTagConversionLog, String?, QQueryOperations>
      parentCategoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentCategoryKey');
    });
  }

  QueryBuilder<JiveTagConversionLog, String?, QQueryOperations>
      parentCategoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentCategoryName');
    });
  }

  QueryBuilder<JiveTagConversionLog, int, QQueryOperations>
      skippedByPolicyCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skippedByPolicyCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, int, QQueryOperations>
      skippedExistingCategoryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skippedExistingCategoryCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, int, QQueryOperations>
      skippedTypeMismatchCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skippedTypeMismatchCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, int, QQueryOperations>
      skippedUnknownCategoryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skippedUnknownCategoryCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, String, QQueryOperations>
      tagKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagKey');
    });
  }

  QueryBuilder<JiveTagConversionLog, String, QQueryOperations>
      tagNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagName');
    });
  }

  QueryBuilder<JiveTagConversionLog, int, QQueryOperations>
      taggedTransactionCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taggedTransactionCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, int, QQueryOperations>
      updatedTransactionCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedTransactionCount');
    });
  }

  QueryBuilder<JiveTagConversionLog, List<int>, QQueryOperations>
      updatedTransactionIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedTransactionIds');
    });
  }
}
