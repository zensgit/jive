// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveCurrencyCollection on Isar {
  IsarCollection<JiveCurrency> get jiveCurrencys => this.collection();
}

const JiveCurrencySchema = CollectionSchema(
  name: r'JiveCurrency',
  id: 3583133943899120433,
  properties: {
    r'code': PropertySchema(
      id: 0,
      name: r'code',
      type: IsarType.string,
    ),
    r'decimalPlaces': PropertySchema(
      id: 1,
      name: r'decimalPlaces',
      type: IsarType.long,
    ),
    r'flag': PropertySchema(
      id: 2,
      name: r'flag',
      type: IsarType.string,
    ),
    r'isCrypto': PropertySchema(
      id: 3,
      name: r'isCrypto',
      type: IsarType.bool,
    ),
    r'isEnabled': PropertySchema(
      id: 4,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'nameZh': PropertySchema(
      id: 6,
      name: r'nameZh',
      type: IsarType.string,
    ),
    r'sortOrder': PropertySchema(
      id: 7,
      name: r'sortOrder',
      type: IsarType.long,
    ),
    r'symbol': PropertySchema(
      id: 8,
      name: r'symbol',
      type: IsarType.string,
    )
  },
  estimateSize: _jiveCurrencyEstimateSize,
  serialize: _jiveCurrencySerialize,
  deserialize: _jiveCurrencyDeserialize,
  deserializeProp: _jiveCurrencyDeserializeProp,
  idName: r'id',
  indexes: {
    r'code': IndexSchema(
      id: 329780482934683790,
      name: r'code',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'code',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveCurrencyGetId,
  getLinks: _jiveCurrencyGetLinks,
  attach: _jiveCurrencyAttach,
  version: '3.1.0+1',
);

int _jiveCurrencyEstimateSize(
  JiveCurrency object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.code.length * 3;
  {
    final value = object.flag;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.nameZh.length * 3;
  bytesCount += 3 + object.symbol.length * 3;
  return bytesCount;
}

void _jiveCurrencySerialize(
  JiveCurrency object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.code);
  writer.writeLong(offsets[1], object.decimalPlaces);
  writer.writeString(offsets[2], object.flag);
  writer.writeBool(offsets[3], object.isCrypto);
  writer.writeBool(offsets[4], object.isEnabled);
  writer.writeString(offsets[5], object.name);
  writer.writeString(offsets[6], object.nameZh);
  writer.writeLong(offsets[7], object.sortOrder);
  writer.writeString(offsets[8], object.symbol);
}

JiveCurrency _jiveCurrencyDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveCurrency();
  object.code = reader.readString(offsets[0]);
  object.decimalPlaces = reader.readLong(offsets[1]);
  object.flag = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.isCrypto = reader.readBool(offsets[3]);
  object.isEnabled = reader.readBool(offsets[4]);
  object.name = reader.readString(offsets[5]);
  object.nameZh = reader.readString(offsets[6]);
  object.sortOrder = reader.readLong(offsets[7]);
  object.symbol = reader.readString(offsets[8]);
  return object;
}

P _jiveCurrencyDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveCurrencyGetId(JiveCurrency object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveCurrencyGetLinks(JiveCurrency object) {
  return [];
}

void _jiveCurrencyAttach(
    IsarCollection<dynamic> col, Id id, JiveCurrency object) {
  object.id = id;
}

extension JiveCurrencyByIndex on IsarCollection<JiveCurrency> {
  Future<JiveCurrency?> getByCode(String code) {
    return getByIndex(r'code', [code]);
  }

  JiveCurrency? getByCodeSync(String code) {
    return getByIndexSync(r'code', [code]);
  }

  Future<bool> deleteByCode(String code) {
    return deleteByIndex(r'code', [code]);
  }

  bool deleteByCodeSync(String code) {
    return deleteByIndexSync(r'code', [code]);
  }

  Future<List<JiveCurrency?>> getAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndex(r'code', values);
  }

  List<JiveCurrency?> getAllByCodeSync(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'code', values);
  }

  Future<int> deleteAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'code', values);
  }

  int deleteAllByCodeSync(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'code', values);
  }

  Future<Id> putByCode(JiveCurrency object) {
    return putByIndex(r'code', object);
  }

  Id putByCodeSync(JiveCurrency object, {bool saveLinks = true}) {
    return putByIndexSync(r'code', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCode(List<JiveCurrency> objects) {
    return putAllByIndex(r'code', objects);
  }

  List<Id> putAllByCodeSync(List<JiveCurrency> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'code', objects, saveLinks: saveLinks);
  }
}

