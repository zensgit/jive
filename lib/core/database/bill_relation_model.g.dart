// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_relation_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveBillRelationCollection on Isar {
  IsarCollection<JiveBillRelation> get jiveBillRelations => this.collection();
}

const JiveBillRelationSchema = CollectionSchema(
  name: r'JiveBillRelation',
  id: 1764364210340548073,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currency': PropertySchema(
      id: 2,
      name: r'currency',
      type: IsarType.string,
    ),
    r'groupKey': PropertySchema(
      id: 3,
      name: r'groupKey',
      type: IsarType.string,
    ),
    r'linkedTransactionId': PropertySchema(
      id: 4,
      name: r'linkedTransactionId',
      type: IsarType.long,
    ),
    r'note': PropertySchema(
      id: 5,
      name: r'note',
      type: IsarType.string,
    ),
    r'relationType': PropertySchema(
      id: 6,
      name: r'relationType',
      type: IsarType.string,
    ),
    r'sourceTransactionId': PropertySchema(
      id: 7,
      name: r'sourceTransactionId',
      type: IsarType.long,
    )
  },
  estimateSize: _jiveBillRelationEstimateSize,
  serialize: _jiveBillRelationSerialize,
  deserialize: _jiveBillRelationDeserialize,
  deserializeProp: _jiveBillRelationDeserializeProp,
  idName: r'id',
  indexes: {
    r'sourceTransactionId': IndexSchema(
      id: 3451458545021410290,
      name: r'sourceTransactionId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sourceTransactionId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'linkedTransactionId': IndexSchema(
      id: 634670711283887622,
      name: r'linkedTransactionId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'linkedTransactionId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'relationType': IndexSchema(
      id: -2445114756645216302,
      name: r'relationType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'relationType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'groupKey': IndexSchema(
      id: -4947244033807428779,
      name: r'groupKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'groupKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveBillRelationGetId,
  getLinks: _jiveBillRelationGetLinks,
  attach: _jiveBillRelationAttach,
  version: '3.1.0+1',
);

int _jiveBillRelationEstimateSize(
  JiveBillRelation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.currency.length * 3;
  {
    final value = object.groupKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.relationType.length * 3;
  return bytesCount;
}

void _jiveBillRelationSerialize(
  JiveBillRelation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.currency);
  writer.writeString(offsets[3], object.groupKey);
  writer.writeLong(offsets[4], object.linkedTransactionId);
  writer.writeString(offsets[5], object.note);
  writer.writeString(offsets[6], object.relationType);
  writer.writeLong(offsets[7], object.sourceTransactionId);
}

JiveBillRelation _jiveBillRelationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveBillRelation();
  object.amount = reader.readDouble(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.currency = reader.readString(offsets[2]);
  object.groupKey = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.linkedTransactionId = reader.readLong(offsets[4]);
  object.note = reader.readStringOrNull(offsets[5]);
  object.relationType = reader.readString(offsets[6]);
  object.sourceTransactionId = reader.readLong(offsets[7]);
  return object;
}

P _jiveBillRelationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveBillRelationGetId(JiveBillRelation object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveBillRelationGetLinks(JiveBillRelation object) {
  return [];
}

void _jiveBillRelationAttach(
    IsarCollection<dynamic> col, Id id, JiveBillRelation object) {
  object.id = id;
}

extension JiveBillRelationQueryWhereSort
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QWhere> {
  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhere>
      anySourceTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'sourceTransactionId'),
      );
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhere>
      anyLinkedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'linkedTransactionId'),
      );
    });
  }
}

