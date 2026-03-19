// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instalment_model.dart';

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJiveInstalmentCollection on Isar {
  IsarCollection<JiveInstalment> get jiveInstalments => this.collection();
}

const JiveInstalmentSchema = CollectionSchema(
  name: r'JiveInstalment',
  id: 5969089475944813907,
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
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'instalmentCount': PropertySchema(
      id: 3,
      name: r'instalmentCount',
      type: IsarType.long,
    ),
    r'monthlyAmount': PropertySchema(
      id: 4,
      name: r'monthlyAmount',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'nextPaymentDate': PropertySchema(
      id: 6,
      name: r'nextPaymentDate',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(
      id: 7,
      name: r'note',
      type: IsarType.string,
    ),
    r'paidCount': PropertySchema(
      id: 8,
      name: r'paidCount',
      type: IsarType.long,
    ),
    r'startDate': PropertySchema(
      id: 9,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 10,
      name: r'status',
      type: IsarType.string,
    ),
    r'totalAmount': PropertySchema(
      id: 11,
      name: r'totalAmount',
      type: IsarType.double,
    ),
  },
  estimateSize: _jiveInstalmentEstimateSize,
  serialize: _jiveInstalmentSerialize,
  deserialize: _jiveInstalmentDeserialize,
  deserializeProp: _jiveInstalmentDeserializeProp,
  idName: r'id',
  indexes: {
    r'nextPaymentDate': IndexSchema(
      id: 4913325069179127434,
      name: r'nextPaymentDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nextPaymentDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'status': IndexSchema(
      id: 8733406715023712412,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _jiveInstalmentGetId,
  getLinks: _jiveInstalmentGetLinks,
  attach: _jiveInstalmentAttach,
  version: '3.1.0+1',
);

int _jiveInstalmentEstimateSize(
  JiveInstalment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  final categoryKey = object.categoryKey;
  if (categoryKey != null) {
    bytesCount += 3 + categoryKey.length * 3;
  }
  bytesCount += 3 + object.name.length * 3;
  final note = object.note;
  if (note != null) {
    bytesCount += 3 + note.length * 3;
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _jiveInstalmentSerialize(
  JiveInstalment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeString(offsets[1], object.categoryKey);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.instalmentCount);
  writer.writeDouble(offsets[4], object.monthlyAmount);
  writer.writeString(offsets[5], object.name);
  writer.writeDateTime(offsets[6], object.nextPaymentDate);
  writer.writeString(offsets[7], object.note);
  writer.writeLong(offsets[8], object.paidCount);
  writer.writeDateTime(offsets[9], object.startDate);
  writer.writeString(offsets[10], object.status);
  writer.writeDouble(offsets[11], object.totalAmount);
}

JiveInstalment _jiveInstalmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JiveInstalment();
  object.accountId = reader.readLongOrNull(offsets[0]);
  object.categoryKey = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.instalmentCount = reader.readLong(offsets[3]);
  object.monthlyAmount = reader.readDouble(offsets[4]);
  object.name = reader.readString(offsets[5]);
  object.nextPaymentDate = reader.readDateTime(offsets[6]);
  object.note = reader.readStringOrNull(offsets[7]);
  object.paidCount = reader.readLong(offsets[8]);
  object.startDate = reader.readDateTime(offsets[9]);
  object.status = reader.readString(offsets[10]);
  object.totalAmount = reader.readDouble(offsets[11]);
  return object;
}

P _jiveInstalmentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jiveInstalmentGetId(JiveInstalment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jiveInstalmentGetLinks(JiveInstalment object) {
  return [];
}

void _jiveInstalmentAttach(
  IsarCollection<dynamic> col,
  Id id,
  JiveInstalment object,
) {
  object.id = id;
}