extension JiveCurrencyQueryWhereSort
    on QueryBuilder<JiveCurrency, JiveCurrency, QWhere> {
  QueryBuilder<JiveCurrency, JiveCurrency, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveCurrencyQueryWhere
    on QueryBuilder<JiveCurrency, JiveCurrency, QWhereClause> {
  QueryBuilder<JiveCurrency, JiveCurrency, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterWhereClause> codeEqualTo(
      String code) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'code',
        value: [code],
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterWhereClause> codeNotEqualTo(
      String code) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveCurrencyQueryFilter
    on QueryBuilder<JiveCurrency, JiveCurrency, QFilterCondition> {
  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> codeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      codeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> codeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> codeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'code',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      codeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> codeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> codeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> codeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'code',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      decimalPlacesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decimalPlaces',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      decimalPlacesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'decimalPlaces',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      decimalPlacesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'decimalPlaces',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      decimalPlacesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'decimalPlaces',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> flagIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'flag',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      flagIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'flag',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> flagEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      flagGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> flagLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> flagBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flag',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      flagStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'flag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> flagEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'flag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> flagContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'flag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> flagMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'flag',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      flagIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flag',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      flagIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'flag',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> idBetween(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      isCryptoEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCrypto',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameContains(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameZhEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameZh',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameZhGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameZh',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameZhLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameZh',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameZhBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameZh',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameZhStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameZh',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameZhEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameZh',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameZhContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameZh',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> nameZhMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameZh',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameZhIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameZh',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      nameZhIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameZh',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      sortOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
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

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> symbolEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      symbolGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      symbolLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> symbolBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'symbol',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      symbolStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      symbolEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      symbolContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition> symbolMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'symbol',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      symbolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'symbol',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterFilterCondition>
      symbolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'symbol',
        value: '',
      ));
    });
  }
}

extension JiveCurrencyQueryObject
    on QueryBuilder<JiveCurrency, JiveCurrency, QFilterCondition> {}

extension JiveCurrencyQueryLinks
    on QueryBuilder<JiveCurrency, JiveCurrency, QFilterCondition> {}

extension JiveCurrencyQuerySortBy
    on QueryBuilder<JiveCurrency, JiveCurrency, QSortBy> {
  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByDecimalPlaces() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decimalPlaces', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy>
      sortByDecimalPlacesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decimalPlaces', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flag', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByFlagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flag', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByIsCrypto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCrypto', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByIsCryptoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCrypto', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByNameZh() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameZh', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortByNameZhDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameZh', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortBySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> sortBySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.desc);
    });
  }
}

extension JiveCurrencyQuerySortThenBy
    on QueryBuilder<JiveCurrency, JiveCurrency, QSortThenBy> {
  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByDecimalPlaces() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decimalPlaces', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy>
      thenByDecimalPlacesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decimalPlaces', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flag', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByFlagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flag', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByIsCrypto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCrypto', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByIsCryptoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCrypto', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByNameZh() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameZh', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenByNameZhDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameZh', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenBySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QAfterSortBy> thenBySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.desc);
    });
  }
}

extension JiveCurrencyQueryWhereDistinct
    on QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> {
  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> distinctByCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct>
      distinctByDecimalPlaces() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'decimalPlaces');
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> distinctByFlag(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flag', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> distinctByIsCrypto() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCrypto');
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> distinctByNameZh(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameZh', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> distinctBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortOrder');
    });
  }

  QueryBuilder<JiveCurrency, JiveCurrency, QDistinct> distinctBySymbol(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'symbol', caseSensitive: caseSensitive);
    });
  }
}

extension JiveCurrencyQueryProperty
    on QueryBuilder<JiveCurrency, JiveCurrency, QQueryProperty> {
  QueryBuilder<JiveCurrency, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveCurrency, String, QQueryOperations> codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<JiveCurrency, int, QQueryOperations> decimalPlacesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'decimalPlaces');
    });
  }

  QueryBuilder<JiveCurrency, String?, QQueryOperations> flagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flag');
    });
  }

  QueryBuilder<JiveCurrency, bool, QQueryOperations> isCryptoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCrypto');
    });
  }

  QueryBuilder<JiveCurrency, bool, QQueryOperations> isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<JiveCurrency, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<JiveCurrency, String, QQueryOperations> nameZhProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameZh');
    });
  }

  QueryBuilder<JiveCurrency, int, QQueryOperations> sortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortOrder');
    });
  }

  QueryBuilder<JiveCurrency, String, QQueryOperations> symbolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'symbol');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveExchangeRateCollection on Isar {
  IsarCollection<JiveExchangeRate> get jiveExchangeRates => this.collection();
}

