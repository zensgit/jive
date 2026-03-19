// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveTransactionCollection on Isar {
  IsarCollection<JiveTransaction> get jiveTransactions => this.collection();
}

const JiveTransactionSchema = CollectionSchema(
  name: r'JiveTransaction',
  id: 6867470903591428996,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'amount': PropertySchema(id: 1, name: r'amount', type: IsarType.double),
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
    r'exchangeFee': PropertySchema(
      id: 4,
      name: r'exchangeFee',
      type: IsarType.double,
    ),
    r'exchangeFeeType': PropertySchema(
      id: 5,
      name: r'exchangeFeeType',
      type: IsarType.string,
    ),
    r'exchangeRate': PropertySchema(
      id: 6,
      name: r'exchangeRate',
      type: IsarType.double,
    ),
    r'excludeFromBudget': PropertySchema(
      id: 7,
      name: r'excludeFromBudget',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(id: 8, name: r'note', type: IsarType.string),
    r'projectId': PropertySchema(
      id: 9,
      name: r'projectId',
      type: IsarType.long,
    ),
    r'rawText': PropertySchema(id: 10, name: r'rawText', type: IsarType.string),
    r'recurringKey': PropertySchema(
      id: 11,
      name: r'recurringKey',
      type: IsarType.string,
    ),
    r'recurringRuleId': PropertySchema(
      id: 12,
      name: r'recurringRuleId',
      type: IsarType.long,
    ),
    r'smartTagKeys': PropertySchema(
      id: 13,
      name: r'smartTagKeys',
      type: IsarType.stringList,
    ),
    r'smartTagOptOutAll': PropertySchema(
      id: 14,
      name: r'smartTagOptOutAll',
      type: IsarType.bool,
    ),
    r'smartTagOptOutKeys': PropertySchema(
      id: 15,
      name: r'smartTagOptOutKeys',
      type: IsarType.stringList,
    ),
    r'source': PropertySchema(id: 16, name: r'source', type: IsarType.string),
    r'subCategory': PropertySchema(
      id: 17,
      name: r'subCategory',
      type: IsarType.string,
    ),
    r'subCategoryKey': PropertySchema(
      id: 18,
      name: r'subCategoryKey',
      type: IsarType.string,
    ),
    r'tagKeys': PropertySchema(
      id: 19,
      name: r'tagKeys',
      type: IsarType.stringList,
    ),
    r'timestamp': PropertySchema(
      id: 20,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'toAccountId': PropertySchema(
      id: 21,
      name: r'toAccountId',
      type: IsarType.long,
    ),
    r'toAmount': PropertySchema(
      id: 22,
      name: r'toAmount',
      type: IsarType.double,
    ),
    r'type': PropertySchema(id: 23, name: r'type', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 24,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _jiveTransactionEstimateSize,
  serialize: _jiveTransactionSerialize,
  deserialize: _jiveTransactionDeserialize,
  deserializeProp: _jiveTransactionDeserializeProp,
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
        ),
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
        ),
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
        ),
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
        ),
      ],
    ),
    r'toAccountId': IndexSchema(
      id: 1956423193434608400,
      name: r'toAccountId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'toAccountId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'projectId': IndexSchema(
      id: 3305656282123791113,
      name: r'projectId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectId',
          type: IndexType.value,
          caseSensitive: false,
        ),
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
        ),
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
        ),
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveTransactionGetId,
  getLinks: _jiveTransactionGetLinks,
  attach: _jiveTransactionAttach,
  version: '3.1.0+1',
);

