// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyMemberData _$FamilyMemberDataFromJson(Map<String, dynamic> json) =>
    FamilyMemberData(
      items: (json['data'] as List<dynamic>?)
          ?.map((e) => FamilyData.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaData.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FamilyMemberDataToJson(FamilyMemberData instance) =>
    <String, dynamic>{
      'data': instance.items?.map((e) => e.toJson()).toList(),
      'meta': instance.meta.toJson(),
    };