extension JiveBillRelationQueryWhere
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QWhereClause> {
  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      sourceTransactionIdEqualTo(int sourceTransactionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sourceTransactionId',
        value: [sourceTransactionId],
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      sourceTransactionIdNotEqualTo(int sourceTransactionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceTransactionId',
              lower: [],
              upper: [sourceTransactionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceTransactionId',
              lower: [sourceTransactionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceTransactionId',
              lower: [sourceTransactionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceTransactionId',
              lower: [],
              upper: [sourceTransactionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      sourceTransactionIdGreaterThan(
    int sourceTransactionId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sourceTransactionId',
        lower: [sourceTransactionId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      sourceTransactionIdLessThan(
    int sourceTransactionId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sourceTransactionId',
        lower: [],
        upper: [sourceTransactionId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      sourceTransactionIdBetween(
    int lowerSourceTransactionId,
    int upperSourceTransactionId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sourceTransactionId',
        lower: [lowerSourceTransactionId],
        includeLower: includeLower,
        upper: [upperSourceTransactionId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      linkedTransactionIdEqualTo(int linkedTransactionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'linkedTransactionId',
        value: [linkedTransactionId],
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      linkedTransactionIdNotEqualTo(int linkedTransactionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'linkedTransactionId',
              lower: [],
              upper: [linkedTransactionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'linkedTransactionId',
              lower: [linkedTransactionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'linkedTransactionId',
              lower: [linkedTransactionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'linkedTransactionId',
              lower: [],
              upper: [linkedTransactionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      linkedTransactionIdGreaterThan(
    int linkedTransactionId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'linkedTransactionId',
        lower: [linkedTransactionId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      linkedTransactionIdLessThan(
    int linkedTransactionId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'linkedTransactionId',
        lower: [],
        upper: [linkedTransactionId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      linkedTransactionIdBetween(
    int lowerLinkedTransactionId,
    int upperLinkedTransactionId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'linkedTransactionId',
        lower: [lowerLinkedTransactionId],
        includeLower: includeLower,
        upper: [upperLinkedTransactionId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      relationTypeEqualTo(String relationType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'relationType',
        value: [relationType],
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      relationTypeNotEqualTo(String relationType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relationType',
              lower: [],
              upper: [relationType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relationType',
              lower: [relationType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relationType',
              lower: [relationType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relationType',
              lower: [],
              upper: [relationType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      groupKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'groupKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      groupKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'groupKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      groupKeyEqualTo(String? groupKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'groupKey',
        value: [groupKey],
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterWhereClause>
      groupKeyNotEqualTo(String? groupKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupKey',
              lower: [],
              upper: [groupKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupKey',
              lower: [groupKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupKey',
              lower: [groupKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupKey',
              lower: [],
              upper: [groupKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveBillRelationQueryFilter
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QFilterCondition> {
  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupKey',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupKey',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      groupKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      linkedTransactionIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      linkedTransactionIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linkedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      linkedTransactionIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linkedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      linkedTransactionIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linkedTransactionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
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

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relationType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relationType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relationType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      relationTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relationType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      sourceTransactionIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      sourceTransactionIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      sourceTransactionIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterFilterCondition>
      sourceTransactionIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceTransactionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveBillRelationQueryObject
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QFilterCondition> {}

extension JiveBillRelationQueryLinks
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QFilterCondition> {}

extension JiveBillRelationQuerySortBy
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QSortBy> {
  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByGroupKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupKey', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByGroupKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupKey', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByLinkedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedTransactionId', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByLinkedTransactionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedTransactionId', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByRelationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationType', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortByRelationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationType', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortBySourceTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceTransactionId', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      sortBySourceTransactionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceTransactionId', Sort.desc);
    });
  }
}

extension JiveBillRelationQuerySortThenBy
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QSortThenBy> {
  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByGroupKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupKey', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByGroupKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupKey', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByLinkedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedTransactionId', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByLinkedTransactionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedTransactionId', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByRelationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationType', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenByRelationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationType', Sort.desc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenBySourceTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceTransactionId', Sort.asc);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QAfterSortBy>
      thenBySourceTransactionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceTransactionId', Sort.desc);
    });
  }
}

extension JiveBillRelationQueryWhereDistinct
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct> {
  QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct>
      distinctByCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct>
      distinctByGroupKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct>
      distinctByLinkedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linkedTransactionId');
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct>
      distinctByRelationType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relationType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveBillRelation, JiveBillRelation, QDistinct>
      distinctBySourceTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceTransactionId');
    });
  }
}

extension JiveBillRelationQueryProperty
    on QueryBuilder<JiveBillRelation, JiveBillRelation, QQueryProperty> {
  QueryBuilder<JiveBillRelation, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveBillRelation, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<JiveBillRelation, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveBillRelation, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<JiveBillRelation, String?, QQueryOperations> groupKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupKey');
    });
  }

  QueryBuilder<JiveBillRelation, int, QQueryOperations>
      linkedTransactionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linkedTransactionId');
    });
  }

  QueryBuilder<JiveBillRelation, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<JiveBillRelation, String, QQueryOperations>
      relationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relationType');
    });
  }

  QueryBuilder<JiveBillRelation, int, QQueryOperations>
      sourceTransactionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceTransactionId');
    });
  }
}