int _jiveTransactionEstimateSize(
  JiveTransaction object,
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
    final value = object.exchangeFeeType;
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
  bytesCount += 3 + object.smartTagKeys.length * 3;
  {
    for (var i = 0; i < object.smartTagKeys.length; i++) {
      final value = object.smartTagKeys[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.smartTagOptOutKeys.length * 3;
  {
    for (var i = 0; i < object.smartTagOptOutKeys.length; i++) {
      final value = object.smartTagOptOutKeys[i];
      bytesCount += value.length * 3;
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

void _jiveTransactionSerialize(
  JiveTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeString(offsets[2], object.category);
  writer.writeString(offsets[3], object.categoryKey);
  writer.writeDouble(offsets[4], object.exchangeFee);
  writer.writeString(offsets[5], object.exchangeFeeType);
  writer.writeDouble(offsets[6], object.exchangeRate);
  writer.writeBool(offsets[7], object.excludeFromBudget);
  writer.writeString(offsets[8], object.note);
  writer.writeLong(offsets[9], object.projectId);
  writer.writeString(offsets[10], object.rawText);
  writer.writeString(offsets[11], object.recurringKey);
  writer.writeLong(offsets[12], object.recurringRuleId);
  writer.writeStringList(offsets[13], object.smartTagKeys);
  writer.writeBool(offsets[14], object.smartTagOptOutAll);
  writer.writeStringList(offsets[15], object.smartTagOptOutKeys);
  writer.writeString(offsets[16], object.source);
  writer.writeString(offsets[17], object.subCategory);
  writer.writeString(offsets[18], object.subCategoryKey);
  writer.writeStringList(offsets[19], object.tagKeys);
  writer.writeDateTime(offsets[20], object.timestamp);
  writer.writeLong(offsets[21], object.toAccountId);
  writer.writeDouble(offsets[22], object.toAmount);
  writer.writeString(offsets[23], object.type);
  writer.writeDateTime(offsets[24], object.updatedAt);
}

JiveTransaction _jiveTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveTransaction();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.amount = reader.readDouble(offsets[1]);
  object.category = reader.readStringOrNull(offsets[2]);
  object.categoryKey = reader.readStringOrNull(offsets[3]);
  object.exchangeFee = reader.readDoubleOrNull(offsets[4]);
  object.exchangeFeeType = reader.readStringOrNull(offsets[5]);
  object.exchangeRate = reader.readDoubleOrNull(offsets[6]);
  object.excludeFromBudget = reader.readBool(offsets[7]);
  object.id = id;
  object.note = reader.readStringOrNull(offsets[8]);
  object.projectId = reader.readLongOrNull(offsets[9]);
  object.rawText = reader.readStringOrNull(offsets[10]);
  object.recurringKey = reader.readStringOrNull(offsets[11]);
  object.recurringRuleId = reader.readLongOrNull(offsets[12]);
  object.smartTagKeys = reader.readStringList(offsets[13]) ?? [];
  object.smartTagOptOutAll = reader.readBool(offsets[14]);
  object.smartTagOptOutKeys = reader.readStringList(offsets[15]) ?? [];
  object.source = reader.readString(offsets[16]);
  object.subCategory = reader.readStringOrNull(offsets[17]);
  object.subCategoryKey = reader.readStringOrNull(offsets[18]);
  object.tagKeys = reader.readStringList(offsets[19]) ?? [];
  object.timestamp = reader.readDateTime(offsets[20]);
  object.toAccountId = reader.readLongOrNull(offsets[21]);
  object.toAmount = reader.readDoubleOrNull(offsets[22]);
  object.type = reader.readStringOrNull(offsets[23]);
  object.updatedAt = reader.readDateTime(offsets[24]);
  return object;
}

P _jiveTransactionDeserializeProp<P>(
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
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readStringList(offset) ?? []) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readStringList(offset) ?? []) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringList(offset) ?? []) as P;
    case 20:
      return (reader.readDateTime(offset)) as P;
    case 21:
      return (reader.readLongOrNull(offset)) as P;
    case 22:
      return (reader.readDoubleOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveTransactionGetId(JiveTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveTransactionGetLinks(JiveTransaction object) {
  return [];
}

void _jiveTransactionAttach(
  IsarCollection<dynamic> col,
  Id id,
  JiveTransaction object,
) {
  object.id = id;
}

extension JiveTransactionQueryWhereSort
    on QueryBuilder<JiveTransaction, JiveTransaction, QWhere> {
  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhere> anyAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'accountId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhere> anyToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'toAccountId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhere> anyProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'projectId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhere>
  anyRecurringRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'recurringRuleId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension JiveTransactionQueryWhere
    on QueryBuilder<JiveTransaction, JiveTransaction, QWhereClause> {
  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
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

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'timestamp', value: [timestamp]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'timestamp',
                lower: [],
                upper: [timestamp],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'timestamp',
                lower: [timestamp],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'timestamp',
                lower: [timestamp],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'timestamp',
                lower: [],
                upper: [timestamp],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  timestampGreaterThan(DateTime timestamp, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'timestamp',
          lower: [timestamp],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  timestampLessThan(DateTime timestamp, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'timestamp',
          lower: [],
          upper: [timestamp],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'timestamp',
          lower: [lowerTimestamp],
          includeLower: includeLower,
          upper: [upperTimestamp],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  categoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'categoryKey', value: [null]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  categoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'categoryKey',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  categoryKeyEqualTo(String? categoryKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'categoryKey',
          value: [categoryKey],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  categoryKeyNotEqualTo(String? categoryKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'categoryKey',
                lower: [],
                upper: [categoryKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'categoryKey',
                lower: [categoryKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'categoryKey',
                lower: [categoryKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'categoryKey',
                lower: [],
                upper: [categoryKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  subCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'subCategoryKey', value: [null]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  subCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'subCategoryKey',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  subCategoryKeyEqualTo(String? subCategoryKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'subCategoryKey',
          value: [subCategoryKey],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  subCategoryKeyNotEqualTo(String? subCategoryKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subCategoryKey',
                lower: [],
                upper: [subCategoryKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subCategoryKey',
                lower: [subCategoryKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subCategoryKey',
                lower: [subCategoryKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'subCategoryKey',
                lower: [],
                upper: [subCategoryKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'accountId', value: [null]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'accountId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  accountIdEqualTo(int? accountId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'accountId', value: [accountId]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  accountIdNotEqualTo(int? accountId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'accountId',
                lower: [],
                upper: [accountId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'accountId',
                lower: [accountId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'accountId',
                lower: [accountId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'accountId',
                lower: [],
                upper: [accountId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  accountIdGreaterThan(int? accountId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'accountId',
          lower: [accountId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  accountIdLessThan(int? accountId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'accountId',
          lower: [],
          upper: [accountId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  accountIdBetween(
    int? lowerAccountId,
    int? upperAccountId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'accountId',
          lower: [lowerAccountId],
          includeLower: includeLower,
          upper: [upperAccountId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  toAccountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'toAccountId', value: [null]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  toAccountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'toAccountId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  toAccountIdEqualTo(int? toAccountId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'toAccountId',
          value: [toAccountId],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  toAccountIdNotEqualTo(int? toAccountId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'toAccountId',
                lower: [],
                upper: [toAccountId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'toAccountId',
                lower: [toAccountId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'toAccountId',
                lower: [toAccountId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'toAccountId',
                lower: [],
                upper: [toAccountId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  toAccountIdGreaterThan(int? toAccountId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'toAccountId',
          lower: [toAccountId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  toAccountIdLessThan(int? toAccountId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'toAccountId',
          lower: [],
          upper: [toAccountId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  toAccountIdBetween(
    int? lowerToAccountId,
    int? upperToAccountId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'toAccountId',
          lower: [lowerToAccountId],
          includeLower: includeLower,
          upper: [upperToAccountId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  projectIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'projectId', value: [null]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  projectIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  projectIdEqualTo(int? projectId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'projectId', value: [projectId]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  projectIdNotEqualTo(int? projectId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectId',
                lower: [],
                upper: [projectId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectId',
                lower: [projectId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectId',
                lower: [projectId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectId',
                lower: [],
                upper: [projectId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  projectIdGreaterThan(int? projectId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectId',
          lower: [projectId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  projectIdLessThan(int? projectId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectId',
          lower: [],
          upper: [projectId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  projectIdBetween(
    int? lowerProjectId,
    int? upperProjectId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectId',
          lower: [lowerProjectId],
          includeLower: includeLower,
          upper: [upperProjectId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringRuleIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'recurringRuleId', value: [null]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringRuleIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'recurringRuleId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringRuleIdEqualTo(int? recurringRuleId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'recurringRuleId',
          value: [recurringRuleId],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringRuleIdNotEqualTo(int? recurringRuleId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'recurringRuleId',
                lower: [],
                upper: [recurringRuleId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'recurringRuleId',
                lower: [recurringRuleId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'recurringRuleId',
                lower: [recurringRuleId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'recurringRuleId',
                lower: [],
                upper: [recurringRuleId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringRuleIdGreaterThan(int? recurringRuleId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'recurringRuleId',
          lower: [recurringRuleId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringRuleIdLessThan(int? recurringRuleId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'recurringRuleId',
          lower: [],
          upper: [recurringRuleId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringRuleIdBetween(
    int? lowerRecurringRuleId,
    int? upperRecurringRuleId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'recurringRuleId',
          lower: [lowerRecurringRuleId],
          includeLower: includeLower,
          upper: [upperRecurringRuleId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'recurringKey', value: [null]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'recurringKey',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringKeyEqualTo(String? recurringKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'recurringKey',
          value: [recurringKey],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  recurringKeyNotEqualTo(String? recurringKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'recurringKey',
                lower: [],
                upper: [recurringKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'recurringKey',
                lower: [recurringKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'recurringKey',
                lower: [recurringKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'recurringKey',
                lower: [],
                upper: [recurringKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'updatedAt', value: [updatedAt]),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  updatedAtGreaterThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [updatedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  updatedAtLessThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [],
          upper: [updatedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterWhereClause>
  updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [lowerUpdatedAt],
          includeLower: includeLower,
          upper: [upperUpdatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension JiveTransactionQueryFilter
    on QueryBuilder<JiveTransaction, JiveTransaction, QFilterCondition> {
  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'accountId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'accountId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  accountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'accountId', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  accountIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'accountId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  accountIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'accountId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  accountIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'accountId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  amountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'amount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'category'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'category'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'categoryKey'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'categoryKey'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'categoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'categoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'categoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'categoryKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'categoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'categoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'categoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'categoryKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'categoryKey', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  categoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'categoryKey', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'exchangeFee'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'exchangeFee'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'exchangeFee',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'exchangeFee',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'exchangeFee',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'exchangeFee',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'exchangeFeeType'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'exchangeFeeType'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'exchangeFeeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'exchangeFeeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'exchangeFeeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'exchangeFeeType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'exchangeFeeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'exchangeFeeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'exchangeFeeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'exchangeFeeType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'exchangeFeeType', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeFeeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'exchangeFeeType', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'exchangeRate'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'exchangeRate'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeRateEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'exchangeRate',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeRateGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'exchangeRate',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeRateLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'exchangeRate',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  exchangeRateBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'exchangeRate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  excludeFromBudgetEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'excludeFromBudget', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  projectIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'projectId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  projectIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'projectId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  projectIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'projectId', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  projectIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'projectId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  projectIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'projectId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  projectIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'projectId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rawText'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rawText'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawText', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  rawTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawText', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'recurringKey'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'recurringKey'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'recurringKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recurringKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'recurringKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recurringKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'recurringKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'recurringKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'recurringKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'recurringKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recurringKey', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'recurringKey', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringRuleIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'recurringRuleId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringRuleIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'recurringRuleId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringRuleIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recurringRuleId', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringRuleIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recurringRuleId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringRuleIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'recurringRuleId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  recurringRuleIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recurringRuleId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'smartTagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'smartTagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'smartTagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'smartTagKeys',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'smartTagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'smartTagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'smartTagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'smartTagKeys',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'smartTagKeys', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'smartTagKeys', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'smartTagKeys', length, true, length, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'smartTagKeys', 0, true, 0, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'smartTagKeys', 0, false, 999999, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'smartTagKeys', 0, true, length, include);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'smartTagKeys', length, include, 999999, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagKeysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'smartTagKeys',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutAllEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'smartTagOptOutAll', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'smartTagOptOutKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'smartTagOptOutKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'smartTagOptOutKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'smartTagOptOutKeys',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'smartTagOptOutKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'smartTagOptOutKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'smartTagOptOutKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'smartTagOptOutKeys',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'smartTagOptOutKeys', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'smartTagOptOutKeys', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'smartTagOptOutKeys',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'smartTagOptOutKeys', 0, true, 0, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'smartTagOptOutKeys', 0, false, 999999, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'smartTagOptOutKeys', 0, true, length, include);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'smartTagOptOutKeys',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  smartTagOptOutKeysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'smartTagOptOutKeys',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'subCategory'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'subCategory'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subCategory',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'subCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'subCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'subCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'subCategory',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'subCategory', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'subCategory', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'subCategoryKey'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'subCategoryKey'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subCategoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subCategoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subCategoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subCategoryKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'subCategoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'subCategoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'subCategoryKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'subCategoryKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'subCategoryKey', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  subCategoryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'subCategoryKey', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tagKeys',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tagKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tagKeys',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tagKeys', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tagKeys', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagKeys', length, true, length, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagKeys', 0, true, 0, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagKeys', 0, false, 999999, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagKeys', 0, true, length, include);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  tagKeysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagKeys', length, include, 999999, true);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
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

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  timestampLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAccountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'toAccountId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAccountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'toAccountId'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAccountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'toAccountId', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAccountIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'toAccountId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAccountIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'toAccountId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAccountIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'toAccountId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'toAmount'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'toAmount'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAmountEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'toAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'toAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'toAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  toAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'toAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'type'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'type'),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension JiveTransactionQueryObject
    on QueryBuilder<JiveTransaction, JiveTransaction, QFilterCondition> {}

extension JiveTransactionQueryLinks
    on QueryBuilder<JiveTransaction, JiveTransaction, QFilterCondition> {}

extension JiveTransactionQuerySortBy
    on QueryBuilder<JiveTransaction, JiveTransaction, QSortBy> {
  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByExchangeFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeFee', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByExchangeFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeFee', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByExchangeFeeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeFeeType', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByExchangeFeeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeFeeType', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByExchangeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRate', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByExchangeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRate', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByExcludeFromBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudget', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByExcludeFromBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudget', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> sortByRawText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByRawTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByRecurringKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByRecurringKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByRecurringRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringRuleId', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByRecurringRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringRuleId', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortBySmartTagOptOutAll() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smartTagOptOutAll', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortBySmartTagOptOutAllDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smartTagOptOutAll', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortBySubCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortBySubCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByToAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByToAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByToAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveTransactionQuerySortThenBy
    on QueryBuilder<JiveTransaction, JiveTransaction, QSortThenBy> {
  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByExchangeFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeFee', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByExchangeFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeFee', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByExchangeFeeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeFeeType', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByExchangeFeeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeFeeType', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByExchangeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRate', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByExchangeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRate', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByExcludeFromBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudget', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByExcludeFromBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludeFromBudget', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> thenByRawText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByRawTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByRecurringKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByRecurringKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByRecurringRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringRuleId', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByRecurringRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurringRuleId', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenBySmartTagOptOutAll() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smartTagOptOutAll', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenBySmartTagOptOutAllDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smartTagOptOutAll', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenBySubCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenBySubCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenBySubCategoryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenBySubCategoryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategoryKey', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByToAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccountId', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByToAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByToAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveTransactionQueryWhereDistinct
    on QueryBuilder<JiveTransaction, JiveTransaction, QDistinct> {
  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct> distinctByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByExchangeFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exchangeFee');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByExchangeFeeType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'exchangeFeeType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByExchangeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exchangeRate');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByExcludeFromBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'excludeFromBudget');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectId');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct> distinctByRawText({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByRecurringKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurringKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByRecurringRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurringRuleId');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctBySmartTagKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'smartTagKeys');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctBySmartTagOptOutAll() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'smartTagOptOutAll');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctBySmartTagOptOutKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'smartTagOptOutKeys');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct> distinctBySource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctBySubCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCategory', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctBySubCategoryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'subCategoryKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByTagKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagKeys');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByToAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toAccountId');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByToAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toAmount');
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct> distinctByType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveTransaction, JiveTransaction, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveTransactionQueryProperty
    on QueryBuilder<JiveTransaction, JiveTransaction, QQueryProperty> {
  QueryBuilder<JiveTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveTransaction, int?, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveTransaction, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations>
  categoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryKey');
    });
  }

  QueryBuilder<JiveTransaction, double?, QQueryOperations>
  exchangeFeeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exchangeFee');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations>
  exchangeFeeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exchangeFeeType');
    });
  }

  QueryBuilder<JiveTransaction, double?, QQueryOperations>
  exchangeRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exchangeRate');
    });
  }

  QueryBuilder<JiveTransaction, bool, QQueryOperations>
  excludeFromBudgetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'excludeFromBudget');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<JiveTransaction, int?, QQueryOperations> projectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectId');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations> rawTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawText');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations>
  recurringKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurringKey');
    });
  }

  QueryBuilder<JiveTransaction, int?, QQueryOperations>
  recurringRuleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurringRuleId');
    });
  }

  QueryBuilder<JiveTransaction, List<String>, QQueryOperations>
  smartTagKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'smartTagKeys');
    });
  }

  QueryBuilder<JiveTransaction, bool, QQueryOperations>
  smartTagOptOutAllProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'smartTagOptOutAll');
    });
  }

  QueryBuilder<JiveTransaction, List<String>, QQueryOperations>
  smartTagOptOutKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'smartTagOptOutKeys');
    });
  }

  QueryBuilder<JiveTransaction, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations>
  subCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategory');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations>
  subCategoryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategoryKey');
    });
  }

  QueryBuilder<JiveTransaction, List<String>, QQueryOperations>
  tagKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagKeys');
    });
  }

  QueryBuilder<JiveTransaction, DateTime, QQueryOperations>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<JiveTransaction, int?, QQueryOperations> toAccountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toAccountId');
    });
  }

  QueryBuilder<JiveTransaction, double?, QQueryOperations> toAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toAmount');
    });
  }

  QueryBuilder<JiveTransaction, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<JiveTransaction, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
