// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_conflict_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveSyncConflictCollection on Isar {
  IsarCollection<JiveSyncConflict> get jiveSyncConflicts => this.collection();
}

const JiveSyncConflictSchema = CollectionSchema(
  name: r'JiveSyncConflict',
  id: -3924196814430004133,
  properties: {
    r'detectedAt': PropertySchema(
      id: 0,
      name: r'detectedAt',
      type: IsarType.dateTime,
    ),
    r'localId': PropertySchema(
      id: 1,
      name: r'localId',
      type: IsarType.long,
    ),
    r'localJson': PropertySchema(
      id: 2,
      name: r'localJson',
      type: IsarType.string,
    ),
    r'localUpdatedAt': PropertySchema(
      id: 3,
      name: r'localUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'remoteJson': PropertySchema(
      id: 4,
      name: r'remoteJson',
      type: IsarType.string,
    ),
    r'remoteUpdatedAt': PropertySchema(
      id: 5,
      name: r'remoteUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'resolvedAt': PropertySchema(
      id: 6,
      name: r'resolvedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 7,
      name: r'status',
      type: IsarType.string,
    ),
    r'table': PropertySchema(
      id: 8,
      name: r'table',
      type: IsarType.string,
    )
  },
  estimateSize: _jiveSyncConflictEstimateSize,
  serialize: _jiveSyncConflictSerialize,
  deserialize: _jiveSyncConflictDeserialize,
  deserializeProp: _jiveSyncConflictDeserializeProp,
  idName: r'id',
  indexes: {
    r'table': IndexSchema(
      id: 8918027309824820424,
      name: r'table',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'table',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveSyncConflictGetId,
  getLinks: _jiveSyncConflictGetLinks,
  attach: _jiveSyncConflictAttach,
  version: '3.1.0+1',
);

int _jiveSyncConflictEstimateSize(
  JiveSyncConflict object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.localJson.length * 3;
  bytesCount += 3 + object.remoteJson.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.table.length * 3;
  return bytesCount;
}

void _jiveSyncConflictSerialize(
  JiveSyncConflict object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.detectedAt);
  writer.writeLong(offsets[1], object.localId);
  writer.writeString(offsets[2], object.localJson);
  writer.writeDateTime(offsets[3], object.localUpdatedAt);
  writer.writeString(offsets[4], object.remoteJson);
  writer.writeDateTime(offsets[5], object.remoteUpdatedAt);
  writer.writeDateTime(offsets[6], object.resolvedAt);
  writer.writeString(offsets[7], object.status);
  writer.writeString(offsets[8], object.table);
}

JiveSyncConflict _jiveSyncConflictDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveSyncConflict();
  object.detectedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.localId = reader.readLong(offsets[1]);
  object.localJson = reader.readString(offsets[2]);
  object.localUpdatedAt = reader.readDateTime(offsets[3]);
  object.remoteJson = reader.readString(offsets[4]);
  object.remoteUpdatedAt = reader.readDateTime(offsets[5]);
  object.resolvedAt = reader.readDateTimeOrNull(offsets[6]);
  object.status = reader.readString(offsets[7]);
  object.table = reader.readString(offsets[8]);
  return object;
}

P _jiveSyncConflictDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveSyncConflictGetId(JiveSyncConflict object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveSyncConflictGetLinks(JiveSyncConflict object) {
  return [];
}

void _jiveSyncConflictAttach(
    IsarCollection<dynamic> col, Id id, JiveSyncConflict object) {
  object.id = id;
}

extension JiveSyncConflictQueryWhereSort
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QWhere> {
  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveSyncConflictQueryWhere
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QWhereClause> {
  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause>
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

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause>
      tableEqualTo(String table) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'table',
        value: [table],
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause>
      tableNotEqualTo(String table) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'table',
              lower: [],
              upper: [table],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'table',
              lower: [table],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'table',
              lower: [table],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'table',
              lower: [],
              upper: [table],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause>
      statusEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterWhereClause>
      statusNotEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveSyncConflictQueryFilter
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QFilterCondition> {
  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      detectedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      detectedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'detectedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      detectedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'detectedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      detectedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'detectedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
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

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
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

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
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

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localUpdatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localUpdatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localUpdatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      localUpdatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localUpdatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteUpdatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteUpdatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteUpdatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      remoteUpdatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteUpdatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      resolvedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'resolvedAt',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      resolvedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'resolvedAt',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      resolvedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resolvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      resolvedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'resolvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      resolvedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'resolvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      resolvedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'resolvedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'table',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'table',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'table',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'table',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'table',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'table',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'table',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'table',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'table',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterFilterCondition>
      tableIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'table',
        value: '',
      ));
    });
  }
}

extension JiveSyncConflictQueryObject
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QFilterCondition> {}

extension JiveSyncConflictQueryLinks
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QFilterCondition> {}

extension JiveSyncConflictQuerySortBy
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QSortBy> {
  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByDetectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByDetectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByLocalJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localJson', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByLocalJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localJson', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByLocalUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByRemoteJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteJson', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByRemoteJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteJson', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByRemoteUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByResolvedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy> sortByTable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'table', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      sortByTableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'table', Sort.desc);
    });
  }
}

extension JiveSyncConflictQuerySortThenBy
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QSortThenBy> {
  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByDetectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByDetectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByLocalJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localJson', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByLocalJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localJson', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByLocalUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByRemoteJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteJson', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByRemoteJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteJson', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByRemoteUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByResolvedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy> thenByTable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'table', Sort.asc);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QAfterSortBy>
      thenByTableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'table', Sort.desc);
    });
  }
}

extension JiveSyncConflictQueryWhereDistinct
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct> {
  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct>
      distinctByDetectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedAt');
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct>
      distinctByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId');
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct>
      distinctByLocalJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct>
      distinctByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localUpdatedAt');
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct>
      distinctByRemoteJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct>
      distinctByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteUpdatedAt');
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct>
      distinctByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resolvedAt');
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSyncConflict, JiveSyncConflict, QDistinct> distinctByTable(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'table', caseSensitive: caseSensitive);
    });
  }
}

extension JiveSyncConflictQueryProperty
    on QueryBuilder<JiveSyncConflict, JiveSyncConflict, QQueryProperty> {
  QueryBuilder<JiveSyncConflict, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveSyncConflict, DateTime, QQueryOperations>
      detectedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedAt');
    });
  }

  QueryBuilder<JiveSyncConflict, int, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<JiveSyncConflict, String, QQueryOperations> localJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localJson');
    });
  }

  QueryBuilder<JiveSyncConflict, DateTime, QQueryOperations>
      localUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localUpdatedAt');
    });
  }

  QueryBuilder<JiveSyncConflict, String, QQueryOperations>
      remoteJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteJson');
    });
  }

  QueryBuilder<JiveSyncConflict, DateTime, QQueryOperations>
      remoteUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteUpdatedAt');
    });
  }

  QueryBuilder<JiveSyncConflict, DateTime?, QQueryOperations>
      resolvedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resolvedAt');
    });
  }

  QueryBuilder<JiveSyncConflict, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<JiveSyncConflict, String, QQueryOperations> tableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'table');
    });
  }
}
