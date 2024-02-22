// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_temporary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyMemberTemporaryData _$FamilyMemberTemporaryDataFromJson(
        Map<String, dynamic> json) =>
    FamilyMemberTemporaryData(
      id: NumParser.intParse(json['id']),
      label: StringParser.parse(json['label']),
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.member,
      userId: NumParser.intParse(json['user_id']),
      name: StringParser.parse(json['name']),
      email: StringParser.parse(json['email']),
      avatar: StringParser.parse(json['avatar']),
      birthDate: StringParser.parse(json['birth_date']),
      gender: StringParser.parse(json['gender']),
      diabetesType: NumParser.intParse(json['diabetesType']),
      weight: NumParser.intParse(json['weight']),
      totalDailyDose: NumParser.intParse(json['total_daily_dose']),
      currentBloodGlucose: NumParser.intParse(json['currentBloodGlucose']),
    );

Map<String, dynamic> _$FamilyMemberTemporaryDataToJson(
        FamilyMemberTemporaryData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'role': _$UserRoleEnumMap[instance.role]!,
      'user_id': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'avatar': instance.avatar,
      'birth_date': instance.birthDate,
      'gender': instance.gender,
      'diabetesType': instance.diabetesType,
      'weight': instance.weight,
      'total_daily_dose': instance.totalDailyDose,
      'currentBloodGlucose': instance.currentBloodGlucose,
    };

const _$UserRoleEnumMap = {
  UserRole.admin: 'ADMIN',
  UserRole.member: 'MEMBER',
};