const JiveExchangeRateSchema = CollectionSchema(
  name: r'JiveExchangeRate',
  id: -5639004468624139776,
  properties: {
    r'effectiveDate': PropertySchema(
      id: 0,
      name: r'effectiveDate',
      type: IsarType.dateTime,
    ),
    r'fromCurrency': PropertySchema(
      id: 1,
      name: r'fromCurrency',
      type: IsarType.string,
    ),
    r'rate': PropertySchema(
      id: 2,
      name: r'rate',
      type: IsarType.double,
    ),
    r'source': PropertySchema(
      id: 3,
      name: r'source',
      type: IsarType.string,
    ),
    r'toCurrency': PropertySchema(
      id: 4,
      name: r'toCurrency',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _jiveExchangeRateEstimateSize,
  serialize: _jiveExchangeRateSerialize,
  deserialize: _jiveExchangeRateDeserialize,
  deserializeProp: _jiveExchangeRateDeserializeProp,
  idName: r'id',
  indexes: {
    r'fromCurrency': IndexSchema(
      id: 9005283779329603710,
      name: r'fromCurrency',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fromCurrency',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'toCurrency': IndexSchema(
      id: 4609850583487918775,
      name: r'toCurrency',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'toCurrency',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveExchangeRateGetId,
  getLinks: _jiveExchangeRateGetLinks,
  attach: _jiveExchangeRateAttach,
  version: '3.1.0+1',
);

int _jiveExchangeRateEstimateSize(
  JiveExchangeRate object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fromCurrency.length * 3;
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.toCurrency.length * 3;
  return bytesCount;
}

void _jiveExchangeRateSerialize(
  JiveExchangeRate object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.effectiveDate);
  writer.writeString(offsets[1], object.fromCurrency);
  writer.writeDouble(offsets[2], object.rate);
  writer.writeString(offsets[3], object.source);
  writer.writeString(offsets[4], object.toCurrency);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

JiveExchangeRate _jiveExchangeRateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveExchangeRate();
  object.effectiveDate = reader.readDateTime(offsets[0]);
  object.fromCurrency = reader.readString(offsets[1]);
  object.id = id;
  object.rate = reader.readDouble(offsets[2]);
  object.source = reader.readString(offsets[3]);
  object.toCurrency = reader.readString(offsets[4]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[5]);
  return object;
}

P _jiveExchangeRateDeserializeProp<P>(
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
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveExchangeRateGetId(JiveExchangeRate object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveExchangeRateGetLinks(JiveExchangeRate object) {
  return [];
}

void _jiveExchangeRateAttach(
    IsarCollection<dynamic> col, Id id, JiveExchangeRate object) {
  object.id = id;
}

extension JiveExchangeRateQueryWhereSort
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QWhere> {
  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveExchangeRateQueryWhere
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QWhereClause> {
  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause> idBetween(
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause>
      fromCurrencyEqualTo(String fromCurrency) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fromCurrency',
        value: [fromCurrency],
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause>
      fromCurrencyNotEqualTo(String fromCurrency) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromCurrency',
              lower: [],
              upper: [fromCurrency],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromCurrency',
              lower: [fromCurrency],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromCurrency',
              lower: [fromCurrency],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromCurrency',
              lower: [],
              upper: [fromCurrency],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause>
      toCurrencyEqualTo(String toCurrency) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'toCurrency',
        value: [toCurrency],
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterWhereClause>
      toCurrencyNotEqualTo(String toCurrency) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toCurrency',
              lower: [],
              upper: [toCurrency],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toCurrency',
              lower: [toCurrency],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toCurrency',
              lower: [toCurrency],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toCurrency',
              lower: [],
              upper: [toCurrency],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JiveExchangeRateQueryFilter
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QFilterCondition> {
  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      effectiveDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectiveDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      effectiveDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'effectiveDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      effectiveDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'effectiveDate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      effectiveDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'effectiveDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fromCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fromCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      fromCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fromCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      rateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      rateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      rateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      rateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'toCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      toCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'toCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
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

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

extension JiveExchangeRateQueryObject
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QFilterCondition> {}

extension JiveExchangeRateQueryLinks
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QFilterCondition> {}

extension JiveExchangeRateQuerySortBy
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QSortBy> {
  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByEffectiveDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveDate', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByEffectiveDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveDate', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByFromCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByFromCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromCurrency', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy> sortByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByToCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByToCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toCurrency', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveExchangeRateQuerySortThenBy
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QSortThenBy> {
  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByEffectiveDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveDate', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByEffectiveDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveDate', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByFromCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByFromCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromCurrency', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy> thenByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByToCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByToCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toCurrency', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension JiveExchangeRateQueryWhereDistinct
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QDistinct> {
  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QDistinct>
      distinctByEffectiveDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'effectiveDate');
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QDistinct>
      distinctByFromCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromCurrency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QDistinct> distinctByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rate');
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QDistinct>
      distinctByToCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toCurrency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveExchangeRate, JiveExchangeRate, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension JiveExchangeRateQueryProperty
    on QueryBuilder<JiveExchangeRate, JiveExchangeRate, QQueryProperty> {
  QueryBuilder<JiveExchangeRate, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveExchangeRate, DateTime, QQueryOperations>
      effectiveDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'effectiveDate');
    });
  }

  QueryBuilder<JiveExchangeRate, String, QQueryOperations>
      fromCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromCurrency');
    });
  }

  QueryBuilder<JiveExchangeRate, double, QQueryOperations> rateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rate');
    });
  }

  QueryBuilder<JiveExchangeRate, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<JiveExchangeRate, String, QQueryOperations>
      toCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toCurrency');
    });
  }

  QueryBuilder<JiveExchangeRate, DateTime?, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveCurrencyPreferenceCollection on Isar {
  IsarCollection<JiveCurrencyPreference> get jiveCurrencyPreferences =>
      this.collection();
}

