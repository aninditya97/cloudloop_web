// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: StringParser.parse(json['id']),
      name: StringParser.parse(json['name']),
      email: StringParser.parse(json['email']),
      avatar: StringParser.parse(json['avatar']),
      birthDate: DateTime.tryParse(json['birthDate'] as String),
      gender:
          $enumDecodeNullable(_$GenderEnumMap, json['gender']) ?? Gender.male,
      weight: NumParser.doubleParse(json['weight']),
      totalDailyDose: NumParser.doubleParse(json['totalDailyDose']),
      basalRate: NumParser.doubleParse(json['basalRate']),
      insulinCarbRatio: NumParser.doubleParse(json['insulinCarbRatio']),
      insulinSensitivityFactor:
          NumParser.doubleParse(json['insulinSensitivityFactor']),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatar': instance.avatar,
      'birthDate': _$JsonConverterToJson<String, DateTime>(
          instance.birthDate, const DateTimeJsonConverter().toJson),
      'gender': _$GenderEnumMap[instance.gender]!,
      'weight': instance.weight,
      'totalDailyDose': instance.totalDailyDose,
      'basalRate': instance.basalRate,
      'insulinCarbRatio': instance.insulinCarbRatio,
      'insulinSensitivityFactor': instance.insulinSensitivityFactor,
    };

const _$GenderEnumMap = {
  Gender.male: 'MALE',
  Gender.female: 'FEMALE',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
