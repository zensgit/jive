// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveSecurityCollection on Isar {
  IsarCollection<JiveSecurity> get jiveSecuritys => this.collection();
}

const JiveSecuritySchema = CollectionSchema(
  name: r'JiveSecurity',
  id: -3712324358454317562,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currency': PropertySchema(
      id: 1,
      name: r'currency',
      type: IsarType.string,
    ),
    r'exchange': PropertySchema(
      id: 2,
      name: r'exchange',
      type: IsarType.string,
    ),
    r'latestPrice': PropertySchema(
      id: 3,
      name: r'latestPrice',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'priceUpdatedAt': PropertySchema(
      id: 5,
      name: r'priceUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'ticker': PropertySchema(
      id: 6,
      name: r'ticker',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 7,
      name: r'type',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveSecurityEstimateSize,
  serialize: _jiveSecuritySerialize,
  deserialize: _jiveSecurityDeserialize,
  deserializeProp: _jiveSecurityDeserializeProp,
  idName: r'id',
  indexes: {
    r'ticker': IndexSchema(
      id: -8264639257510259247,
      name: r'ticker',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ticker',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveSecurityGetId,
  getLinks: _jiveSecurityGetLinks,
  attach: _jiveSecurityAttach,
  version: '3.1.0+1',
);

int _jiveSecurityEstimateSize(
  JiveSecurity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.currency.length * 3;
  {
    final value = object.exchange;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.ticker.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _jiveSecuritySerialize(
  JiveSecurity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.currency);
  writer.writeString(offsets[2], object.exchange);
  writer.writeDouble(offsets[3], object.latestPrice);
  writer.writeString(offsets[4], object.name);
  writer.writeDateTime(offsets[5], object.priceUpdatedAt);
  writer.writeString(offsets[6], object.ticker);
  writer.writeString(offsets[7], object.type);
  writer.writeDateTime(offsets[8], object.updatedAt);
}

JiveSecurity _jiveSecurityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveSecurity();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.currency = reader.readString(offsets[1]);
  object.exchange = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.latestPrice = reader.readDoubleOrNull(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.priceUpdatedAt = reader.readDateTimeOrNull(offsets[5]);
  object.ticker = reader.readString(offsets[6]);
  object.type = reader.readString(offsets[7]);
  object.updatedAt = reader.readDateTime(offsets[8]);
  return object;
}

P _jiveSecurityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveSecurityGetId(JiveSecurity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveSecurityGetLinks(JiveSecurity object) {
  return [];
}

void _jiveSecurityAttach(
    IsarCollection<dynamic> col, Id id, JiveSecurity object) {
  object.id = id;
}

extension JiveSecurityByIndex on IsarCollection<JiveSecurity> {
  Future<JiveSecurity?> getByTicker(String ticker) {
    return getByIndex(r'ticker', [ticker]);
  }

  JiveSecurity? getByTickerSync(String ticker) {
    return getByIndexSync(r'ticker', [ticker]);
  }

  Future<bool> deleteByTicker(String ticker) {
    return deleteByIndex(r'ticker', [ticker]);
  }

  bool deleteByTickerSync(String ticker) {
    return deleteByIndexSync(r'ticker', [ticker]);
  }

  Future<List<JiveSecurity?>> getAllByTicker(List<String> tickerValues) {
    final values = tickerValues.map((e) => [e]).toList();
    return getAllByIndex(r'ticker', values);
  }

  List<JiveSecurity?> getAllByTickerSync(List<String> tickerValues) {
    final values = tickerValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'ticker', values);
  }

  Future<int> deleteAllByTicker(List<String> tickerValues) {
    final values = tickerValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'ticker', values);
  }

  int deleteAllByTickerSync(List<String> tickerValues) {
    final values = tickerValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'ticker', values);
  }

  Future<Id> putByTicker(JiveSecurity object) {
    return putByIndex(r'ticker', object);
  }

  Id putByTickerSync(JiveSecurity object, {bool saveLinks = true}) {
    return putByIndexSync(r'ticker', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTicker(List<JiveSecurity> objects) {
    return putAllByIndex(r'ticker', objects);
  }

  List<Id> putAllByTickerSync(List<JiveSecurity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ticker', objects, saveLinks: saveLinks);
  }
}

extension JiveSecurityQueryWhereSort
    on QueryBuilder<JiveSecurity, JiveSecurity, QWhere> {
  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveSecurityQueryWhere
    on QueryBuilder<JiveSecurity, JiveSecurity, QWhereClause> {
  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> tickerEqualTo(
      String ticker) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ticker',
        value: [ticker],
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> tickerNotEqualTo(
      String ticker) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker',
              lower: [],
              upper: [ticker],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker',
              lower: [ticker],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker',
              lower: [ticker],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker',
              lower: [],
              upper: [ticker],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> typeEqualTo(
      String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterWhereClause> typeNotEqualTo(
      String type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveSecurityQueryFilter
    on QueryBuilder<JiveSecurity, JiveSecurity, QFilterCondition> {
  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exchange',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exchange',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exchange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exchange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exchange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exchange',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exchange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exchange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exchange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exchange',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exchange',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      exchangeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exchange',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      latestPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latestPrice',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      latestPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latestPrice',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      latestPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      latestPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latestPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      latestPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latestPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      latestPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latestPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      priceUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'priceUpdatedAt',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      priceUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'priceUpdatedAt',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      priceUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      priceUpdatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priceUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      priceUpdatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priceUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      priceUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priceUpdatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> tickerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      tickerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      tickerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> tickerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ticker',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      tickerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      tickerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      tickerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> tickerMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ticker',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      tickerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticker',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      tickerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ticker',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> typeEqualTo(
    String value, {
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> typeLessThan(
    String value, {
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> typeEndsWith(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition> typeMatches(
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterFilterCondition>
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

extension JiveSecurityQueryObject
    on QueryBuilder<JiveSecurity, JiveSecurity, QFilterCondition> {}

extension JiveSecurityQueryLinks
    on QueryBuilder<JiveSecurity, JiveSecurity, QFilterCondition> {}

extension JiveSecurityQuerySortBy
    on QueryBuilder<JiveSecurity, JiveSecurity, QSortBy> {
  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByExchange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchange', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByExchangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchange', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByLatestPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestPrice', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy>
      sortByLatestPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestPrice', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy>
      sortByPriceUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy>
      sortByPriceUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByTicker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByTickerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveSecurityQuerySortThenBy
    on QueryBuilder<JiveSecurity, JiveSecurity, QSortThenBy> {
  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByExchange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchange', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByExchangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchange', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByLatestPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestPrice', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy>
      thenByLatestPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestPrice', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy>
      thenByPriceUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy>
      thenByPriceUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByTicker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByTickerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveSecurityQueryWhereDistinct
    on QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> {
  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> distinctByCurrency(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> distinctByExchange(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exchange', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> distinctByLatestPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latestPrice');
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct>
      distinctByPriceUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priceUpdatedAt');
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> distinctByTicker(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticker', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveSecurity, JiveSecurity, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveSecurityQueryProperty
    on QueryBuilder<JiveSecurity, JiveSecurity, QQueryProperty> {
  QueryBuilder<JiveSecurity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveSecurity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveSecurity, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<JiveSecurity, String?, QQueryOperations> exchangeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exchange');
    });
  }

  QueryBuilder<JiveSecurity, double?, QQueryOperations> latestPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestPrice');
    });
  }

  QueryBuilder<JiveSecurity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<JiveSecurity, DateTime?, QQueryOperations>
      priceUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priceUpdatedAt');
    });
  }

  QueryBuilder<JiveSecurity, String, QQueryOperations> tickerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticker');
    });
  }

  QueryBuilder<JiveSecurity, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<JiveSecurity, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveHoldingCollection on Isar {
  IsarCollection<JiveHolding> get jiveHoldings => this.collection();
}

const JiveHoldingSchema = CollectionSchema(
  name: r'JiveHolding',
  id: 1543354212382752758,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'costBasis': PropertySchema(
      id: 1,
      name: r'costBasis',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(
      id: 3,
      name: r'note',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 4,
      name: r'quantity',
      type: IsarType.double,
    ),
    r'securityId': PropertySchema(
      id: 5,
      name: r'securityId',
      type: IsarType.long,
    ),
    r'totalCost': PropertySchema(
      id: 6,
      name: r'totalCost',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveHoldingEstimateSize,
  serialize: _jiveHoldingSerialize,
  deserialize: _jiveHoldingDeserialize,
  deserializeProp: _jiveHoldingDeserializeProp,
  idName: r'id',
  indexes: {
    r'securityId': IndexSchema(
      id: 5704923243201981925,
      name: r'securityId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'securityId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveHoldingGetId,
  getLinks: _jiveHoldingGetLinks,
  attach: _jiveHoldingAttach,
  version: '3.1.0+1',
);

int _jiveHoldingEstimateSize(
  JiveHolding object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _jiveHoldingSerialize(
  JiveHolding object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeDouble(offsets[1], object.costBasis);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.note);
  writer.writeDouble(offsets[4], object.quantity);
  writer.writeLong(offsets[5], object.securityId);
  writer.writeDouble(offsets[6], object.totalCost);
  writer.writeDateTime(offsets[7], object.updatedAt);
}

JiveHolding _jiveHoldingDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveHolding();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.costBasis = reader.readDouble(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.note = reader.readStringOrNull(offsets[3]);
  object.quantity = reader.readDouble(offsets[4]);
  object.securityId = reader.readLong(offsets[5]);
  object.updatedAt = reader.readDateTime(offsets[7]);
  return object;
}

P _jiveHoldingDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveHoldingGetId(JiveHolding object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveHoldingGetLinks(JiveHolding object) {
  return [];
}

void _jiveHoldingAttach(
    IsarCollection<dynamic> col, Id id, JiveHolding object) {
  object.id = id;
}

extension JiveHoldingQueryWhereSort
    on QueryBuilder<JiveHolding, JiveHolding, QWhere> {
  QueryBuilder<JiveHolding, JiveHolding, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhere> anySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'securityId'),
      );
    });
  }
}

extension JiveHoldingQueryWhere
    on QueryBuilder<JiveHolding, JiveHolding, QWhereClause> {
  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause> securityIdEqualTo(
      int securityId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'securityId',
        value: [securityId],
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause>
      securityIdNotEqualTo(int securityId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [],
              upper: [securityId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [securityId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [securityId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [],
              upper: [securityId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause>
      securityIdGreaterThan(
    int securityId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [securityId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause> securityIdLessThan(
    int securityId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [],
        upper: [securityId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterWhereClause> securityIdBetween(
    int lowerSecurityId,
    int upperSecurityId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [lowerSecurityId],
        includeLower: includeLower,
        upper: [upperSecurityId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveHoldingQueryFilter
    on QueryBuilder<JiveHolding, JiveHolding, QFilterCondition> {
  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      accountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      costBasisEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'costBasis',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      costBasisGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'costBasis',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      costBasisLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'costBasis',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      costBasisBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'costBasis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> idBetween(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteEqualTo(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteGreaterThan(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteLessThan(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteBetween(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteStartsWith(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteEndsWith(
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> quantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      quantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      quantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition> quantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      securityIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      securityIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      securityIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      securityIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'securityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      totalCostEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      totalCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      totalCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      totalCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

  QueryBuilder<JiveHolding, JiveHolding, QAfterFilterCondition>
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

extension JiveHoldingQueryObject
    on QueryBuilder<JiveHolding, JiveHolding, QFilterCondition> {}

extension JiveHoldingQueryLinks
    on QueryBuilder<JiveHolding, JiveHolding, QFilterCondition> {}

extension JiveHoldingQuerySortBy
    on QueryBuilder<JiveHolding, JiveHolding, QSortBy> {
  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByCostBasis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costBasis', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByCostBasisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costBasis', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortBySecurityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByTotalCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveHoldingQuerySortThenBy
    on QueryBuilder<JiveHolding, JiveHolding, QSortThenBy> {
  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByCostBasis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costBasis', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByCostBasisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costBasis', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenBySecurityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByTotalCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.desc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveHoldingQueryWhereDistinct
    on QueryBuilder<JiveHolding, JiveHolding, QDistinct> {
  QueryBuilder<JiveHolding, JiveHolding, QDistinct> distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QDistinct> distinctByCostBasis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'costBasis');
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QDistinct> distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QDistinct> distinctBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'securityId');
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QDistinct> distinctByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCost');
    });
  }

  QueryBuilder<JiveHolding, JiveHolding, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveHoldingQueryProperty
    on QueryBuilder<JiveHolding, JiveHolding, QQueryProperty> {
  QueryBuilder<JiveHolding, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveHolding, int?, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveHolding, double, QQueryOperations> costBasisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'costBasis');
    });
  }

  QueryBuilder<JiveHolding, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveHolding, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<JiveHolding, double, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<JiveHolding, int, QQueryOperations> securityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'securityId');
    });
  }

  QueryBuilder<JiveHolding, double, QQueryOperations> totalCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCost');
    });
  }

  QueryBuilder<JiveHolding, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveInvestmentTransactionCollection on Isar {
  IsarCollection<JiveInvestmentTransaction> get jiveInvestmentTransactions =>
      this.collection();
}

const JiveInvestmentTransactionSchema = CollectionSchema(
  name: r'JiveInvestmentTransaction',
  id: -7323733868823870662,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'action': PropertySchema(
      id: 1,
      name: r'action',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'fee': PropertySchema(
      id: 3,
      name: r'fee',
      type: IsarType.double,
    ),
    r'holdingId': PropertySchema(
      id: 4,
      name: r'holdingId',
      type: IsarType.long,
    ),
    r'note': PropertySchema(
      id: 5,
      name: r'note',
      type: IsarType.string,
    ),
    r'price': PropertySchema(
      id: 6,
      name: r'price',
      type: IsarType.double,
    ),
    r'quantity': PropertySchema(
      id: 7,
      name: r'quantity',
      type: IsarType.double,
    ),
    r'securityId': PropertySchema(
      id: 8,
      name: r'securityId',
      type: IsarType.long,
    ),
    r'totalAmount': PropertySchema(
      id: 9,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'transactionDate': PropertySchema(
      id: 10,
      name: r'transactionDate',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveInvestmentTransactionEstimateSize,
  serialize: _jiveInvestmentTransactionSerialize,
  deserialize: _jiveInvestmentTransactionDeserialize,
  deserializeProp: _jiveInvestmentTransactionDeserializeProp,
  idName: r'id',
  indexes: {
    r'securityId': IndexSchema(
      id: 5704923243201981925,
      name: r'securityId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'securityId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'action': IndexSchema(
      id: -2948318935682215514,
      name: r'action',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'action',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveInvestmentTransactionGetId,
  getLinks: _jiveInvestmentTransactionGetLinks,
  attach: _jiveInvestmentTransactionAttach,
  version: '3.1.0+1',
);

int _jiveInvestmentTransactionEstimateSize(
  JiveInvestmentTransaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.action.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _jiveInvestmentTransactionSerialize(
  JiveInvestmentTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeString(offsets[1], object.action);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDouble(offsets[3], object.fee);
  writer.writeLong(offsets[4], object.holdingId);
  writer.writeString(offsets[5], object.note);
  writer.writeDouble(offsets[6], object.price);
  writer.writeDouble(offsets[7], object.quantity);
  writer.writeLong(offsets[8], object.securityId);
  writer.writeDouble(offsets[9], object.totalAmount);
  writer.writeDateTime(offsets[10], object.transactionDate);
}

JiveInvestmentTransaction _jiveInvestmentTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveInvestmentTransaction();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.action = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.fee = reader.readDouble(offsets[3]);
  object.holdingId = reader.readLongOrNull(offsets[4]);
  object.id = id;
  object.note = reader.readStringOrNull(offsets[5]);
  object.price = reader.readDouble(offsets[6]);
  object.quantity = reader.readDouble(offsets[7]);
  object.securityId = reader.readLong(offsets[8]);
  object.transactionDate = reader.readDateTime(offsets[10]);
  return object;
}

P _jiveInvestmentTransactionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveInvestmentTransactionGetId(JiveInvestmentTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveInvestmentTransactionGetLinks(
    JiveInvestmentTransaction object) {
  return [];
}

void _jiveInvestmentTransactionAttach(
    IsarCollection<dynamic> col, Id id, JiveInvestmentTransaction object) {
  object.id = id;
}

extension JiveInvestmentTransactionQueryWhereSort on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QWhere> {
  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhere> anySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'securityId'),
      );
    });
  }
}

extension JiveInvestmentTransactionQueryWhere on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QWhereClause> {
  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> securityIdEqualTo(int securityId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'securityId',
        value: [securityId],
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> securityIdNotEqualTo(int securityId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [],
              upper: [securityId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [securityId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [securityId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [],
              upper: [securityId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> securityIdGreaterThan(
    int securityId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [securityId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> securityIdLessThan(
    int securityId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [],
        upper: [securityId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> securityIdBetween(
    int lowerSecurityId,
    int upperSecurityId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [lowerSecurityId],
        includeLower: includeLower,
        upper: [upperSecurityId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> actionEqualTo(String action) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'action',
        value: [action],
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterWhereClause> actionNotEqualTo(String action) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'action',
              lower: [],
              upper: [action],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'action',
              lower: [action],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'action',
              lower: [action],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'action',
              lower: [],
              upper: [action],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveInvestmentTransactionQueryFilter on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QFilterCondition> {
  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> accountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> accountIdGreaterThan(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> accountIdLessThan(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> accountIdBetween(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> actionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> actionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> actionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> actionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'action',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> actionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> actionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
          QAfterFilterCondition>
      actionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
          QAfterFilterCondition>
      actionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'action',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> actionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'action',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> actionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'action',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> feeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> feeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> feeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> feeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fee',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> holdingIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'holdingId',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> holdingIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'holdingId',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> holdingIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'holdingId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> holdingIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'holdingId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> holdingIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'holdingId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> holdingIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'holdingId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteEqualTo(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteGreaterThan(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteLessThan(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteBetween(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteStartsWith(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteEndsWith(
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

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
          QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
          QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> quantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> quantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> quantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> quantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> securityIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> securityIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> securityIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> securityIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'securityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> totalAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> totalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> totalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> totalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> transactionDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> transactionDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transactionDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> transactionDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transactionDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterFilterCondition> transactionDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transactionDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveInvestmentTransactionQueryObject on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QFilterCondition> {}

extension JiveInvestmentTransactionQueryLinks on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QFilterCondition> {}

extension JiveInvestmentTransactionQuerySortBy on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QSortBy> {
  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByHoldingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'holdingId', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByHoldingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'holdingId', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortBySecurityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> sortByTransactionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.desc);
    });
  }
}

extension JiveInvestmentTransactionQuerySortThenBy on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QSortThenBy> {
  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByHoldingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'holdingId', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByHoldingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'holdingId', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenBySecurityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.asc);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction,
      QAfterSortBy> thenByTransactionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionDate', Sort.desc);
    });
  }
}

extension JiveInvestmentTransactionQueryWhereDistinct on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct> {
  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByAction({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'action', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fee');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByHoldingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'holdingId');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByNote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'securityId');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, JiveInvestmentTransaction, QDistinct>
      distinctByTransactionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionDate');
    });
  }
}

extension JiveInvestmentTransactionQueryProperty on QueryBuilder<
    JiveInvestmentTransaction, JiveInvestmentTransaction, QQueryProperty> {
  QueryBuilder<JiveInvestmentTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, int?, QQueryOperations>
      accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, String, QQueryOperations>
      actionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'action');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, double, QQueryOperations>
      feeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fee');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, int?, QQueryOperations>
      holdingIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'holdingId');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, String?, QQueryOperations>
      noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, double, QQueryOperations>
      priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, double, QQueryOperations>
      quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, int, QQueryOperations>
      securityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'securityId');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, double, QQueryOperations>
      totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<JiveInvestmentTransaction, DateTime, QQueryOperations>
      transactionDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionDate');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJivePriceHistoryCollection on Isar {
  IsarCollection<JivePriceHistory> get jivePriceHistorys => this.collection();
}

const JivePriceHistorySchema = CollectionSchema(
  name: r'JivePriceHistory',
  id: -7182933355361252625,
  properties: {
    r'closePrice': PropertySchema(
      id: 0,
      name: r'closePrice',
      type: IsarType.double,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'highPrice': PropertySchema(
      id: 2,
      name: r'highPrice',
      type: IsarType.double,
    ),
    r'lowPrice': PropertySchema(
      id: 3,
      name: r'lowPrice',
      type: IsarType.double,
    ),
    r'openPrice': PropertySchema(
      id: 4,
      name: r'openPrice',
      type: IsarType.double,
    ),
    r'securityId': PropertySchema(
      id: 5,
      name: r'securityId',
      type: IsarType.long,
    )
  },
  estimateSize: _jivePriceHistoryEstimateSize,
  serialize: _jivePriceHistorySerialize,
  deserialize: _jivePriceHistoryDeserialize,
  deserializeProp: _jivePriceHistoryDeserializeProp,
  idName: r'id',
  indexes: {
    r'securityId': IndexSchema(
      id: 5704923243201981925,
      name: r'securityId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'securityId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jivePriceHistoryGetId,
  getLinks: _jivePriceHistoryGetLinks,
  attach: _jivePriceHistoryAttach,
  version: '3.1.0+1',
);

int _jivePriceHistoryEstimateSize(
  JivePriceHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _jivePriceHistorySerialize(
  JivePriceHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.closePrice);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeDouble(offsets[2], object.highPrice);
  writer.writeDouble(offsets[3], object.lowPrice);
  writer.writeDouble(offsets[4], object.openPrice);
  writer.writeLong(offsets[5], object.securityId);
}

JivePriceHistory _jivePriceHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JivePriceHistory();
  object.closePrice = reader.readDouble(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.highPrice = reader.readDoubleOrNull(offsets[2]);
  object.id = id;
  object.lowPrice = reader.readDoubleOrNull(offsets[3]);
  object.openPrice = reader.readDoubleOrNull(offsets[4]);
  object.securityId = reader.readLong(offsets[5]);
  return object;
}

P _jivePriceHistoryDeserializeProp<P>(
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
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jivePriceHistoryGetId(JivePriceHistory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jivePriceHistoryGetLinks(JivePriceHistory object) {
  return [];
}

void _jivePriceHistoryAttach(
    IsarCollection<dynamic> col, Id id, JivePriceHistory object) {
  object.id = id;
}

extension JivePriceHistoryQueryWhereSort
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QWhere> {
  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhere>
      anySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'securityId'),
      );
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension JivePriceHistoryQueryWhere
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QWhereClause> {
  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
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

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause> idBetween(
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

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      securityIdEqualTo(int securityId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'securityId',
        value: [securityId],
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      securityIdNotEqualTo(int securityId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [],
              upper: [securityId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [securityId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [securityId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'securityId',
              lower: [],
              upper: [securityId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      securityIdGreaterThan(
    int securityId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [securityId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      securityIdLessThan(
    int securityId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [],
        upper: [securityId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      securityIdBetween(
    int lowerSecurityId,
    int upperSecurityId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'securityId',
        lower: [lowerSecurityId],
        includeLower: includeLower,
        upper: [upperSecurityId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      dateEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterWhereClause>
      dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JivePriceHistoryQueryFilter
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QFilterCondition> {
  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      closePriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      closePriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      closePriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      closePriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closePrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      highPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'highPrice',
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      highPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'highPrice',
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      highPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'highPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      highPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'highPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      highPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'highPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      highPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'highPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
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

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
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

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
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

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      lowPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lowPrice',
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      lowPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lowPrice',
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      lowPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lowPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      lowPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lowPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      lowPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lowPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      lowPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lowPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      openPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'openPrice',
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      openPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'openPrice',
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      openPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      openPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      openPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      openPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      securityIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      securityIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      securityIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'securityId',
        value: value,
      ));
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterFilterCondition>
      securityIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'securityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JivePriceHistoryQueryObject
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QFilterCondition> {}

extension JivePriceHistoryQueryLinks
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QFilterCondition> {}

extension JivePriceHistoryQuerySortBy
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QSortBy> {
  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByClosePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closePrice', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByClosePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closePrice', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByHighPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highPrice', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByHighPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highPrice', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByLowPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lowPrice', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByLowPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lowPrice', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByOpenPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openPrice', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortByOpenPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openPrice', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      sortBySecurityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.desc);
    });
  }
}

extension JivePriceHistoryQuerySortThenBy
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QSortThenBy> {
  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByClosePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closePrice', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByClosePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closePrice', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByHighPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highPrice', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByHighPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highPrice', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByLowPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lowPrice', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByLowPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lowPrice', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByOpenPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openPrice', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenByOpenPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openPrice', Sort.desc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.asc);
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QAfterSortBy>
      thenBySecurityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityId', Sort.desc);
    });
  }
}

extension JivePriceHistoryQueryWhereDistinct
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QDistinct> {
  QueryBuilder<JivePriceHistory, JivePriceHistory, QDistinct>
      distinctByClosePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closePrice');
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QDistinct>
      distinctByHighPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'highPrice');
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QDistinct>
      distinctByLowPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lowPrice');
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QDistinct>
      distinctByOpenPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openPrice');
    });
  }

  QueryBuilder<JivePriceHistory, JivePriceHistory, QDistinct>
      distinctBySecurityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'securityId');
    });
  }
}

extension JivePriceHistoryQueryProperty
    on QueryBuilder<JivePriceHistory, JivePriceHistory, QQueryProperty> {
  QueryBuilder<JivePriceHistory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JivePriceHistory, double, QQueryOperations>
      closePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closePrice');
    });
  }

  QueryBuilder<JivePriceHistory, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<JivePriceHistory, double?, QQueryOperations>
      highPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'highPrice');
    });
  }

  QueryBuilder<JivePriceHistory, double?, QQueryOperations> lowPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lowPrice');
    });
  }

  QueryBuilder<JivePriceHistory, double?, QQueryOperations>
      openPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openPrice');
    });
  }

  QueryBuilder<JivePriceHistory, int, QQueryOperations> securityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'securityId');
    });
  }
}