const JiveCurrencyPreferenceSchema = CollectionSchema(
  name: r'JiveCurrencyPreference',
  id: 6919570410729963317,
  properties: {
    r'autoUpdateRates': PropertySchema(
      id: 0,
      name: r'autoUpdateRates',
      type: IsarType.bool,
    ),
    r'baseCurrency': PropertySchema(
      id: 1,
      name: r'baseCurrency',
      type: IsarType.string,
    ),
    r'enabledCurrencies': PropertySchema(
      id: 2,
      name: r'enabledCurrencies',
      type: IsarType.stringList,
    ),
    r'favoritePairs': PropertySchema(
      id: 3,
      name: r'favoritePairs',
      type: IsarType.stringList,
    ),
    r'lastRateUpdate': PropertySchema(
      id: 4,
      name: r'lastRateUpdate',
      type: IsarType.dateTime,
    ),
    r'preferredCryptoSource': PropertySchema(
      id: 5,
      name: r'preferredCryptoSource',
      type: IsarType.string,
    ),
    r'preferredRateSource': PropertySchema(
      id: 6,
      name: r'preferredRateSource',
      type: IsarType.string,
    ),
    r'rateChangeAlert': PropertySchema(
      id: 7,
      name: r'rateChangeAlert',
      type: IsarType.bool,
    ),
    r'rateChangeThreshold': PropertySchema(
      id: 8,
      name: r'rateChangeThreshold',
      type: IsarType.double,
    )
  },
  estimateSize: _jiveCurrencyPreferenceEstimateSize,
  serialize: _jiveCurrencyPreferenceSerialize,
  deserialize: _jiveCurrencyPreferenceDeserialize,
  deserializeProp: _jiveCurrencyPreferenceDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _jiveCurrencyPreferenceGetId,
  getLinks: _jiveCurrencyPreferenceGetLinks,
  attach: _jiveCurrencyPreferenceAttach,
  version: '3.1.0+1',
);

