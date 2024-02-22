// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_temporary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitationTemporaryData _$InvitationTemporaryDataFromJson(
        Map<String, dynamic> json) =>
    InvitationTemporaryData(
      temporaryId: json['temporary_id'] as String,
      email: json['email'] as String,
      userId: json['user_id'] as String,
      createdAt:
          const DateTimeJsonConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const DateTimeJsonConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$InvitationTemporaryDataToJson(
        InvitationTemporaryData instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'email': instance.email,
      'user_id': instance.userId,
      'created_at': const DateTimeJsonConverter().toJson(instance.createdAt),
      'updated_at': const DateTimeJsonConverter().toJson(instance.updatedAt),
    };
