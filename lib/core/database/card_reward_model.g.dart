// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_reward_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveCardRewardCollection on Isar {
  IsarCollection<JiveCardReward> get jiveCardRewards => this.collection();
}

const JiveCardRewardSchema = CollectionSchema(
  name: r'JiveCardReward',
  id: -3937127606489099656,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'accountName': PropertySchema(
      id: 1,
      name: r'accountName',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isEnabled': PropertySchema(
      id: 3,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'lastResetMonth': PropertySchema(
      id: 4,
      name: r'lastResetMonth',
      type: IsarType.string,
    ),
    r'monthEarned': PropertySchema(
      id: 5,
      name: r'monthEarned',
      type: IsarType.double,
    ),
    r'monthlyCapAmount': PropertySchema(
      id: 6,
      name: r'monthlyCapAmount',
      type: IsarType.double,
    ),
    r'monthlyRemaining': PropertySchema(
      id: 7,
      name: r'monthlyRemaining',
      type: IsarType.double,
    ),
    r'rewardRate': PropertySchema(
      id: 8,
      name: r'rewardRate',
      type: IsarType.double,
    ),
    r'rewardType': PropertySchema(
      id: 9,
      name: r'rewardType',
      type: IsarType.string,
    ),
    r'totalEarned': PropertySchema(
      id: 10,
      name: r'totalEarned',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveCardRewardEstimateSize,
  serialize: _jiveCardRewardSerialize,
  deserialize: _jiveCardRewardDeserialize,
  deserializeProp: _jiveCardRewardDeserializeProp,
  idName: r'id',
  indexes: {
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveCardRewardGetId,
  getLinks: _jiveCardRewardGetLinks,
  attach: _jiveCardRewardAttach,
  version: '3.1.0+1',
);

int _jiveCardRewardEstimateSize(
  JiveCardReward object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accountName.length * 3;
  bytesCount += 3 + object.lastResetMonth.length * 3;
  bytesCount += 3 + object.rewardType.length * 3;
  return bytesCount;
}

void _jiveCardRewardSerialize(
  JiveCardReward object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeString(offsets[1], object.accountName);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.isEnabled);
  writer.writeString(offsets[4], object.lastResetMonth);
  writer.writeDouble(offsets[5], object.monthEarned);
  writer.writeDouble(offsets[6], object.monthlyCapAmount);
  writer.writeDouble(offsets[7], object.monthlyRemaining);
  writer.writeDouble(offsets[8], object.rewardRate);
  writer.writeString(offsets[9], object.rewardType);
  writer.writeDouble(offsets[10], object.totalEarned);
  writer.writeDateTime(offsets[11], object.updatedAt);
}

JiveCardReward _jiveCardRewardDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveCardReward();
  object.accountId = reader.readLong(offsets[0]);
  object.accountName = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.isEnabled = reader.readBool(offsets[3]);
  object.lastResetMonth = reader.readString(offsets[4]);
  object.monthEarned = reader.readDouble(offsets[5]);
  object.monthlyCapAmount = reader.readDoubleOrNull(offsets[6]);
  object.rewardRate = reader.readDouble(offsets[8]);
  object.rewardType = reader.readString(offsets[9]);
  object.totalEarned = reader.readDouble(offsets[10]);
  object.updatedAt = reader.readDateTime(offsets[11]);
  return object;
}

P _jiveCardRewardDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveCardRewardGetId(JiveCardReward object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveCardRewardGetLinks(JiveCardReward object) {
  return [];
}

void _jiveCardRewardAttach(
    IsarCollection<dynamic> col, Id id, JiveCardReward object) {
  object.id = id;
}

extension JiveCardRewardQueryWhereSort
    on QueryBuilder<JiveCardReward, JiveCardReward, QWhere> {
  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhere> anyAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'accountId'),
      );
    });
  }
}