int _jiveCurrencyPreferenceEstimateSize(
  JiveCurrencyPreference object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.baseCurrency.length * 3;
  bytesCount += 3 + object.enabledCurrencies.length * 3;
  {
    for (var i = 0; i < object.enabledCurrencies.length; i++) {
      final value = object.enabledCurrencies[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.favoritePairs.length * 3;
  {
    for (var i = 0; i < object.favoritePairs.length; i++) {
      final value = object.favoritePairs[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.preferredCryptoSource.length * 3;
  bytesCount += 3 + object.preferredRateSource.length * 3;
  return bytesCount;
}

void _jiveCurrencyPreferenceSerialize(
  JiveCurrencyPreference object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoUpdateRates);
  writer.writeString(offsets[1], object.baseCurrency);
  writer.writeStringList(offsets[2], object.enabledCurrencies);
  writer.writeStringList(offsets[3], object.favoritePairs);
  writer.writeDateTime(offsets[4], object.lastRateUpdate);
  writer.writeString(offsets[5], object.preferredCryptoSource);
  writer.writeString(offsets[6], object.preferredRateSource);
  writer.writeBool(offsets[7], object.rateChangeAlert);
  writer.writeDouble(offsets[8], object.rateChangeThreshold);
}

JiveCurrencyPreference _jiveCurrencyPreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveCurrencyPreference();
  object.autoUpdateRates = reader.readBool(offsets[0]);
  object.baseCurrency = reader.readString(offsets[1]);
  object.enabledCurrencies = reader.readStringList(offsets[2]) ?? [];
  object.favoritePairs = reader.readStringList(offsets[3]) ?? [];
  object.id = id;
  object.lastRateUpdate = reader.readDateTimeOrNull(offsets[4]);
  object.preferredCryptoSource = reader.readString(offsets[5]);
  object.preferredRateSource = reader.readString(offsets[6]);
  object.rateChangeAlert = reader.readBool(offsets[7]);
  object.rateChangeThreshold = reader.readDouble(offsets[8]);
  return object;
}

P _jiveCurrencyPreferenceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveCurrencyPreferenceGetId(JiveCurrencyPreference object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveCurrencyPreferenceGetLinks(
    JiveCurrencyPreference object) {
  return [];
}

void _jiveCurrencyPreferenceAttach(
    IsarCollection<dynamic> col, Id id, JiveCurrencyPreference object) {
  object.id = id;
}

extension JiveCurrencyPreferenceQueryWhereSort
    on QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QWhere> {
  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JiveCurrencyPreferenceQueryWhere on QueryBuilder<
    JiveCurrencyPreference, JiveCurrencyPreference, QWhereClause> {
  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
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

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
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
}

extension JiveCurrencyPreferenceQueryFilter on QueryBuilder<
    JiveCurrencyPreference, JiveCurrencyPreference, QFilterCondition> {
  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> autoUpdateRatesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoUpdateRates',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> baseCurrencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> baseCurrencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> baseCurrencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> baseCurrencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> baseCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'baseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> baseCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'baseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      baseCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'baseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      baseCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'baseCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> baseCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> baseCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'baseCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabledCurrencies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'enabledCurrencies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'enabledCurrencies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'enabledCurrencies',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'enabledCurrencies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'enabledCurrencies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      enabledCurrenciesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'enabledCurrencies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      enabledCurrenciesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'enabledCurrencies',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabledCurrencies',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'enabledCurrencies',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'enabledCurrencies',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'enabledCurrencies',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'enabledCurrencies',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'enabledCurrencies',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'enabledCurrencies',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> enabledCurrenciesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'enabledCurrencies',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favoritePairs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'favoritePairs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'favoritePairs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'favoritePairs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'favoritePairs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'favoritePairs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      favoritePairsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'favoritePairs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      favoritePairsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'favoritePairs',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favoritePairs',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'favoritePairs',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoritePairs',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoritePairs',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoritePairs',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoritePairs',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoritePairs',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> favoritePairsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoritePairs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
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

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
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

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
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

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> lastRateUpdateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastRateUpdate',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> lastRateUpdateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastRateUpdate',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> lastRateUpdateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastRateUpdate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> lastRateUpdateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastRateUpdate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> lastRateUpdateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastRateUpdate',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> lastRateUpdateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastRateUpdate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredCryptoSourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredCryptoSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredCryptoSourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preferredCryptoSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredCryptoSourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preferredCryptoSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredCryptoSourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preferredCryptoSource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredCryptoSourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'preferredCryptoSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredCryptoSourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'preferredCryptoSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      preferredCryptoSourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'preferredCryptoSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      preferredCryptoSourceMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'preferredCryptoSource',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredCryptoSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredCryptoSource',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredCryptoSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'preferredCryptoSource',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredRateSourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredRateSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredRateSourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preferredRateSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredRateSourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preferredRateSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredRateSourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preferredRateSource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredRateSourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'preferredRateSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredRateSourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'preferredRateSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      preferredRateSourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'preferredRateSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
          QAfterFilterCondition>
      preferredRateSourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'preferredRateSource',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredRateSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredRateSource',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> preferredRateSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'preferredRateSource',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> rateChangeAlertEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateChangeAlert',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> rateChangeThresholdEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateChangeThreshold',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> rateChangeThresholdGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rateChangeThreshold',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> rateChangeThresholdLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rateChangeThreshold',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference,
      QAfterFilterCondition> rateChangeThresholdBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rateChangeThreshold',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension JiveCurrencyPreferenceQueryObject on QueryBuilder<
    JiveCurrencyPreference, JiveCurrencyPreference, QFilterCondition> {}

extension JiveCurrencyPreferenceQueryLinks on QueryBuilder<
    JiveCurrencyPreference, JiveCurrencyPreference, QFilterCondition> {}

extension JiveCurrencyPreferenceQuerySortBy
    on QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QSortBy> {
  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByAutoUpdateRates() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoUpdateRates', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByAutoUpdateRatesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoUpdateRates', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByBaseCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByBaseCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseCurrency', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByLastRateUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRateUpdate', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByLastRateUpdateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRateUpdate', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByPreferredCryptoSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredCryptoSource', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByPreferredCryptoSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredCryptoSource', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByPreferredRateSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredRateSource', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByPreferredRateSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredRateSource', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByRateChangeAlert() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateChangeAlert', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByRateChangeAlertDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateChangeAlert', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByRateChangeThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateChangeThreshold', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      sortByRateChangeThresholdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateChangeThreshold', Sort.desc);
    });
  }
}

extension JiveCurrencyPreferenceQuerySortThenBy on QueryBuilder<
    JiveCurrencyPreference, JiveCurrencyPreference, QSortThenBy> {
  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByAutoUpdateRates() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoUpdateRates', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByAutoUpdateRatesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoUpdateRates', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByBaseCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByBaseCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseCurrency', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByLastRateUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRateUpdate', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByLastRateUpdateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRateUpdate', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByPreferredCryptoSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredCryptoSource', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByPreferredCryptoSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredCryptoSource', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByPreferredRateSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredRateSource', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByPreferredRateSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredRateSource', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByRateChangeAlert() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateChangeAlert', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByRateChangeAlertDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateChangeAlert', Sort.desc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByRateChangeThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateChangeThreshold', Sort.asc);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QAfterSortBy>
      thenByRateChangeThresholdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateChangeThreshold', Sort.desc);
    });
  }
}

