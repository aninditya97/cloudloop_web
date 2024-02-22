// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_temporary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileTemporaryData _$UpdateProfileTemporaryDataFromJson(
        Map<String, dynamic> json) =>
    UpdateProfileTemporaryData(
      temporaryId: json['temporary_id'] as String,
      userId: json['user_id'] as String,
      name: StringParser.parse(json['name']),
      email: StringParser.parse(json['email']),
      avatar: StringParser.parse(json['avatar']),
      birthDate: DateTime.tryParse(json['birthDate'] as String),
      gender:
          $enumDecodeNullable(_$GenderEnumMap, json['gender']) ?? Gender.male,
      weight: NumParser.doubleParse(json['weight']),
      totalDailyDose: NumParser.doubleParse(json['totalDailyDose']),
      diabetesType:
          $enumDecodeNullable(_$DiabetesTypeEnumMap, json['diabetesType']) ??
              DiabetesType.type1,
    );

Map<String, dynamic> _$UpdateProfileTemporaryDataToJson(
        UpdateProfileTemporaryData instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'user_id': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'avatar': instance.avatar,
      'birthDate': _$JsonConverterToJson<String, DateTime>(
          instance.birthDate, const DateTimeJsonConverter().toJson),
      'gender': _$GenderEnumMap[instance.gender]!,
      'weight': instance.weight,
      'totalDailyDose': instance.totalDailyDose,
      'diabetesType': _$DiabetesTypeEnumMap[instance.diabetesType]!,
    };

const _$GenderEnumMap = {
  Gender.male: 'MALE',
  Gender.female: 'FEMALE',
};

const _$DiabetesTypeEnumMap = {
  DiabetesType.type1: 1,
  DiabetesType.type2: 2,
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
