// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_list_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveSmartListCollection on Isar {
  IsarCollection<JiveSmartList> get jiveSmartLists => this.collection();
}

const JiveSmartListSchema = CollectionSchema(
  name: r'JiveSmartList',
  id: 8387165906329876017,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'bookId': PropertySchema(
      id: 1,
      name: r'bookId',
      type: IsarType.long,
    ),
    r'categoryKeys': PropertySchema(
      id: 2,
      name: r'categoryKeys',
      type: IsarType.string,
    ),
    r'colorHex': PropertySchema(
      id: 3,
      name: r'colorHex',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'customEndDate': PropertySchema(
      id: 5,
      name: r'customEndDate',
      type: IsarType.dateTime,
    ),
    r'customStartDate': PropertySchema(
      id: 6,
      name: r'customStartDate',
      type: IsarType.dateTime,
    ),
    r'dateRangeType': PropertySchema(
      id: 7,
      name: r'dateRangeType',
      type: IsarType.string,
    ),
    r'iconName': PropertySchema(
      id: 8,
      name: r'iconName',
      type: IsarType.string,
    ),
    r'isPinned': PropertySchema(
      id: 9,
      name: r'isPinned',
      type: IsarType.bool,
    ),
    r'keyword': PropertySchema(
      id: 10,
      name: r'keyword',
      type: IsarType.string,
    ),
    r'maxAmount': PropertySchema(
      id: 11,
      name: r'maxAmount',
      type: IsarType.double,
    ),
    r'minAmount': PropertySchema(
      id: 12,
      name: r'minAmount',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 13,
      name: r'name',
      type: IsarType.string,
    ),
    r'sortOrder': PropertySchema(
      id: 14,
      name: r'sortOrder',
      type: IsarType.long,
    ),
    r'tagKeys': PropertySchema(
      id: 15,
      name: r'tagKeys',
      type: IsarType.string,
    ),
    r'transactionType': PropertySchema(
      id: 16,
      name: r'transactionType',
      type: IsarType.string,
    )
  },
  estimateSize: _jiveSmartListEstimateSize,
  serialize: _jiveSmartListSerialize,
  deserialize: _jiveSmartListDeserialize,
  deserializeProp: _jiveSmartListDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _jiveSmartListGetId,
  getLinks: _jiveSmartListGetLinks,
  attach: _jiveSmartListAttach,
  version: '3.1.0+1',
);

int _jiveSmartListEstimateSize(
  JiveSmartList object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.categoryKeys;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.colorHex;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dateRangeType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.iconName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.keyword;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.tagKeys;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.transactionType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _jiveSmartListSerialize(
  JiveSmartList object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeLong(offsets[1], object.bookId);
  writer.writeString(offsets[2], object.categoryKeys);
  writer.writeString(offsets[3], object.colorHex);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeDateTime(offsets[5], object.customEndDate);
  writer.writeDateTime(offsets[6], object.customStartDate);
  writer.writeString(offsets[7], object.dateRangeType);
  writer.writeString(offsets[8], object.iconName);
  writer.writeBool(offsets[9], object.isPinned);
  writer.writeString(offsets[10], object.keyword);
  writer.writeDouble(offsets[11], object.maxAmount);
  writer.writeDouble(offsets[12], object.minAmount);
  writer.writeString(offsets[13], object.name);
  writer.writeLong(offsets[14], object.sortOrder);
  writer.writeString(offsets[15], object.tagKeys);
  writer.writeString(offsets[16], object.transactionType);
}

JiveSmartList _jiveSmartListDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveSmartList();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.bookId = reader.readLongOrNull(offsets[1]);
  object.categoryKeys = reader.readStringOrNull(offsets[2]);
  object.colorHex = reader.readStringOrNull(offsets[3]);
  object.createdAt = reader.readDateTime(offsets[4]);
  object.customEndDate = reader.readDateTimeOrNull(offsets[5]);
  object.customStartDate = reader.readDateTimeOrNull(offsets[6]);
  object.dateRangeType = reader.readStringOrNull(offsets[7]);
  object.iconName = reader.readStringOrNull(offsets[8]);
  object.id = id;
  object.isPinned = reader.readBool(offsets[9]);
  object.keyword = reader.readStringOrNull(offsets[10]);
  object.maxAmount = reader.readDoubleOrNull(offsets[11]);
  object.minAmount = reader.readDoubleOrNull(offsets[12]);
  object.name = reader.readString(offsets[13]);
  object.sortOrder = reader.readLong(offsets[14]);
  object.tagKeys = reader.readStringOrNull(offsets[15]);
  object.transactionType = reader.readStringOrNull(offsets[16]);
  return object;
}