extension JiveCurrencyPreferenceQueryWhereDistinct
    on QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct> {
  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByAutoUpdateRates() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoUpdateRates');
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByBaseCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseCurrency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByEnabledCurrencies() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabledCurrencies');
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByFavoritePairs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'favoritePairs');
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByLastRateUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastRateUpdate');
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByPreferredCryptoSource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferredCryptoSource',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByPreferredRateSource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferredRateSource',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByRateChangeAlert() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateChangeAlert');
    });
  }

  QueryBuilder<JiveCurrencyPreference, JiveCurrencyPreference, QDistinct>
      distinctByRateChangeThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateChangeThreshold');
    });
  }
}

extension JiveCurrencyPreferenceQueryProperty on QueryBuilder<
    JiveCurrencyPreference, JiveCurrencyPreference, QQueryProperty> {
  QueryBuilder<JiveCurrencyPreference, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveCurrencyPreference, bool, QQueryOperations>
      autoUpdateRatesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoUpdateRates');
    });
  }

  QueryBuilder<JiveCurrencyPreference, String, QQueryOperations>
      baseCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseCurrency');
    });
  }

  QueryBuilder<JiveCurrencyPreference, List<String>, QQueryOperations>
      enabledCurrenciesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabledCurrencies');
    });
  }

  QueryBuilder<JiveCurrencyPreference, List<String>, QQueryOperations>
      favoritePairsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'favoritePairs');
    });
  }

  QueryBuilder<JiveCurrencyPreference, DateTime?, QQueryOperations>
      lastRateUpdateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastRateUpdate');
    });
  }

  QueryBuilder<JiveCurrencyPreference, String, QQueryOperations>
      preferredCryptoSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredCryptoSource');
    });
  }

  QueryBuilder<JiveCurrencyPreference, String, QQueryOperations>
      preferredRateSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredRateSource');
    });
  }

  QueryBuilder<JiveCurrencyPreference, bool, QQueryOperations>
      rateChangeAlertProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateChangeAlert');
    });
  }

  QueryBuilder<JiveCurrencyPreference, double, QQueryOperations>
      rateChangeThresholdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateChangeThreshold');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveExchangeRateHistoryCollection on Isar {
  IsarCollection<JiveExchangeRateHistory> get jiveExchangeRateHistorys =>
      this.collection();
}

