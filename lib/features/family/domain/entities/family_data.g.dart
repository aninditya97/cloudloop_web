// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyData _$FamilyDataFromJson(Map<String, dynamic> json) => FamilyData(
      id: NumParser.intParse(json['id']),
      label: StringParser.parse(json['label']),
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.member,
      user: json['user'] == null
          ? null
          : UserData.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FamilyDataToJson(FamilyData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'role': _$UserRoleEnumMap[instance.role]!,
      'user': instance.user?.toJson(),
    };

const _$UserRoleEnumMap = {
  UserRole.admin: 'ADMIN',
  UserRole.member: 'MEMBER',
};
