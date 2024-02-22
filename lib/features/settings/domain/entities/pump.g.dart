// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pump.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PumpData _$PumpDataFromJson(Map<String, dynamic> json) => PumpData(
      id: json['id'] as String,
      name: StringParser.parse(json['name']),
      status: json['status'] as bool,
      connectAt: DateTime.tryParse(json['connect_at'] as String),
    );

Map<String, dynamic> _$PumpDataToJson(PumpData instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'connect_at': _$JsonConverterToJson<String, DateTime>(
          instance.connectAt, const DateTimeJsonConverter().toJson),
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
