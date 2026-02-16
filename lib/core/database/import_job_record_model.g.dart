// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_job_record_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveImportJobRecordCollection on Isar {
  IsarCollection<JiveImportJobRecord> get jiveImportJobRecords =>
      this.collection();
}

const JiveImportJobRecordSchema = CollectionSchema(
  name: r'JiveImportJobRecord',
  id: -2649845843324232173,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'confidence': PropertySchema(
      id: 1,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'decision': PropertySchema(
      id: 3,
      name: r'decision',
      type: IsarType.string,
    ),
    r'decisionReason': PropertySchema(
      id: 4,
      name: r'decisionReason',
      type: IsarType.string,
    ),
    r'dedupKey': PropertySchema(
      id: 5,
      name: r'dedupKey',
      type: IsarType.string,
    ),
    r'jobId': PropertySchema(
      id: 6,
      name: r'jobId',
      type: IsarType.long,
    ),
    r'riskLevel': PropertySchema(
      id: 7,
      name: r'riskLevel',
      type: IsarType.string,
    ),
    r'source': PropertySchema(
      id: 8,
      name: r'source',
      type: IsarType.string,
    ),
    r'sourceLineNumber': PropertySchema(
      id: 9,
      name: r'sourceLineNumber',
      type: IsarType.long,
    ),
    r'timestamp': PropertySchema(
      id: 10,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'type': PropertySchema(
      id: 11,
      name: r'type',
      type: IsarType.string,
    ),
    r'warningsJson': PropertySchema(
      id: 12,
      name: r'warningsJson',
      type: IsarType.string,
    )
  },
  estimateSize: _jiveImportJobRecordEstimateSize,
  serialize: _jiveImportJobRecordSerialize,
  deserialize: _jiveImportJobRecordDeserialize,
  deserializeProp: _jiveImportJobRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'jobId': IndexSchema(
      id: 7916160552736803877,
      name: r'jobId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'jobId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
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
    r'riskLevel': IndexSchema(
      id: -5764699641590423344,
      name: r'riskLevel',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'riskLevel',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'decision': IndexSchema(
      id: -6438185418393544667,
      name: r'decision',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'decision',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveImportJobRecordGetId,
  getLinks: _jiveImportJobRecordGetLinks,
  attach: _jiveImportJobRecordAttach,
  version: '3.1.0+1',
);

int _jiveImportJobRecordEstimateSize(
  JiveImportJobRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.decision.length * 3;
  {
    final value = object.decisionReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.dedupKey.length * 3;
  bytesCount += 3 + object.riskLevel.length * 3;
  bytesCount += 3 + object.source.length * 3;
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.warningsJson.length * 3;
  return bytesCount;
}

void _jiveImportJobRecordSerialize(
  JiveImportJobRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDouble(offsets[1], object.confidence);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.decision);
  writer.writeString(offsets[4], object.decisionReason);
  writer.writeString(offsets[5], object.dedupKey);
  writer.writeLong(offsets[6], object.jobId);
  writer.writeString(offsets[7], object.riskLevel);
  writer.writeString(offsets[8], object.source);
  writer.writeLong(offsets[9], object.sourceLineNumber);
  writer.writeDateTime(offsets[10], object.timestamp);
  writer.writeString(offsets[11], object.type);
  writer.writeString(offsets[12], object.warningsJson);
}

JiveImportJobRecord _jiveImportJobRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveImportJobRecord();
  object.amount = reader.readDouble(offsets[0]);
  object.confidence = reader.readDouble(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.decision = reader.readString(offsets[3]);
  object.decisionReason = reader.readStringOrNull(offsets[4]);
  object.dedupKey = reader.readString(offsets[5]);
  object.id = id;
  object.jobId = reader.readLong(offsets[6]);
  object.riskLevel = reader.readString(offsets[7]);
  object.source = reader.readString(offsets[8]);
  object.sourceLineNumber = reader.readLong(offsets[9]);
  object.timestamp = reader.readDateTime(offsets[10]);
  object.type = reader.readStringOrNull(offsets[11]);
  object.warningsJson = reader.readString(offsets[12]);
  return object;
}

P _jiveImportJobRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveImportJobRecordGetId(JiveImportJobRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveImportJobRecordGetLinks(
    JiveImportJobRecord object) {
  return [];
}

void _jiveImportJobRecordAttach(
    IsarCollection<dynamic> col, Id id, JiveImportJobRecord object) {
  object.id = id;
}

extension JiveImportJobRecordQueryWhereSort
    on QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QWhere> {
  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhere>
      anyJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'jobId'),
      );
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhere>
      anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhere>
      anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension JiveImportJobRecordQueryWhere
    on QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QWhereClause> {
  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      jobIdEqualTo(int jobId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'jobId',
        value: [jobId],
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      jobIdNotEqualTo(int jobId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [],
              upper: [jobId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [jobId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [jobId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [],
              upper: [jobId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      jobIdGreaterThan(
    int jobId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'jobId',
        lower: [jobId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      jobIdLessThan(
    int jobId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'jobId',
        lower: [],
        upper: [jobId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      jobIdBetween(
    int lowerJobId,
    int upperJobId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'jobId',
        lower: [lowerJobId],
        includeLower: includeLower,
        upper: [upperJobId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      riskLevelEqualTo(String riskLevel) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'riskLevel',
        value: [riskLevel],
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      riskLevelNotEqualTo(String riskLevel) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'riskLevel',
              lower: [],
              upper: [riskLevel],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'riskLevel',
              lower: [riskLevel],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'riskLevel',
              lower: [riskLevel],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'riskLevel',
              lower: [],
              upper: [riskLevel],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      decisionEqualTo(String decision) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'decision',
        value: [decision],
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      decisionNotEqualTo(String decision) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'decision',
              lower: [],
              upper: [decision],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'decision',
              lower: [decision],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'decision',
              lower: [decision],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'decision',
              lower: [],
              upper: [decision],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterWhereClause>
      createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveImportJobRecordQueryFilter on QueryBuilder<JiveImportJobRecord,
    JiveImportJobRecord, QFilterCondition> {
  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      confidenceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      confidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      confidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      confidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'decision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'decision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'decision',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'decision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'decision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'decision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'decision',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decision',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'decision',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'decisionReason',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'decisionReason',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decisionReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'decisionReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'decisionReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'decisionReason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'decisionReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'decisionReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'decisionReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'decisionReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decisionReason',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      decisionReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'decisionReason',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      dedupKeyEqualTo(
    String value, {
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      dedupKeyGreaterThan(
    String value, {
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      dedupKeyLessThan(
    String value, {
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      dedupKeyBetween(
    String lower,
    String upper, {
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      dedupKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dedupKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      dedupKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dedupKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      dedupKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dedupKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      dedupKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dedupKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      jobIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      jobIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jobId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      jobIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jobId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      jobIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jobId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'riskLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'riskLevel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'riskLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      riskLevelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'riskLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      sourceLineNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceLineNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      sourceLineNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceLineNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      sourceLineNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceLineNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      sourceLineNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceLineNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      typeEqualTo(
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      typeBetween(
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'warningsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'warningsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'warningsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'warningsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'warningsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'warningsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'warningsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'warningsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'warningsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterFilterCondition>
      warningsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'warningsJson',
        value: '',
      ));
    });
  }
}

extension JiveImportJobRecordQueryObject on QueryBuilder<JiveImportJobRecord,
    JiveImportJobRecord, QFilterCondition> {}

extension JiveImportJobRecordQueryLinks on QueryBuilder<JiveImportJobRecord,
    JiveImportJobRecord, QFilterCondition> {}

extension JiveImportJobRecordQuerySortBy
    on QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QSortBy> {
  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByDecision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decision', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByDecisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decision', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByDecisionReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionReason', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByDecisionReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionReason', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByDedupKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dedupKey', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByDedupKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dedupKey', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByRiskLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByRiskLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortBySourceLineNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLineNumber', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortBySourceLineNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLineNumber', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByWarningsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warningsJson', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      sortByWarningsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warningsJson', Sort.desc);
    });
  }
}

extension JiveImportJobRecordQuerySortThenBy
    on QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QSortThenBy> {
  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByDecision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decision', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByDecisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decision', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByDecisionReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionReason', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByDecisionReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionReason', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByDedupKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dedupKey', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByDedupKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dedupKey', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByRiskLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByRiskLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenBySourceLineNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLineNumber', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenBySourceLineNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLineNumber', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByWarningsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warningsJson', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QAfterSortBy>
      thenByWarningsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warningsJson', Sort.desc);
    });
  }
}

extension JiveImportJobRecordQueryWhereDistinct
    on QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct> {
  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence');
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByDecision({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'decision', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByDecisionReason({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'decisionReason',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByDedupKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dedupKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobId');
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByRiskLevel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'riskLevel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctBySourceLineNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceLineNumber');
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QDistinct>
      distinctByWarningsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'warningsJson', caseSensitive: caseSensitive);
    });
  }
}

extension JiveImportJobRecordQueryProperty
    on QueryBuilder<JiveImportJobRecord, JiveImportJobRecord, QQueryProperty> {
  QueryBuilder<JiveImportJobRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveImportJobRecord, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<JiveImportJobRecord, double, QQueryOperations>
      confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<JiveImportJobRecord, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveImportJobRecord, String, QQueryOperations>
      decisionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'decision');
    });
  }

  QueryBuilder<JiveImportJobRecord, String?, QQueryOperations>
      decisionReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'decisionReason');
    });
  }

  QueryBuilder<JiveImportJobRecord, String, QQueryOperations>
      dedupKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dedupKey');
    });
  }

  QueryBuilder<JiveImportJobRecord, int, QQueryOperations> jobIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobId');
    });
  }

  QueryBuilder<JiveImportJobRecord, String, QQueryOperations>
      riskLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'riskLevel');
    });
  }

  QueryBuilder<JiveImportJobRecord, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<JiveImportJobRecord, int, QQueryOperations>
      sourceLineNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceLineNumber');
    });
  }

  QueryBuilder<JiveImportJobRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<JiveImportJobRecord, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<JiveImportJobRecord, String, QQueryOperations>
      warningsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'warningsJson');
    });
  }
}
