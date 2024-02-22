// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_blood_glucose_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendBloodGlucoseParams _$SendBloodGlucoseParamsFromJson(
        Map<String, dynamic> json) =>
    SendBloodGlucoseParams(
      temporaryId: json['temporary_id'] as String?,
      userId: json['user_id'] as int?,
      value: NumParser.doubleParse(json['value']),
      source: json['source'] as String,
      time: json['time'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$SendBloodGlucoseParamsToJson(
        SendBloodGlucoseParams instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'value': instance.value,
      'source': instance.source,
      'time': instance.time,
      'user_id': instance.userId,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