P _jiveSmartListDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveSmartListGetId(JiveSmartList object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveSmartListGetLinks(JiveSmartList object) {
  return [];
}

void _jiveSmartListAttach(
    IsarCollection<dynamic> col, Id id, JiveSmartList object) {
  object.id = id;
}

extension JiveSmartListQueryWhereSort
    on QueryBuilder<JiveSmartList, JiveSmartList, QWhere> {
  QueryBuilder<JiveSmartList, JiveSmartList, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveSmartListQueryWhere
    on QueryBuilder<JiveSmartList, JiveSmartList, QWhereClause> {
  QueryBuilder<JiveSmartList, JiveSmartList, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterWhereClause> idBetween(
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
}

extension JiveSmartListQueryFilter
    on QueryBuilder<JiveSmartList, JiveSmartList, QFilterCondition> {
  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      accountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      bookIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bookId',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      bookIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bookId',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      bookIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      bookIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      bookIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      bookIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryKeys',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryKeys',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryKeys',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryKeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      categoryKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorHex',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorHex',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorHex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorHex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      colorHexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customEndDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customEndDate',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customEndDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customEndDate',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customEndDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customEndDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customEndDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customEndDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customEndDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customStartDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customStartDate',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customStartDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customStartDate',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customStartDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customStartDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customStartDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      customStartDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customStartDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dateRangeType',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dateRangeType',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateRangeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateRangeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateRangeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateRangeType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateRangeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateRangeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateRangeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateRangeType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateRangeType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      dateRangeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateRangeType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'iconName',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'iconName',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iconName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'iconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'iconName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      iconNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'iconName',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition> idBetween(
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      isPinnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPinned',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'keyword',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'keyword',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keyword',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keyword',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyword',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      keywordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keyword',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      maxAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'maxAmount',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      maxAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'maxAmount',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      maxAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      maxAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      maxAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      maxAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      minAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'minAmount',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      minAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'minAmount',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      minAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      minAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      minAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      minAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      sortOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      sortOrderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      sortOrderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      sortOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sortOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tagKeys',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tagKeys',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysEqualTo(
    String? value, {
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysGreaterThan(
    String? value, {
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysLessThan(
    String? value, {
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysStartsWith(
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysEndsWith(
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

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagKeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      tagKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transactionType',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transactionType',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transactionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transactionType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionType',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterFilterCondition>
      transactionTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transactionType',
        value: '',
      ));
    });
  }
}

extension JiveSmartListQueryObject
    on QueryBuilder<JiveSmartList, JiveSmartList, QFilterCondition> {}

extension JiveSmartListQueryLinks
    on QueryBuilder<JiveSmartList, JiveSmartList, QFilterCondition> {}

extension JiveSmartListQuerySortBy
    on QueryBuilder<JiveSmartList, JiveSmartList, QSortBy> {
  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByCategoryKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKeys', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByCategoryKeysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKeys', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByCustomEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customEndDate', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByCustomEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customEndDate', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByCustomStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customStartDate', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByCustomStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customStartDate', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByDateRangeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateRangeType', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByDateRangeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateRangeType', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByIconName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByIconNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByKeyword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByKeywordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByMaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByMaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByMinAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByMinAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByTagKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagKeys', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> sortByTagKeysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagKeys', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      sortByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }
}

extension JiveSmartListQuerySortThenBy
    on QueryBuilder<JiveSmartList, JiveSmartList, QSortThenBy> {
  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByCategoryKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKeys', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByCategoryKeysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryKeys', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByCustomEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customEndDate', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByCustomEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customEndDate', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByCustomStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customStartDate', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByCustomStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customStartDate', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByDateRangeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateRangeType', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByDateRangeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateRangeType', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByIconName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByIconNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconName', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByKeyword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByKeywordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByMaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByMaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByMinAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByMinAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByTagKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagKeys', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy> thenByTagKeysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagKeys', Sort.desc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QAfterSortBy>
      thenByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }
}

extension JiveSmartListQueryWhereDistinct
    on QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> {
  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookId');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByCategoryKeys(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryKeys', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByColorHex(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorHex', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct>
      distinctByCustomEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customEndDate');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct>
      distinctByCustomStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customStartDate');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByDateRangeType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateRangeType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByIconName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByKeyword(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keyword', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByMaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxAmount');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByMinAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minAmount');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortOrder');
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct> distinctByTagKeys(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagKeys', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSmartList, JiveSmartList, QDistinct>
      distinctByTransactionType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionType',
          caseSensitive: caseSensitive);
    });
  }
}

extension JiveSmartListQueryProperty
    on QueryBuilder<JiveSmartList, JiveSmartList, QQueryProperty> {
  QueryBuilder<JiveSmartList, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveSmartList, int?, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveSmartList, int?, QQueryOperations> bookIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookId');
    });
  }

  QueryBuilder<JiveSmartList, String?, QQueryOperations>
      categoryKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryKeys');
    });
  }

  QueryBuilder<JiveSmartList, String?, QQueryOperations> colorHexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorHex');
    });
  }

  QueryBuilder<JiveSmartList, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveSmartList, DateTime?, QQueryOperations>
      customEndDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customEndDate');
    });
  }

  QueryBuilder<JiveSmartList, DateTime?, QQueryOperations>
      customStartDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customStartDate');
    });
  }

  QueryBuilder<JiveSmartList, String?, QQueryOperations>
      dateRangeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateRangeType');
    });
  }

  QueryBuilder<JiveSmartList, String?, QQueryOperations> iconNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconName');
    });
  }

  QueryBuilder<JiveSmartList, bool, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<JiveSmartList, String?, QQueryOperations> keywordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyword');
    });
  }

  QueryBuilder<JiveSmartList, double?, QQueryOperations> maxAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxAmount');
    });
  }

  QueryBuilder<JiveSmartList, double?, QQueryOperations> minAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minAmount');
    });
  }

  QueryBuilder<JiveSmartList, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<JiveSmartList, int, QQueryOperations> sortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortOrder');
    });
  }

  QueryBuilder<JiveSmartList, String?, QQueryOperations> tagKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagKeys');
    });
  }

  QueryBuilder<JiveSmartList, String?, QQueryOperations>
      transactionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionType');
    });
  }
}
