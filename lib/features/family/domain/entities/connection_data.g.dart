// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionData _$ConnectionDataFromJson(Map<String, dynamic> json) =>
    ConnectionData(
      sentAt: _$JsonConverterFromJson<String, DateTime>(
          json['sentAt'], const DateTimeJsonConverter().fromJson),
      connectedAt: _$JsonConverterFromJson<String, DateTime>(
          json['connectedAt'], const DateTimeJsonConverter().fromJson),
      status: $enumDecodeNullable(_$ConnectionStatusEnumMap, json['status']) ??
          ConnectionStatus.status1,
    );

Map<String, dynamic> _$ConnectionDataToJson(ConnectionData instance) =>
    <String, dynamic>{
      'sentAt': _$JsonConverterToJson<String, DateTime>(
          instance.sentAt, const DateTimeJsonConverter().toJson),
      'connectedAt': _$JsonConverterToJson<String, DateTime>(
          instance.connectedAt, const DateTimeJsonConverter().toJson),
      'status': _$ConnectionStatusEnumMap[instance.status]!,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.status1: 'UNCONNECTED',
  ConnectionStatus.status2: 'CONNECTED',
  ConnectionStatus.status3: 'PENDING',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
