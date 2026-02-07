// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_draft_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveAutoDraftCollection on Isar {
  IsarCollection<JiveAutoDraft> get jiveAutoDrafts => this.collection();
}

const JiveAutoDraftSchema = CollectionSchema(
  name: r'JiveAutoDraft',
  id: -138213615113772295,
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
    r'category': PropertySchema(
      id: 2,
      name: r'category',
      type: IsarType.string,
    ),
    r'categoryKey': PropertySchema(
      id: 3,
      name: r'categoryKey',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dedupKey': PropertySchema(
      id: 5,
      name: r'dedupKey',
      type: IsarType.string,
    ),
    r'metadataJson': PropertySchema(
      id: 6,
      name: r'metadataJson',
      type: IsarType.string,
    ),
    r'rawText': PropertySchema(
      id: 7,
      name: r'rawText',
      type: IsarType.string,
    ),
    r'recurringKey': PropertySchema(
      id: 8,
      name: r'recurringKey',
      type: IsarType.string,
    ),
    r'recurringRuleId': PropertySchema(
      id: 9,
      name: r'recurringRuleId',
      type: IsarType.long,
    ),
    r'source': PropertySchema(
      id: 10,
      name: r'source',
      type: IsarType.string,
    ),
    r'subCategory': PropertySchema(
      id: 11,
      name: r'subCategory',
      type: IsarType.string,
    ),
    r'subCategoryKey': PropertySchema(
      id: 12,
      name: r'subCategoryKey',
      type: IsarType.string,
    ),
    r'tagKeys': PropertySchema(
      id: 13,
      name: r'tagKeys',
      type: IsarType.stringList,
    ),
    r'timestamp': PropertySchema(
      id: 14,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'toAccountId': PropertySchema(
      id: 15,
      name: r'toAccountId',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 16,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _jiveAutoDraftEstimateSize,
  serialize: _jiveAutoDraftSerialize,
  deserialize: _jiveAutoDraftDeserialize,
  deserializeProp: _jiveAutoDraftDeserializeProp,
  idName: r'id',
  indexes: {
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
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
    ),
    r'subCategoryKey': IndexSchema(
      id: -3691976471568379551,
      name: r'subCategoryKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'subCategoryKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'dedupKey': IndexSchema(
      id: 2124236096506660101,
      name: r'dedupKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dedupKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'recurringRuleId': IndexSchema(
      id: 7860537796394788863,
      name: r'recurringRuleId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'recurringRuleId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'recurringKey': IndexSchema(
      id: 1211987308107365496,
      name: r'recurringKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'recurringKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveAutoDraftGetId,
  getLinks: _jiveAutoDraftGetLinks,
  attach: _jiveAutoDraftAttach,
  version: '3.1.0+1',
);

int _jiveAutoDraftEstimateSize(
  JiveAutoDraft object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.categoryKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dedupKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadataJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.rawText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recurringKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.source.length * 3;
  {
    final value = object.subCategory;
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
  bytesCount += 3 + object.tagKeys.length * 3;
  {
    for (var i = 0; i < object.tagKeys.length; i++) {
      final value = object.tagKeys[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _jiveAutoDraftSerialize(
  JiveAutoDraft object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeString(offsets[2], object.category);
  writer.writeString(offsets[3], object.categoryKey);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.dedupKey);
  writer.writeString(offsets[6], object.metadataJson);
  writer.writeString(offsets[7], object.rawText);
  writer.writeString(offsets[8], object.recurringKey);
  writer.writeLong(offsets[9], object.recurringRuleId);
  writer.writeString(offsets[10], object.source);
  writer.writeString(offsets[11], object.subCategory);
  writer.writeString(offsets[12], object.subCategoryKey);
  writer.writeStringList(offsets[13], object.tagKeys);
  writer.writeDateTime(offsets[14], object.timestamp);
  writer.writeLong(offsets[15], object.toAccountId);
  writer.writeString(offsets[16], object.type);
}

JiveAutoDraft _jiveAutoDraftDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveAutoDraft();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.amount = reader.readDouble(offsets[1]);
  object.category = reader.readStringOrNull(offsets[2]);
  object.categoryKey = reader.readStringOrNull(offsets[3]);
  object.createdAt = reader.readDateTime(offsets[4]);
  object.dedupKey = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.metadataJson = reader.readStringOrNull(offsets[6]);
  object.rawText = reader.readStringOrNull(offsets[7]);
  object.recurringKey = reader.readStringOrNull(offsets[8]);
  object.recurringRuleId = reader.readLongOrNull(offsets[9]);
  object.source = reader.readString(offsets[10]);
  object.subCategory = reader.readStringOrNull(offsets[11]);
  object.subCategoryKey = reader.readStringOrNull(offsets[12]);
  object.tagKeys = reader.readStringList(offsets[13]) ?? [];
  object.timestamp = reader.readDateTime(offsets[14]);
  object.toAccountId = reader.readLongOrNull(offsets[15]);
  object.type = reader.readStringOrNull(offsets[16]);
  return object;
}

P _jiveAutoDraftDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringList(offset) ?? []) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveAutoDraftGetId(JiveAutoDraft object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveAutoDraftGetLinks(JiveAutoDraft object) {
  return [];
}

void _jiveAutoDraftAttach(
    IsarCollection<dynamic> col, Id id, JiveAutoDraft object) {
  object.id = id;
}

extension JiveAutoDraftQueryWhereSort
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QWhere> {
  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhere> anyRecurringRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'recurringRuleId'),
      );
    });
  }
}

extension JiveAutoDraftQueryWhere
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QWhereClause> {
  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      categoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'categoryKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      categoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'categoryKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      categoryKeyEqualTo(String? categoryKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'categoryKey',
        value: [categoryKey],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      categoryKeyNotEqualTo(String? categoryKey) {
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      subCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'subCategoryKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      subCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'subCategoryKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      subCategoryKeyEqualTo(String? subCategoryKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'subCategoryKey',
        value: [subCategoryKey],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      subCategoryKeyNotEqualTo(String? subCategoryKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subCategoryKey',
              lower: [],
              upper: [subCategoryKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subCategoryKey',
              lower: [subCategoryKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subCategoryKey',
              lower: [subCategoryKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subCategoryKey',
              lower: [],
              upper: [subCategoryKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      dedupKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dedupKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      dedupKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dedupKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause> dedupKeyEqualTo(
      String? dedupKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dedupKey',
        value: [dedupKey],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      dedupKeyNotEqualTo(String? dedupKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dedupKey',
              lower: [],
              upper: [dedupKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dedupKey',
              lower: [dedupKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dedupKey',
              lower: [dedupKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dedupKey',
              lower: [],
              upper: [dedupKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringRuleIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'recurringRuleId',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringRuleIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recurringRuleId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringRuleIdEqualTo(int? recurringRuleId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'recurringRuleId',
        value: [recurringRuleId],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringRuleIdNotEqualTo(int? recurringRuleId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recurringRuleId',
              lower: [],
              upper: [recurringRuleId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recurringRuleId',
              lower: [recurringRuleId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recurringRuleId',
              lower: [recurringRuleId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recurringRuleId',
              lower: [],
              upper: [recurringRuleId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringRuleIdGreaterThan(
    int? recurringRuleId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recurringRuleId',
        lower: [recurringRuleId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringRuleIdLessThan(
    int? recurringRuleId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recurringRuleId',
        lower: [],
        upper: [recurringRuleId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringRuleIdBetween(
    int? lowerRecurringRuleId,
    int? upperRecurringRuleId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recurringRuleId',
        lower: [lowerRecurringRuleId],
        includeLower: includeLower,
        upper: [upperRecurringRuleId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'recurringKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recurringKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringKeyEqualTo(String? recurringKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'recurringKey',
        value: [recurringKey],
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterWhereClause>
      recurringKeyNotEqualTo(String? recurringKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recurringKey',
              lower: [],
              upper: [recurringKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recurringKey',
              lower: [recurringKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recurringKey',
              lower: [recurringKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recurringKey',
              lower: [],
              upper: [recurringKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveAutoDraftQueryFilter
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QFilterCondition> {
  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      accountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryKey',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryKey',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      categoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dedupKey',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dedupKey',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dedupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dedupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dedupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dedupKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dedupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dedupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dedupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dedupKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dedupKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      dedupKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dedupKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition> idBetween(
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'metadataJson',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'metadataJson',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'metadataJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'metadataJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      metadataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'metadataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rawText',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rawText',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rawText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rawText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rawText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rawText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rawText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rawText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rawText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawText',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      rawTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rawText',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recurringKey',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recurringKey',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurringKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recurringKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recurringKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recurringKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recurringKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recurringKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recurringKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recurringKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurringKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recurringKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringRuleIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recurringRuleId',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringRuleIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recurringRuleId',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringRuleIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurringRuleId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringRuleIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recurringRuleId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringRuleIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recurringRuleId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      recurringRuleIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recurringRuleId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subCategory',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subCategory',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subCategory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subCategory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subCategoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      subCategoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      tagKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      tagKeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagKeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      tagKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      tagKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      toAccountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'toAccountId',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      toAccountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'toAccountId',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      toAccountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition> typeEqualTo(
    String? value, {
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      typeGreaterThan(
    String? value, {
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      typeLessThan(
    String? value, {
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition> typeBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
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

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension JiveAutoDraftQueryObject
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QFilterCondition> {}

extension JiveAutoDraftQueryLinks
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QFilterCondition> {}

extension JiveAutoDraftQuerySortBy
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QSortBy> {
  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByDedupKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dedupKey', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByDedupKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dedupKey', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByMetadataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByMetadataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByRawText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByRawTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByRecurringKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringKey', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByRecurringKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringKey', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByRecurringRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringRuleId', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByRecurringRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringRuleId', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortBySubCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortBySubCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      sortByToAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension JiveAutoDraftQuerySortThenBy
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QSortThenBy> {
  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByDedupKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dedupKey', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByDedupKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dedupKey', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByMetadataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByMetadataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByRawText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByRawTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByRecurringKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringKey', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByRecurringKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringKey', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByRecurringRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringRuleId', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByRecurringRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringRuleId', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenBySubCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenBySubCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy>
      thenByToAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension JiveAutoDraftQueryWhereDistinct
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> {
  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByCategoryKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByDedupKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dedupKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByMetadataJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadataJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByRawText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByRecurringKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurringKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct>
      distinctByRecurringRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurringRuleId');
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctBySubCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCategory', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct>
      distinctBySubCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCategoryKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByTagKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagKeys');
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct>
      distinctByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toAccountId');
    });
  }

  QueryBuilder<JiveAutoDraft, JiveAutoDraft, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension JiveAutoDraftQueryProperty
    on QueryBuilder<JiveAutoDraft, JiveAutoDraft, QQueryProperty> {
  QueryBuilder<JiveAutoDraft, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveAutoDraft, int?, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveAutoDraft, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations> categoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryKey');
    });
  }

  QueryBuilder<JiveAutoDraft, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations> dedupKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dedupKey');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations>
      metadataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataJson');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations> rawTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawText');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations>
      recurringKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurringKey');
    });
  }

  QueryBuilder<JiveAutoDraft, int?, QQueryOperations>
      recurringRuleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurringRuleId');
    });
  }

  QueryBuilder<JiveAutoDraft, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations> subCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategory');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations>
      subCategoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategoryKey');
    });
  }

  QueryBuilder<JiveAutoDraft, List<String>, QQueryOperations>
      tagKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagKeys');
    });
  }

  QueryBuilder<JiveAutoDraft, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<JiveAutoDraft, int?, QQueryOperations> toAccountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toAccountId');
    });
  }

  QueryBuilder<JiveAutoDraft, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
