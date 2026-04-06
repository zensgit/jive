// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_deposit_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveFixedDepositCollection on Isar {
  IsarCollection<JiveFixedDeposit> get jiveFixedDeposits => this.collection();
}

const JiveFixedDepositSchema = CollectionSchema(
  name: r'JiveFixedDeposit',
  id: 559995275291798190,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'annualRate': PropertySchema(
      id: 1,
      name: r'annualRate',
      type: IsarType.double,
    ),
    r'autoRenew': PropertySchema(
      id: 2,
      name: r'autoRenew',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'daysToMaturity': PropertySchema(
      id: 4,
      name: r'daysToMaturity',
      type: IsarType.long,
    ),
    r'expectedInterest': PropertySchema(
      id: 5,
      name: r'expectedInterest',
      type: IsarType.double,
    ),
    r'interestType': PropertySchema(
      id: 6,
      name: r'interestType',
      type: IsarType.string,
    ),
    r'isMatured': PropertySchema(
      id: 7,
      name: r'isMatured',
      type: IsarType.bool,
    ),
    r'maturityAmount': PropertySchema(
      id: 8,
      name: r'maturityAmount',
      type: IsarType.double,
    ),
    r'maturityDate': PropertySchema(
      id: 9,
      name: r'maturityDate',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 10,
      name: r'name',
      type: IsarType.string,
    ),
    r'note': PropertySchema(
      id: 11,
      name: r'note',
      type: IsarType.string,
    ),
    r'principal': PropertySchema(
      id: 12,
      name: r'principal',
      type: IsarType.double,
    ),
    r'startDate': PropertySchema(
      id: 13,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 14,
      name: r'status',
      type: IsarType.string,
    ),
    r'termMonths': PropertySchema(
      id: 15,
      name: r'termMonths',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 16,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveFixedDepositEstimateSize,
  serialize: _jiveFixedDepositSerialize,
  deserialize: _jiveFixedDepositDeserialize,
  deserializeProp: _jiveFixedDepositDeserializeProp,
  idName: r'id',
  indexes: {
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
    r'maturityDate': IndexSchema(
      id: 6086636242390800413,
      name: r'maturityDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'maturityDate',
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
  getId: _jiveFixedDepositGetId,
  getLinks: _jiveFixedDepositGetLinks,
  attach: _jiveFixedDepositAttach,
  version: '3.1.0+1',
);

int _jiveFixedDepositEstimateSize(
  JiveFixedDeposit object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.interestType.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _jiveFixedDepositSerialize(
  JiveFixedDeposit object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeDouble(offsets[1], object.annualRate);
  writer.writeBool(offsets[2], object.autoRenew);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeLong(offsets[4], object.daysToMaturity);
  writer.writeDouble(offsets[5], object.expectedInterest);
  writer.writeString(offsets[6], object.interestType);
  writer.writeBool(offsets[7], object.isMatured);
  writer.writeDouble(offsets[8], object.maturityAmount);
  writer.writeDateTime(offsets[9], object.maturityDate);
  writer.writeString(offsets[10], object.name);
  writer.writeString(offsets[11], object.note);
  writer.writeDouble(offsets[12], object.principal);
  writer.writeDateTime(offsets[13], object.startDate);
  writer.writeString(offsets[14], object.status);
  writer.writeLong(offsets[15], object.termMonths);
  writer.writeDateTime(offsets[16], object.updatedAt);
}

JiveFixedDeposit _jiveFixedDepositDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveFixedDeposit();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.annualRate = reader.readDouble(offsets[1]);
  object.autoRenew = reader.readBool(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.id = id;
  object.interestType = reader.readString(offsets[6]);
  object.maturityDate = reader.readDateTime(offsets[9]);
  object.name = reader.readString(offsets[10]);
  object.note = reader.readStringOrNull(offsets[11]);
  object.principal = reader.readDouble(offsets[12]);
  object.startDate = reader.readDateTime(offsets[13]);
  object.status = reader.readString(offsets[14]);
  object.termMonths = reader.readLong(offsets[15]);
  object.updatedAt = reader.readDateTime(offsets[16]);
  return object;
}

P _jiveFixedDepositDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveFixedDepositGetId(JiveFixedDeposit object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveFixedDepositGetLinks(JiveFixedDeposit object) {
  return [];
}

void _jiveFixedDepositAttach(
    IsarCollection<dynamic> col, Id id, JiveFixedDeposit object) {
  object.id = id;
}

extension JiveFixedDepositQueryWhereSort
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QWhere> {
  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhere> anyStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startDate'),
      );
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhere>
      anyMaturityDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'maturityDate'),
      );
    });
  }
}

