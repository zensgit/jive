// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_job_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveImportJobCollection on Isar {
  IsarCollection<JiveImportJob> get jiveImportJobs => this.collection();
}

const JiveImportJobSchema = CollectionSchema(
  name: r'JiveImportJob',
  id: -1057496840939284094,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'decisionSummaryJson': PropertySchema(
      id: 1,
      name: r'decisionSummaryJson',
      type: IsarType.string,
    ),
    r'duplicateCount': PropertySchema(
      id: 2,
      name: r'duplicateCount',
      type: IsarType.long,
    ),
    r'duplicatePolicy': PropertySchema(
      id: 3,
      name: r'duplicatePolicy',
      type: IsarType.string,
    ),
    r'entryType': PropertySchema(
      id: 4,
      name: r'entryType',
      type: IsarType.string,
    ),
    r'errorMessage': PropertySchema(
      id: 5,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'fileName': PropertySchema(
      id: 6,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'filePath': PropertySchema(
      id: 7,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'finishedAt': PropertySchema(
      id: 8,
      name: r'finishedAt',
      type: IsarType.dateTime,
    ),
    r'insertedCount': PropertySchema(
      id: 9,
      name: r'insertedCount',
      type: IsarType.long,
    ),
    r'invalidCount': PropertySchema(
      id: 10,
      name: r'invalidCount',
      type: IsarType.long,
    ),
    r'payloadText': PropertySchema(
      id: 11,
      name: r'payloadText',
      type: IsarType.string,
    ),
    r'retryCount': PropertySchema(
      id: 12,
      name: r'retryCount',
      type: IsarType.long,
    ),
    r'retryFromJobId': PropertySchema(
      id: 13,
      name: r'retryFromJobId',
      type: IsarType.long,
    ),
    r'skippedByDuplicateDecisionCount': PropertySchema(
      id: 14,
      name: r'skippedByDuplicateDecisionCount',
      type: IsarType.long,
    ),
    r'sourceType': PropertySchema(
      id: 15,
      name: r'sourceType',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 16,
      name: r'status',
      type: IsarType.string,
    ),
    r'totalCount': PropertySchema(
      id: 17,
      name: r'totalCount',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 18,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveImportJobEstimateSize,
  serialize: _jiveImportJobSerialize,
  deserialize: _jiveImportJobDeserialize,
  deserializeProp: _jiveImportJobDeserializeProp,
  idName: r'id',
  indexes: {
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
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
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
    ),
    r'sourceType': IndexSchema(
      id: 5365578901051110922,
      name: r'sourceType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sourceType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'duplicatePolicy': IndexSchema(
      id: 9159316549581538169,
      name: r'duplicatePolicy',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'duplicatePolicy',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'retryFromJobId': IndexSchema(
      id: 5147065010982805222,
      name: r'retryFromJobId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'retryFromJobId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveImportJobGetId,
  getLinks: _jiveImportJobGetLinks,
  attach: _jiveImportJobAttach,
  version: '3.1.0+1',
);

int _jiveImportJobEstimateSize(
  JiveImportJob object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.decisionSummaryJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.duplicatePolicy.length * 3;
  bytesCount += 3 + object.entryType.length * 3;
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fileName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.filePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.payloadText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceType.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _jiveImportJobSerialize(
  JiveImportJob object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.decisionSummaryJson);
  writer.writeLong(offsets[2], object.duplicateCount);
  writer.writeString(offsets[3], object.duplicatePolicy);
  writer.writeString(offsets[4], object.entryType);
  writer.writeString(offsets[5], object.errorMessage);
  writer.writeString(offsets[6], object.fileName);
  writer.writeString(offsets[7], object.filePath);
  writer.writeDateTime(offsets[8], object.finishedAt);
  writer.writeLong(offsets[9], object.insertedCount);
  writer.writeLong(offsets[10], object.invalidCount);
  writer.writeString(offsets[11], object.payloadText);
  writer.writeLong(offsets[12], object.retryCount);
  writer.writeLong(offsets[13], object.retryFromJobId);
  writer.writeLong(offsets[14], object.skippedByDuplicateDecisionCount);
  writer.writeString(offsets[15], object.sourceType);
  writer.writeString(offsets[16], object.status);
  writer.writeLong(offsets[17], object.totalCount);
  writer.writeDateTime(offsets[18], object.updatedAt);
}

JiveImportJob _jiveImportJobDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveImportJob();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.decisionSummaryJson = reader.readStringOrNull(offsets[1]);
  object.duplicateCount = reader.readLong(offsets[2]);
  object.duplicatePolicy = reader.readString(offsets[3]);
  object.entryType = reader.readString(offsets[4]);
  object.errorMessage = reader.readStringOrNull(offsets[5]);
  object.fileName = reader.readStringOrNull(offsets[6]);
  object.filePath = reader.readStringOrNull(offsets[7]);
  object.finishedAt = reader.readDateTimeOrNull(offsets[8]);
  object.id = id;
  object.insertedCount = reader.readLong(offsets[9]);
  object.invalidCount = reader.readLong(offsets[10]);
  object.payloadText = reader.readStringOrNull(offsets[11]);
  object.retryCount = reader.readLong(offsets[12]);
  object.retryFromJobId = reader.readLongOrNull(offsets[13]);
  object.skippedByDuplicateDecisionCount = reader.readLong(offsets[14]);
  object.sourceType = reader.readString(offsets[15]);
  object.status = reader.readString(offsets[16]);
  object.totalCount = reader.readLong(offsets[17]);
  object.updatedAt = reader.readDateTime(offsets[18]);
  return object;
}

P _jiveImportJobDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveImportJobGetId(JiveImportJob object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveImportJobGetLinks(JiveImportJob object) {
  return [];
}

void _jiveImportJobAttach(
    IsarCollection<dynamic> col, Id id, JiveImportJob object) {
  object.id = id;
}

extension JiveImportJobQueryWhereSort
    on QueryBuilder<JiveImportJob, JiveImportJob, QWhere> {
  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhere> anyRetryFromJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'retryFromJobId'),
      );
    });
  }
}

extension JiveImportJobQueryWhere
    on QueryBuilder<JiveImportJob, JiveImportJob, QWhereClause> {
  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAt',
        value: [updatedAt],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      updatedAtGreaterThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [updatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [],
        upper: [updatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [lowerUpdatedAt],
        includeLower: includeLower,
        upper: [upperUpdatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause> statusEqualTo(
      String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      sourceTypeEqualTo(String sourceType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sourceType',
        value: [sourceType],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      sourceTypeNotEqualTo(String sourceType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceType',
              lower: [],
              upper: [sourceType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceType',
              lower: [sourceType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceType',
              lower: [sourceType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceType',
              lower: [],
              upper: [sourceType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      duplicatePolicyEqualTo(String duplicatePolicy) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'duplicatePolicy',
        value: [duplicatePolicy],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      duplicatePolicyNotEqualTo(String duplicatePolicy) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'duplicatePolicy',
              lower: [],
              upper: [duplicatePolicy],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'duplicatePolicy',
              lower: [duplicatePolicy],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'duplicatePolicy',
              lower: [duplicatePolicy],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'duplicatePolicy',
              lower: [],
              upper: [duplicatePolicy],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      retryFromJobIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'retryFromJobId',
        value: [null],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      retryFromJobIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'retryFromJobId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      retryFromJobIdEqualTo(int? retryFromJobId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'retryFromJobId',
        value: [retryFromJobId],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      retryFromJobIdNotEqualTo(int? retryFromJobId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'retryFromJobId',
              lower: [],
              upper: [retryFromJobId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'retryFromJobId',
              lower: [retryFromJobId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'retryFromJobId',
              lower: [retryFromJobId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'retryFromJobId',
              lower: [],
              upper: [retryFromJobId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      retryFromJobIdGreaterThan(
    int? retryFromJobId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'retryFromJobId',
        lower: [retryFromJobId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      retryFromJobIdLessThan(
    int? retryFromJobId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'retryFromJobId',
        lower: [],
        upper: [retryFromJobId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterWhereClause>
      retryFromJobIdBetween(
    int? lowerRetryFromJobId,
    int? upperRetryFromJobId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'retryFromJobId',
        lower: [lowerRetryFromJobId],
        includeLower: includeLower,
        upper: [upperRetryFromJobId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveImportJobQueryFilter
    on QueryBuilder<JiveImportJob, JiveImportJob, QFilterCondition> {
  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'decisionSummaryJson',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'decisionSummaryJson',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decisionSummaryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'decisionSummaryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'decisionSummaryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'decisionSummaryJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'decisionSummaryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'decisionSummaryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'decisionSummaryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'decisionSummaryJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decisionSummaryJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      decisionSummaryJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'decisionSummaryJson',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicateCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duplicateCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicateCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duplicateCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicateCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duplicateCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicateCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duplicateCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duplicatePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duplicatePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duplicatePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duplicatePolicy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'duplicatePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'duplicatePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'duplicatePolicy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'duplicatePolicy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duplicatePolicy',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      duplicatePolicyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'duplicatePolicy',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entryType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entryType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      entryTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entryType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorMessage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fileName',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fileName',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      finishedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'finishedAt',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      finishedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'finishedAt',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      finishedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'finishedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      finishedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'finishedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      finishedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'finishedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      finishedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'finishedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition> idBetween(
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      insertedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'insertedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      insertedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'insertedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      insertedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'insertedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      insertedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'insertedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      invalidCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invalidCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      invalidCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invalidCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      invalidCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invalidCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      invalidCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invalidCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'payloadText',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'payloadText',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payloadText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payloadText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payloadText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payloadText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payloadText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payloadText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payloadText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadText',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      payloadTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadText',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryFromJobIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'retryFromJobId',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryFromJobIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'retryFromJobId',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryFromJobIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retryFromJobId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryFromJobIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retryFromJobId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryFromJobIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retryFromJobId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      retryFromJobIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retryFromJobId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      skippedByDuplicateDecisionCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skippedByDuplicateDecisionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      skippedByDuplicateDecisionCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skippedByDuplicateDecisionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      skippedByDuplicateDecisionCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skippedByDuplicateDecisionCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      skippedByDuplicateDecisionCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skippedByDuplicateDecisionCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      sourceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      totalCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      totalCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      totalCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      totalCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterFilterCondition>
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

extension JiveImportJobQueryObject
    on QueryBuilder<JiveImportJob, JiveImportJob, QFilterCondition> {}

extension JiveImportJobQueryLinks
    on QueryBuilder<JiveImportJob, JiveImportJob, QFilterCondition> {}

extension JiveImportJobQuerySortBy
    on QueryBuilder<JiveImportJob, JiveImportJob, QSortBy> {
  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByDecisionSummaryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionSummaryJson', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByDecisionSummaryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionSummaryJson', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByDuplicateCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duplicateCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByDuplicateCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duplicateCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByDuplicatePolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duplicatePolicy', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByDuplicatePolicyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duplicatePolicy', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByEntryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByEntryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByFinishedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finishedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByFinishedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finishedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByInsertedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insertedCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByInsertedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insertedCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByInvalidCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invalidCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByInvalidCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invalidCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByPayloadText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadText', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByPayloadTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadText', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByRetryFromJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryFromJobId', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByRetryFromJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryFromJobId', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortBySkippedByDuplicateDecisionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedByDuplicateDecisionCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortBySkippedByDuplicateDecisionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedByDuplicateDecisionCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByTotalCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveImportJobQuerySortThenBy
    on QueryBuilder<JiveImportJob, JiveImportJob, QSortThenBy> {
  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByDecisionSummaryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionSummaryJson', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByDecisionSummaryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionSummaryJson', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByDuplicateCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duplicateCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByDuplicateCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duplicateCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByDuplicatePolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duplicatePolicy', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByDuplicatePolicyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duplicatePolicy', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByEntryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByEntryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByFinishedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finishedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByFinishedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finishedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByInsertedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insertedCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByInsertedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insertedCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByInvalidCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invalidCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByInvalidCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invalidCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByPayloadText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadText', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByPayloadTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadText', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByRetryFromJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryFromJobId', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByRetryFromJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryFromJobId', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenBySkippedByDuplicateDecisionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedByDuplicateDecisionCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenBySkippedByDuplicateDecisionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skippedByDuplicateDecisionCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByTotalCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.desc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveImportJobQueryWhereDistinct
    on QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> {
  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct>
      distinctByDecisionSummaryJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'decisionSummaryJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct>
      distinctByDuplicateCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'duplicateCount');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct>
      distinctByDuplicatePolicy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'duplicatePolicy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByEntryType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByErrorMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByFileName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByFilePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByFinishedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'finishedAt');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct>
      distinctByInsertedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'insertedCount');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct>
      distinctByInvalidCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invalidCount');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByPayloadText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct>
      distinctByRetryFromJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryFromJobId');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct>
      distinctBySkippedByDuplicateDecisionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skippedByDuplicateDecisionCount');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctBySourceType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCount');
    });
  }

  QueryBuilder<JiveImportJob, JiveImportJob, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveImportJobQueryProperty
    on QueryBuilder<JiveImportJob, JiveImportJob, QQueryProperty> {
  QueryBuilder<JiveImportJob, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveImportJob, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveImportJob, String?, QQueryOperations>
      decisionSummaryJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'decisionSummaryJson');
    });
  }

  QueryBuilder<JiveImportJob, int, QQueryOperations> duplicateCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'duplicateCount');
    });
  }

  QueryBuilder<JiveImportJob, String, QQueryOperations>
      duplicatePolicyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'duplicatePolicy');
    });
  }

  QueryBuilder<JiveImportJob, String, QQueryOperations> entryTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryType');
    });
  }

  QueryBuilder<JiveImportJob, String?, QQueryOperations>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<JiveImportJob, String?, QQueryOperations> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<JiveImportJob, String?, QQueryOperations> filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<JiveImportJob, DateTime?, QQueryOperations>
      finishedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'finishedAt');
    });
  }

  QueryBuilder<JiveImportJob, int, QQueryOperations> insertedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'insertedCount');
    });
  }

  QueryBuilder<JiveImportJob, int, QQueryOperations> invalidCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invalidCount');
    });
  }

  QueryBuilder<JiveImportJob, String?, QQueryOperations> payloadTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadText');
    });
  }

  QueryBuilder<JiveImportJob, int, QQueryOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }

  QueryBuilder<JiveImportJob, int?, QQueryOperations> retryFromJobIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryFromJobId');
    });
  }

  QueryBuilder<JiveImportJob, int, QQueryOperations>
      skippedByDuplicateDecisionCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skippedByDuplicateDecisionCount');
    });
  }

  QueryBuilder<JiveImportJob, String, QQueryOperations> sourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceType');
    });
  }

  QueryBuilder<JiveImportJob, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<JiveImportJob, int, QQueryOperations> totalCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCount');
    });
  }

  QueryBuilder<JiveImportJob, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
