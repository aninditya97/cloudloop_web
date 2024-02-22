// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_report_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SummaryReportItem _$SummaryReportItemFromJson(Map<String, dynamic> json) =>
    SummaryReportItem(
      value: NumParser.doubleParse(json['value']),
      date: const DateTimeJsonConverter().fromJson(json['time'] as String),
      source: $enumDecodeNullable(_$InputSourceEnumMap, json['source']) ??
          InputSource.sensor,
      level: $enumDecodeNullable(_$BloodGlucoseLevelEnumMap, json['level']) ??
          BloodGlucoseLevel.status1,
      average: NumParser.doubleParse(json['average']),
      highest: NumParser.doubleParse(json['highest']),
      lowest: NumParser.doubleParse(json['lowest']),
    );

Map<String, dynamic> _$SummaryReportItemToJson(SummaryReportItem instance) =>
    <String, dynamic>{
      'value': instance.value,
      'time': const DateTimeJsonConverter().toJson(instance.date),
      'source': _$InputSourceEnumMap[instance.source]!,
      'level': _$BloodGlucoseLevelEnumMap[instance.level],
      'average': instance.average,
      'highest': instance.highest,
      'lowest': instance.lowest,
    };

const _$InputSourceEnumMap = {
  InputSource.sensor: 'SENSOR',
  InputSource.user: 'USER',
};

const _$BloodGlucoseLevelEnumMap = {
  BloodGlucoseLevel.status1: 'VERY_LOW',
  BloodGlucoseLevel.status2: 'LOW',
  BloodGlucoseLevel.status3: 'NORMAL',
  BloodGlucoseLevel.status4: 'HIGH',
  BloodGlucoseLevel.status5: 'VERY_HIGH',
};