extension JiveFixedDepositQueryWhere
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QWhereClause> {
  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      startDateEqualTo(DateTime startDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startDate',
        value: [startDate],
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      maturityDateEqualTo(DateTime maturityDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'maturityDate',
        value: [maturityDate],
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      maturityDateNotEqualTo(DateTime maturityDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'maturityDate',
              lower: [],
              upper: [maturityDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'maturityDate',
              lower: [maturityDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'maturityDate',
              lower: [maturityDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'maturityDate',
              lower: [],
              upper: [maturityDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      maturityDateGreaterThan(
    DateTime maturityDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'maturityDate',
        lower: [maturityDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      maturityDateLessThan(
    DateTime maturityDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'maturityDate',
        lower: [],
        upper: [maturityDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      maturityDateBetween(
    DateTime lowerMaturityDate,
    DateTime upperMaturityDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'maturityDate',
        lower: [lowerMaturityDate],
        includeLower: includeLower,
        upper: [upperMaturityDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
      statusEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterWhereClause>
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

extension JiveFixedDepositQueryFilter
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QFilterCondition> {
  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      accountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      annualRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'annualRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      annualRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'annualRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      annualRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'annualRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      annualRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'annualRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      autoRenewEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoRenew',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      daysToMaturityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysToMaturity',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      daysToMaturityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysToMaturity',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      daysToMaturityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysToMaturity',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      daysToMaturityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysToMaturity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      expectedInterestEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expectedInterest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      expectedInterestGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expectedInterest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      expectedInterestLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expectedInterest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      expectedInterestBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expectedInterest',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'interestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'interestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'interestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'interestType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'interestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'interestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'interestType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'interestType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'interestType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      interestTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'interestType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      isMaturedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMatured',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      maturityAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maturityAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      maturityAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maturityAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      maturityAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maturityAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      maturityAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maturityAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      maturityDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maturityDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      maturityDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maturityDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      maturityDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maturityDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      maturityDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maturityDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      principalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'principal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      principalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'principal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      principalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'principal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      principalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'principal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      startDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      termMonthsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'termMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      termMonthsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'termMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      termMonthsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'termMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      termMonthsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'termMonths',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterFilterCondition>
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

extension JiveFixedDepositQueryObject
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QFilterCondition> {}

extension JiveFixedDepositQueryLinks
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QFilterCondition> {}

extension JiveFixedDepositQuerySortBy
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QSortBy> {
  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByAnnualRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'annualRate', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByAnnualRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'annualRate', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRenew', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByAutoRenewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRenew', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByDaysToMaturity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysToMaturity', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByDaysToMaturityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysToMaturity', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByExpectedInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedInterest', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByExpectedInterestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedInterest', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByInterestType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestType', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByInterestTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestType', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByIsMatured() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMatured', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByIsMaturedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMatured', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByMaturityAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maturityAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByMaturityAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maturityAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByMaturityDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maturityDate', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByMaturityDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maturityDate', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByPrincipal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'principal', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByPrincipalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'principal', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByTermMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termMonths', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByTermMonthsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termMonths', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveFixedDepositQuerySortThenBy
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QSortThenBy> {
  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByAnnualRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'annualRate', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByAnnualRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'annualRate', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRenew', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByAutoRenewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRenew', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByDaysToMaturity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysToMaturity', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByDaysToMaturityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysToMaturity', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByExpectedInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedInterest', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByExpectedInterestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedInterest', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByInterestType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestType', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByInterestTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestType', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByIsMatured() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMatured', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByIsMaturedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMatured', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByMaturityAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maturityAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByMaturityAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maturityAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByMaturityDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maturityDate', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByMaturityDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maturityDate', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByPrincipal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'principal', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByPrincipalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'principal', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByTermMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termMonths', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByTermMonthsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termMonths', Sort.desc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveFixedDepositQueryWhereDistinct
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct> {
  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByAnnualRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'annualRate');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoRenew');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByDaysToMaturity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysToMaturity');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByExpectedInterest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expectedInterest');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByInterestType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'interestType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByIsMatured() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMatured');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByMaturityAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maturityAmount');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByMaturityDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maturityDate');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByPrincipal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'principal');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByTermMonths() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'termMonths');
    });
  }

  QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveFixedDepositQueryProperty
    on QueryBuilder<JiveFixedDeposit, JiveFixedDeposit, QQueryProperty> {
  QueryBuilder<JiveFixedDeposit, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveFixedDeposit, int?, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveFixedDeposit, double, QQueryOperations>
      annualRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'annualRate');
    });
  }

  QueryBuilder<JiveFixedDeposit, bool, QQueryOperations> autoRenewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoRenew');
    });
  }

  QueryBuilder<JiveFixedDeposit, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveFixedDeposit, int, QQueryOperations>
      daysToMaturityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysToMaturity');
    });
  }

  QueryBuilder<JiveFixedDeposit, double, QQueryOperations>
      expectedInterestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expectedInterest');
    });
  }

  QueryBuilder<JiveFixedDeposit, String, QQueryOperations>
      interestTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'interestType');
    });
  }

  QueryBuilder<JiveFixedDeposit, bool, QQueryOperations> isMaturedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMatured');
    });
  }

  QueryBuilder<JiveFixedDeposit, double, QQueryOperations>
      maturityAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maturityAmount');
    });
  }

  QueryBuilder<JiveFixedDeposit, DateTime, QQueryOperations>
      maturityDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maturityDate');
    });
  }

  QueryBuilder<JiveFixedDeposit, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<JiveFixedDeposit, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<JiveFixedDeposit, double, QQueryOperations> principalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'principal');
    });
  }

  QueryBuilder<JiveFixedDeposit, DateTime, QQueryOperations>
      startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<JiveFixedDeposit, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<JiveFixedDeposit, int, QQueryOperations> termMonthsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'termMonths');
    });
  }

  QueryBuilder<JiveFixedDeposit, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
