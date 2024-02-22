// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cgm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CgmData _$CgmDataFromJson(Map<String, dynamic> json) => CgmData(
      id: json['id'] as String,
      deviceId: StringParser.parse(json['device_id']),
      status: json['status'] as bool,
      transmitterId: StringParser.parse(json['transmitter_id']),
      transmitterCode: StringParser.parse(json['transmitter_code']),
      connectAt: DateTime.tryParse(json['connect_at'] as String),
    );

Map<String, dynamic> _$CgmDataToJson(CgmData instance) => <String, dynamic>{
      'id': instance.id,
      'device_id': instance.deviceId,
      'transmitter_id': instance.transmitterId,
      'transmitter_code': instance.transmitterCode,
      'status': instance.status,
      'connect_at': _$JsonConverterToJson<String, DateTime>(
          instance.connectAt, const DateTimeJsonConverter().toJson),
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
