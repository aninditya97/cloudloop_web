// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rejected_temporary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RejactedTemporaryData _$RejactedTemporaryDataFromJson(
        Map<String, dynamic> json) =>
    RejactedTemporaryData(
      temporaryId: json['temporary_id'] as String,
      invitationId: json['invitation_id'] as String,
      userId: json['user_id'] as String,
      rejactedAt:
          const DateTimeJsonConverter().fromJson(json['rejacted_at'] as String),
    );

Map<String, dynamic> _$RejactedTemporaryDataToJson(
        RejactedTemporaryData instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'user_id': instance.userId,
      'invitation_id': instance.invitationId,
      'rejacted_at': const DateTimeJsonConverter().toJson(instance.rejactedAt),
    };