extension JiveCardRewardQueryWhere
    on QueryBuilder<JiveCardReward, JiveCardReward, QWhereClause> {
  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause>
      accountIdEqualTo(int accountId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'accountId',
        value: [accountId],
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterWhereClause>
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
}

extension JiveCardRewardQueryFilter
    on QueryBuilder<JiveCardReward, JiveCardReward, QFilterCondition> {
  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accountName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accountName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      accountNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accountName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition> idBetween(
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastResetMonth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastResetMonth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastResetMonth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastResetMonth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastResetMonth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastResetMonth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastResetMonth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastResetMonth',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastResetMonth',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      lastResetMonthIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastResetMonth',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthEarnedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthEarned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthEarnedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthEarned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthEarnedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthEarned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthEarnedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthEarned',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyCapAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'monthlyCapAmount',
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyCapAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'monthlyCapAmount',
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyCapAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyCapAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyCapAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyCapAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyCapAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyCapAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyCapAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyCapAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyRemainingEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyRemaining',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyRemainingGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyRemaining',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyRemainingLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyRemaining',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      monthlyRemainingBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyRemaining',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rewardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rewardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rewardType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rewardType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      rewardTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rewardType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      totalEarnedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalEarned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      totalEarnedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalEarned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      totalEarnedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalEarned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      totalEarnedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalEarned',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterFilterCondition>
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

extension JiveCardRewardQueryObject
    on QueryBuilder<JiveCardReward, JiveCardReward, QFilterCondition> {}

extension JiveCardRewardQueryLinks
    on QueryBuilder<JiveCardReward, JiveCardReward, QFilterCondition> {}

extension JiveCardRewardQuerySortBy
    on QueryBuilder<JiveCardReward, JiveCardReward, QSortBy> {
  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByAccountName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountName', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByAccountNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountName', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByLastResetMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastResetMonth', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByLastResetMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastResetMonth', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByMonthEarned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthEarned', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByMonthEarnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthEarned', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByMonthlyCapAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyCapAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByMonthlyCapAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyCapAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByMonthlyRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyRemaining', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByMonthlyRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyRemaining', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByRewardRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardRate', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByRewardRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardRate', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByRewardType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardType', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByRewardTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardType', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByTotalEarned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEarned', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByTotalEarnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEarned', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveCardRewardQuerySortThenBy
    on QueryBuilder<JiveCardReward, JiveCardReward, QSortThenBy> {
  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByAccountName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountName', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByAccountNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountName', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByLastResetMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastResetMonth', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByLastResetMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastResetMonth', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByMonthEarned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthEarned', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByMonthEarnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthEarned', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByMonthlyCapAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyCapAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByMonthlyCapAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyCapAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByMonthlyRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyRemaining', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByMonthlyRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyRemaining', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByRewardRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardRate', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByRewardRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardRate', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByRewardType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardType', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByRewardTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardType', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByTotalEarned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEarned', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByTotalEarnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEarned', Sort.desc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveCardRewardQueryWhereDistinct
    on QueryBuilder<JiveCardReward, JiveCardReward, QDistinct> {
  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct> distinctByAccountName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByLastResetMonth({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastResetMonth',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByMonthEarned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthEarned');
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByMonthlyCapAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlyCapAmount');
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByMonthlyRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlyRemaining');
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByRewardRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardRate');
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct> distinctByRewardType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByTotalEarned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalEarned');
    });
  }

  QueryBuilder<JiveCardReward, JiveCardReward, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveCardRewardQueryProperty
    on QueryBuilder<JiveCardReward, JiveCardReward, QQueryProperty> {
  QueryBuilder<JiveCardReward, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveCardReward, int, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveCardReward, String, QQueryOperations> accountNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountName');
    });
  }

  QueryBuilder<JiveCardReward, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveCardReward, bool, QQueryOperations> isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<JiveCardReward, String, QQueryOperations>
      lastResetMonthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastResetMonth');
    });
  }

  QueryBuilder<JiveCardReward, double, QQueryOperations> monthEarnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthEarned');
    });
  }

  QueryBuilder<JiveCardReward, double?, QQueryOperations>
      monthlyCapAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlyCapAmount');
    });
  }

  QueryBuilder<JiveCardReward, double, QQueryOperations>
      monthlyRemainingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlyRemaining');
    });
  }

  QueryBuilder<JiveCardReward, double, QQueryOperations> rewardRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardRate');
    });
  }

  QueryBuilder<JiveCardReward, String, QQueryOperations> rewardTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardType');
    });
  }

  QueryBuilder<JiveCardReward, double, QQueryOperations> totalEarnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalEarned');
    });
  }

  QueryBuilder<JiveCardReward, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
