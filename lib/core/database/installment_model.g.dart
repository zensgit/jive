// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installment_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveInstallmentCollection on Isar {
  IsarCollection<JiveInstallment> get jiveInstallments => this.collection();
}

const JiveInstallmentSchema = CollectionSchema(
  name: r'JiveInstallment',
  id: -1036780890896865988,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'categoryKey': PropertySchema(
      id: 1,
      name: r'categoryKey',
      type: IsarType.string,
    ),
    r'commitMode': PropertySchema(
      id: 2,
      name: r'commitMode',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currency': PropertySchema(
      id: 4,
      name: r'currency',
      type: IsarType.string,
    ),
    r'executedPeriods': PropertySchema(
      id: 5,
      name: r'executedPeriods',
      type: IsarType.long,
    ),
    r'feeType': PropertySchema(
      id: 6,
      name: r'feeType',
      type: IsarType.string,
    ),
    r'finishedAt': PropertySchema(
      id: 7,
      name: r'finishedAt',
      type: IsarType.dateTime,
    ),
    r'includeFeeInLiability': PropertySchema(
      id: 8,
      name: r'includeFeeInLiability',
      type: IsarType.bool,
    ),
    r'includePrincipalInLiability': PropertySchema(
      id: 9,
      name: r'includePrincipalInLiability',
      type: IsarType.bool,
    ),
    r'isActive': PropertySchema(
      id: 10,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'key': PropertySchema(
      id: 11,
      name: r'key',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 12,
      name: r'name',
      type: IsarType.string,
    ),
    r'nextDueAt': PropertySchema(
      id: 13,
      name: r'nextDueAt',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(
      id: 14,
      name: r'note',
      type: IsarType.string,
    ),
    r'principalAmount': PropertySchema(
      id: 15,
      name: r'principalAmount',
      type: IsarType.double,
    ),
    r'remainderType': PropertySchema(
      id: 16,
      name: r'remainderType',
      type: IsarType.string,
    ),
    r'startDate': PropertySchema(
      id: 17,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 18,
      name: r'status',
      type: IsarType.string,
    ),
    r'subCategoryKey': PropertySchema(
      id: 19,
      name: r'subCategoryKey',
      type: IsarType.string,
    ),
    r'totalFee': PropertySchema(
      id: 20,
      name: r'totalFee',
      type: IsarType.double,
    ),
    r'totalPeriods': PropertySchema(
      id: 21,
      name: r'totalPeriods',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 22,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveInstallmentEstimateSize,
  serialize: _jiveInstallmentSerialize,
  deserialize: _jiveInstallmentDeserialize,
  deserializeProp: _jiveInstallmentDeserializeProp,
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
    r'accountId': IndexSchema(
      id: -1591555361937770434,
      name: r'accountId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'accountId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'startDate': IndexSchema(
      id: 7723980484494730382,
      name: r'startDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'nextDueAt': IndexSchema(
      id: -3685361607704079337,
      name: r'nextDueAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nextDueAt',
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveInstallmentGetId,
  getLinks: _jiveInstallmentGetLinks,
  attach: _jiveInstallmentAttach,
  version: '3.1.0+1',
);

int _jiveInstallmentEstimateSize(
  JiveInstallment object,
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
  bytesCount += 3 + object.currency.length * 3;
  bytesCount += 3 + object.feeType.length * 3;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.remainderType.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.subCategoryKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _jiveInstallmentSerialize(
  JiveInstallment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeString(offsets[1], object.categoryKey);
  writer.writeString(offsets[2], object.commitMode);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.currency);
  writer.writeLong(offsets[5], object.executedPeriods);
  writer.writeString(offsets[6], object.feeType);
  writer.writeDateTime(offsets[7], object.finishedAt);
  writer.writeBool(offsets[8], object.includeFeeInLiability);
  writer.writeBool(offsets[9], object.includePrincipalInLiability);
  writer.writeBool(offsets[10], object.isActive);
  writer.writeString(offsets[11], object.key);
  writer.writeString(offsets[12], object.name);
  writer.writeDateTime(offsets[13], object.nextDueAt);
  writer.writeString(offsets[14], object.note);
  writer.writeDouble(offsets[15], object.principalAmount);
  writer.writeString(offsets[16], object.remainderType);
  writer.writeDateTime(offsets[17], object.startDate);
  writer.writeString(offsets[18], object.status);
  writer.writeString(offsets[19], object.subCategoryKey);
  writer.writeDouble(offsets[20], object.totalFee);
  writer.writeLong(offsets[21], object.totalPeriods);
  writer.writeDateTime(offsets[22], object.updatedAt);
}

JiveInstallment _jiveInstallmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveInstallment();
  object.accountId = reader.readLong(offsets[0]);
  object.categoryKey = reader.readStringOrNull(offsets[1]);
  object.commitMode = reader.readString(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.currency = reader.readString(offsets[4]);
  object.executedPeriods = reader.readLong(offsets[5]);
  object.feeType = reader.readString(offsets[6]);
  object.finishedAt = reader.readDateTimeOrNull(offsets[7]);
  object.id = id;
  object.includeFeeInLiability = reader.readBool(offsets[8]);
  object.includePrincipalInLiability = reader.readBool(offsets[9]);
  object.isActive = reader.readBool(offsets[10]);
  object.key = reader.readString(offsets[11]);
  object.name = reader.readString(offsets[12]);
  object.nextDueAt = reader.readDateTime(offsets[13]);
  object.note = reader.readStringOrNull(offsets[14]);
  object.principalAmount = reader.readDouble(offsets[15]);
  object.remainderType = reader.readString(offsets[16]);
  object.startDate = reader.readDateTime(offsets[17]);
  object.status = reader.readString(offsets[18]);
  object.subCategoryKey = reader.readStringOrNull(offsets[19]);
  object.totalFee = reader.readDouble(offsets[20]);
  object.totalPeriods = reader.readLong(offsets[21]);
  object.updatedAt = reader.readDateTime(offsets[22]);
  return object;
}

P _jiveInstallmentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readDateTime(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readLong(offset)) as P;
    case 22:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveInstallmentGetId(JiveInstallment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveInstallmentGetLinks(JiveInstallment object) {
  return [];
}

void _jiveInstallmentAttach(
    IsarCollection<dynamic> col, Id id, JiveInstallment object) {
  object.id = id;
}

extension JiveInstallmentByIndex on IsarCollection<JiveInstallment> {
  Future<JiveInstallment?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  JiveInstallment? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<JiveInstallment?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<JiveInstallment?> getAllByKeySync(List<String> keyValues) {
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

  Future<Id> putByKey(JiveInstallment object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(JiveInstallment object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<JiveInstallment> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<JiveInstallment> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension JiveInstallmentQueryWhereSort
    on QueryBuilder<JiveInstallment, JiveInstallment, QWhere> {
  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhere> anyAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'accountId'),
      );
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhere> anyStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startDate'),
      );
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhere> anyNextDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'nextDueAt'),
      );
    });
  }
}

extension JiveInstallmentQueryWhere
    on QueryBuilder<JiveInstallment, JiveInstallment, QWhereClause> {
  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause> keyEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      keyNotEqualTo(String key) {
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      accountIdEqualTo(int accountId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'accountId',
        value: [accountId],
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      accountIdNotEqualTo(int accountId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'accountId',
              lower: [],
              upper: [accountId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'accountId',
              lower: [accountId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'accountId',
              lower: [accountId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'accountId',
              lower: [],
              upper: [accountId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      accountIdGreaterThan(
    int accountId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'accountId',
        lower: [accountId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      accountIdLessThan(
    int accountId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'accountId',
        lower: [],
        upper: [accountId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      accountIdBetween(
    int lowerAccountId,
    int upperAccountId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'accountId',
        lower: [lowerAccountId],
        includeLower: includeLower,
        upper: [upperAccountId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      startDateEqualTo(DateTime startDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startDate',
        value: [startDate],
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      startDateNotEqualTo(DateTime startDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startDate',
              lower: [],
              upper: [startDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startDate',
              lower: [startDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startDate',
              lower: [startDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startDate',
              lower: [],
              upper: [startDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      startDateGreaterThan(
    DateTime startDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startDate',
        lower: [startDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      startDateLessThan(
    DateTime startDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startDate',
        lower: [],
        upper: [startDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      startDateBetween(
    DateTime lowerStartDate,
    DateTime upperStartDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startDate',
        lower: [lowerStartDate],
        includeLower: includeLower,
        upper: [upperStartDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      nextDueAtEqualTo(DateTime nextDueAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nextDueAt',
        value: [nextDueAt],
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      nextDueAtNotEqualTo(DateTime nextDueAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextDueAt',
              lower: [],
              upper: [nextDueAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextDueAt',
              lower: [nextDueAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextDueAt',
              lower: [nextDueAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nextDueAt',
              lower: [],
              upper: [nextDueAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      nextDueAtGreaterThan(
    DateTime nextDueAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextDueAt',
        lower: [nextDueAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      nextDueAtLessThan(
    DateTime nextDueAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextDueAt',
        lower: [],
        upper: [nextDueAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      nextDueAtBetween(
    DateTime lowerNextDueAt,
    DateTime upperNextDueAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nextDueAt',
        lower: [lowerNextDueAt],
        includeLower: includeLower,
        upper: [upperNextDueAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
      statusEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterWhereClause>
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

extension JiveInstallmentQueryFilter
    on QueryBuilder<JiveInstallment, JiveInstallment, QFilterCondition> {
  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      accountIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      accountIdGreaterThan(
    int value, {
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      accountIdLessThan(
    int value, {
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      accountIdBetween(
    int lower,
    int upper, {
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      categoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryKey',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      categoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryKey',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      categoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      categoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      categoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      categoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      commitModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'commitMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      commitModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'commitMode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      commitModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'commitMode',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      commitModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'commitMode',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      executedPeriodsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executedPeriods',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      executedPeriodsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'executedPeriods',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      executedPeriodsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'executedPeriods',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      executedPeriodsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'executedPeriods',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'feeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'feeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'feeType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'feeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'feeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'feeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'feeType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feeType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      feeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'feeType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      finishedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'finishedAt',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      finishedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'finishedAt',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      finishedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'finishedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      includeFeeInLiabilityEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'includeFeeInLiability',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      includePrincipalInLiabilityEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'includePrincipalInLiability',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyEqualTo(
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyLessThan(
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyBetween(
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyStartsWith(
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyEndsWith(
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      nextDueAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextDueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      nextDueAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextDueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      nextDueAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextDueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      nextDueAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextDueAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      principalAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'principalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      principalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'principalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      principalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'principalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      principalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'principalAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainderType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainderType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainderType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainderType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remainderType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remainderType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remainderType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remainderType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainderType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      remainderTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remainderType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      startDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      subCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      subCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subCategoryKey',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      subCategoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subCategoryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      subCategoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subCategoryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      subCategoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      subCategoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subCategoryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      totalFeeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalFee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      totalFeeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalFee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      totalFeeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalFee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      totalFeeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalFee',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      totalPeriodsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalPeriods',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      totalPeriodsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalPeriods',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      totalPeriodsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalPeriods',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      totalPeriodsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalPeriods',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterFilterCondition>
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

extension JiveInstallmentQueryObject
    on QueryBuilder<JiveInstallment, JiveInstallment, QFilterCondition> {}

extension JiveInstallmentQueryLinks
    on QueryBuilder<JiveInstallment, JiveInstallment, QFilterCondition> {}

extension JiveInstallmentQuerySortBy
    on QueryBuilder<JiveInstallment, JiveInstallment, QSortBy> {
  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByCommitMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commitMode', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByCommitModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commitMode', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByExecutedPeriods() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedPeriods', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByExecutedPeriodsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedPeriods', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> sortByFeeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feeType', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByFeeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feeType', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByFinishedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finishedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByFinishedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finishedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByIncludeFeeInLiability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeFeeInLiability', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByIncludeFeeInLiabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeFeeInLiability', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByIncludePrincipalInLiability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includePrincipalInLiability', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByIncludePrincipalInLiabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includePrincipalInLiability', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByNextDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByNextDueAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueAt', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByPrincipalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'principalAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByPrincipalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'principalAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByRemainderType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainderType', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByRemainderTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainderType', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByTotalFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFee', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByTotalFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFee', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByTotalPeriods() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPeriods', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByTotalPeriodsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPeriods', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveInstallmentQuerySortThenBy
    on QueryBuilder<JiveInstallment, JiveInstallment, QSortThenBy> {
  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByCommitMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commitMode', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByCommitModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commitMode', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByExecutedPeriods() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedPeriods', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByExecutedPeriodsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedPeriods', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> thenByFeeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feeType', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByFeeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feeType', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByFinishedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finishedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByFinishedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finishedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByIncludeFeeInLiability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeFeeInLiability', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByIncludeFeeInLiabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeFeeInLiability', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByIncludePrincipalInLiability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includePrincipalInLiability', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByIncludePrincipalInLiabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includePrincipalInLiability', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByNextDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByNextDueAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueAt', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByPrincipalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'principalAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByPrincipalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'principalAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByRemainderType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainderType', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByRemainderTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainderType', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByTotalFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFee', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByTotalFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFee', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByTotalPeriods() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPeriods', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByTotalPeriodsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPeriods', Sort.desc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveInstallmentQueryWhereDistinct
    on QueryBuilder<JiveInstallment, JiveInstallment, QDistinct> {
  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByCommitMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'commitMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct> distinctByCurrency(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByExecutedPeriods() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'executedPeriods');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct> distinctByFeeType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'feeType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByFinishedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'finishedAt');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByIncludeFeeInLiability() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'includeFeeInLiability');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByIncludePrincipalInLiability() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'includePrincipalInLiability');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByNextDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextDueAt');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByPrincipalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'principalAmount');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByRemainderType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainderType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctBySubCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCategoryKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByTotalFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalFee');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByTotalPeriods() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalPeriods');
    });
  }

  QueryBuilder<JiveInstallment, JiveInstallment, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveInstallmentQueryProperty
    on QueryBuilder<JiveInstallment, JiveInstallment, QQueryProperty> {
  QueryBuilder<JiveInstallment, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveInstallment, int, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveInstallment, String?, QQueryOperations>
      categoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryKey');
    });
  }

  QueryBuilder<JiveInstallment, String, QQueryOperations> commitModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'commitMode');
    });
  }

  QueryBuilder<JiveInstallment, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveInstallment, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<JiveInstallment, int, QQueryOperations>
      executedPeriodsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'executedPeriods');
    });
  }

  QueryBuilder<JiveInstallment, String, QQueryOperations> feeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'feeType');
    });
  }

  QueryBuilder<JiveInstallment, DateTime?, QQueryOperations>
      finishedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'finishedAt');
    });
  }

  QueryBuilder<JiveInstallment, bool, QQueryOperations>
      includeFeeInLiabilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'includeFeeInLiability');
    });
  }

  QueryBuilder<JiveInstallment, bool, QQueryOperations>
      includePrincipalInLiabilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'includePrincipalInLiability');
    });
  }

  QueryBuilder<JiveInstallment, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<JiveInstallment, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<JiveInstallment, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<JiveInstallment, DateTime, QQueryOperations>
      nextDueAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextDueAt');
    });
  }

  QueryBuilder<JiveInstallment, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<JiveInstallment, double, QQueryOperations>
      principalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'principalAmount');
    });
  }

  QueryBuilder<JiveInstallment, String, QQueryOperations>
      remainderTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainderType');
    });
  }

  QueryBuilder<JiveInstallment, DateTime, QQueryOperations>
      startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<JiveInstallment, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<JiveInstallment, String?, QQueryOperations>
      subCategoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategoryKey');
    });
  }

  QueryBuilder<JiveInstallment, double, QQueryOperations> totalFeeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalFee');
    });
  }

  QueryBuilder<JiveInstallment, int, QQueryOperations> totalPeriodsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalPeriods');
    });
  }

  QueryBuilder<JiveInstallment, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