const JiveExchangeRateHistorySchema = CollectionSchema(
  name: r'JiveExchangeRateHistory',
  id: 8517312444633449987,
  properties: {
    r'fromCurrency': PropertySchema(
      id: 0,
      name: r'fromCurrency',
      type: IsarType.string,
    ),
    r'rate': PropertySchema(
      id: 1,
      name: r'rate',
      type: IsarType.double,
    ),
    r'recordedAt': PropertySchema(
      id: 2,
      name: r'recordedAt',
      type: IsarType.dateTime,
    ),
    r'source': PropertySchema(
      id: 3,
      name: r'source',
      type: IsarType.string,
    ),
    r'toCurrency': PropertySchema(
      id: 4,
      name: r'toCurrency',
      type: IsarType.string,
    )
  },
  estimateSize: _jiveExchangeRateHistoryEstimateSize,
  serialize: _jiveExchangeRateHistorySerialize,
  deserialize: _jiveExchangeRateHistoryDeserialize,
  deserializeProp: _jiveExchangeRateHistoryDeserializeProp,
  idName: r'id',
  indexes: {
    r'fromCurrency': IndexSchema(
      id: 9005283779329603710,
      name: r'fromCurrency',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fromCurrency',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'toCurrency': IndexSchema(
      id: 4609850583487918775,
      name: r'toCurrency',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'toCurrency',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'recordedAt': IndexSchema(
      id: -5046025352082009396,
      name: r'recordedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'recordedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveExchangeRateHistoryGetId,
  getLinks: _jiveExchangeRateHistoryGetLinks,
  attach: _jiveExchangeRateHistoryAttach,
  version: '3.1.0+1',
);

int _jiveExchangeRateHistoryEstimateSize(
  JiveExchangeRateHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fromCurrency.length * 3;
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.toCurrency.length * 3;
  return bytesCount;
}

void _jiveExchangeRateHistorySerialize(
  JiveExchangeRateHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.fromCurrency);
  writer.writeDouble(offsets[1], object.rate);
  writer.writeDateTime(offsets[2], object.recordedAt);
  writer.writeString(offsets[3], object.source);
  writer.writeString(offsets[4], object.toCurrency);
}

JiveExchangeRateHistory _jiveExchangeRateHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveExchangeRateHistory();
  object.fromCurrency = reader.readString(offsets[0]);
  object.id = id;
  object.rate = reader.readDouble(offsets[1]);
  object.recordedAt = reader.readDateTime(offsets[2]);
  object.source = reader.readString(offsets[3]);
  object.toCurrency = reader.readString(offsets[4]);
  return object;
}

P _jiveExchangeRateHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveExchangeRateHistoryGetId(JiveExchangeRateHistory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveExchangeRateHistoryGetLinks(
    JiveExchangeRateHistory object) {
  return [];
}

void _jiveExchangeRateHistoryAttach(
    IsarCollection<dynamic> col, Id id, JiveExchangeRateHistory object) {
  object.id = id;
}

extension JiveExchangeRateHistoryQueryWhereSort
    on QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QWhere> {
  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterWhere>
      anyRecordedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'recordedAt'),
      );
    });
  }
}

