// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xdrip_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XdripData _$XdripDataFromJson(Map<String, dynamic> json) => XdripData(
      glucose: json['glucose'] as String,
      timestamp: json['timestamp'] as String,
      raw: json['raw'] as String,
      direction: $enumDecode(_$DirectionsEnumMap, json['direction']),
      source: json['source'] as String,
    );

Map<String, dynamic> _$XdripDataToJson(XdripData instance) => <String, dynamic>{
      'glucose': instance.glucose,
      'timestamp': instance.timestamp,
      'raw': instance.raw,
      'direction': _$DirectionsEnumMap[instance.direction]!,
      'source': instance.source,
    };

const _$DirectionsEnumMap = {
  Directions.singleUp: 'SingleUp',
  Directions.singleDown: 'SingleDown',
  Directions.flat: 'Flat',
  Directions.doubleUp: 'DoubleUp',
  Directions.doubleDown: 'DoubleDown',
  Directions.fortyFiveUp: 'FortyFiveUp',
  Directions.fortyFiveDown: 'FortyFiveDown',
  Directions.none: '...',
};
