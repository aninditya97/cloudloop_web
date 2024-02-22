// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accepted_temporary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptedTemporaryData _$AcceptedTemporaryDataFromJson(
        Map<String, dynamic> json) =>
    AcceptedTemporaryData(
      temporaryId: json['temporary_id'] as String,
      invitationId: json['invitation_id'] as String,
      userId: json['user_id'] as String,
      acceptedAt:
          const DateTimeJsonConverter().fromJson(json['accepted_at'] as String),
    );

Map<String, dynamic> _$AcceptedTemporaryDataToJson(
        AcceptedTemporaryData instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'user_id': instance.userId,
      'invitation_id': instance.invitationId,
      'accepted_at': const DateTimeJsonConverter().toJson(instance.acceptedAt),
    };