extension JiveExchangeRateHistoryQueryWhere on QueryBuilder<
    JiveExchangeRateHistory, JiveExchangeRateHistory, QWhereClause> {
  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> fromCurrencyEqualTo(String fromCurrency) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fromCurrency',
        value: [fromCurrency],
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> fromCurrencyNotEqualTo(String fromCurrency) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromCurrency',
              lower: [],
              upper: [fromCurrency],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromCurrency',
              lower: [fromCurrency],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromCurrency',
              lower: [fromCurrency],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromCurrency',
              lower: [],
              upper: [fromCurrency],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> toCurrencyEqualTo(String toCurrency) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'toCurrency',
        value: [toCurrency],
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> toCurrencyNotEqualTo(String toCurrency) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toCurrency',
              lower: [],
              upper: [toCurrency],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toCurrency',
              lower: [toCurrency],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toCurrency',
              lower: [toCurrency],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toCurrency',
              lower: [],
              upper: [toCurrency],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> recordedAtEqualTo(DateTime recordedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'recordedAt',
        value: [recordedAt],
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> recordedAtNotEqualTo(DateTime recordedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordedAt',
              lower: [],
              upper: [recordedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordedAt',
              lower: [recordedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordedAt',
              lower: [recordedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordedAt',
              lower: [],
              upper: [recordedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> recordedAtGreaterThan(
    DateTime recordedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recordedAt',
        lower: [recordedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> recordedAtLessThan(
    DateTime recordedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recordedAt',
        lower: [],
        upper: [recordedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterWhereClause> recordedAtBetween(
    DateTime lowerRecordedAt,
    DateTime upperRecordedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recordedAt',
        lower: [lowerRecordedAt],
        includeLower: includeLower,
        upper: [upperRecordedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JiveExchangeRateHistoryQueryFilter on QueryBuilder<
    JiveExchangeRateHistory, JiveExchangeRateHistory, QFilterCondition> {
  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> fromCurrencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> fromCurrencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> fromCurrencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> fromCurrencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fromCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> fromCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> fromCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
          QAfterFilterCondition>
      fromCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fromCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
          QAfterFilterCondition>
      fromCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fromCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> fromCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> fromCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fromCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> rateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> rateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> rateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> rateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> recordedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> recordedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> recordedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> recordedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recordedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> sourceEqualTo(
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> sourceGreaterThan(
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> sourceLessThan(
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> sourceBetween(
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> sourceStartsWith(
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> sourceEndsWith(
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

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
          QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
          QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> toCurrencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> toCurrencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> toCurrencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> toCurrencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> toCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> toCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
          QAfterFilterCondition>
      toCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'toCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
          QAfterFilterCondition>
      toCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'toCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> toCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory,
      QAfterFilterCondition> toCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'toCurrency',
        value: '',
      ));
    });
  }
}

extension JiveExchangeRateHistoryQueryObject on QueryBuilder<
    JiveExchangeRateHistory, JiveExchangeRateHistory, QFilterCondition> {}

extension JiveExchangeRateHistoryQueryLinks on QueryBuilder<
    JiveExchangeRateHistory, JiveExchangeRateHistory, QFilterCondition> {}

extension JiveExchangeRateHistoryQuerySortBy
    on QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QSortBy> {
  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortByFromCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortByFromCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromCurrency', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortByRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortByRecordedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortByRecordedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortByToCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      sortByToCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toCurrency', Sort.desc);
    });
  }
}

extension JiveExchangeRateHistoryQuerySortThenBy on QueryBuilder<
    JiveExchangeRateHistory, JiveExchangeRateHistory, QSortThenBy> {
  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByFromCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByFromCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromCurrency', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rate', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByRecordedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAt', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByRecordedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAt', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByToCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toCurrency', Sort.asc);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QAfterSortBy>
      thenByToCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toCurrency', Sort.desc);
    });
  }
}

extension JiveExchangeRateHistoryQueryWhereDistinct on QueryBuilder<
    JiveExchangeRateHistory, JiveExchangeRateHistory, QDistinct> {
  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QDistinct>
      distinctByFromCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromCurrency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QDistinct>
      distinctByRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rate');
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QDistinct>
      distinctByRecordedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordedAt');
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QDistinct>
      distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JiveExchangeRateHistory, JiveExchangeRateHistory, QDistinct>
      distinctByToCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toCurrency', caseSensitive: caseSensitive);
    });
  }
}

extension JiveExchangeRateHistoryQueryProperty on QueryBuilder<
    JiveExchangeRateHistory, JiveExchangeRateHistory, QQueryProperty> {
  QueryBuilder<JiveExchangeRateHistory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JiveExchangeRateHistory, String, QQueryOperations>
      fromCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromCurrency');
    });
  }

  QueryBuilder<JiveExchangeRateHistory, double, QQueryOperations>
      rateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rate');
    });
  }

  QueryBuilder<JiveExchangeRateHistory, DateTime, QQueryOperations>
      recordedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordedAt');
    });
  }

  QueryBuilder<JiveExchangeRateHistory, String, QQueryOperations>
      sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<JiveExchangeRateHistory, String, QQueryOperations>
      toCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toCurrency');
    });
  }
}
