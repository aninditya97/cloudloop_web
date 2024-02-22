// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remove_temporary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoveTemporaryData _$RemoveTemporaryDataFromJson(Map<String, dynamic> json) =>
    RemoveTemporaryData(
      temporaryId: json['temporary_id'] as String,
      familyMemberId: json['family_member_id'] as String,
      userId: json['user_id'] as String,
      deletedAt:
          const DateTimeJsonConverter().fromJson(json['deleted_at'] as String),
    );

Map<String, dynamic> _$RemoveTemporaryDataToJson(
        RemoveTemporaryData instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'family_member_id': instance.familyMemberId,
      'user_id': instance.userId,
      'deleted_at': const DateTimeJsonConverter().toJson(instance.deletedAt),
    };
