// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_temporary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveTemporaryData _$LeaveTemporaryDataFromJson(Map<String, dynamic> json) =>
    LeaveTemporaryData(
      temporaryId: json['temporary_id'] as String,
      userId: json['user_id'] as String,
    );

Map<String, dynamic> _$LeaveTemporaryDataToJson(LeaveTemporaryData instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'user_id': instance.userId,
    };
