// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glucose_report_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlucoseReportItem _$GlucoseReportItemFromJson(Map<String, dynamic> json) =>
    GlucoseReportItem(
      id: NumParser.intParse(json['id']),
      value: NumParser.doubleParse(json['value']),
      source: $enumDecode(_$ReportSourceEnumMap, json['source']),
      userId: json['user_id'] as int,
      time: const DateTimeJsonConverter().fromJson(json['time'] as String),
      level: $enumDecode(_$GlucoseLevelEnumMap, json['level']),
      createdAt:
          const DateTimeJsonConverter().fromJson(json['createdAt'] as String),
      updatedAt:
          const DateTimeJsonConverter().fromJson(json['updatedAt'] as String),
    );

Map<String, dynamic> _$GlucoseReportItemToJson(GlucoseReportItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value': instance.value,
      'source': _$ReportSourceEnumMap[instance.source]!,
      'user_id': instance.userId,
      'time': const DateTimeJsonConverter().toJson(instance.time),
      'level': _$GlucoseLevelEnumMap[instance.level]!,
      'createdAt': const DateTimeJsonConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeJsonConverter().toJson(instance.updatedAt),
    };

const _$ReportSourceEnumMap = {
  ReportSource.user: 'USER',
  ReportSource.sensor: 'SENSOR',
};

const _$GlucoseLevelEnumMap = {
  GlucoseLevel.veryLow: 'VERY_LOW',
  GlucoseLevel.low: 'LOW',
  GlucoseLevel.normal: 'NORMAL',
  GlucoseLevel.high: 'HIGH',
  GlucoseLevel.veryHigh: 'VERY_HIGH',
};
