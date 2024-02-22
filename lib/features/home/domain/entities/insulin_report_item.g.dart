// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insulin_report_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InsulinReportItem _$InsulinReportItemFromJson(Map<String, dynamic> json) =>
    InsulinReportItem(
      id: NumParser.intParse(json['id']),
      source: $enumDecode(_$ReportSourceEnumMap, json['source']),
      value: NumParser.doubleParse(json['value']),
      time: const DateTimeJsonConverter().fromJson(json['time'] as String),
      announceMealEnabled: json['announceMealEnabled'] as bool?,
      autoModeEnabled: json['autoModeEnabled'] as bool?,
      iob: json['iob'] as String,
      userId: json['user_id'] as int,
      hypoPrevention: BoolParser.boolParse(json['hypoPrevention']),
      createdAt:
          const DateTimeJsonConverter().fromJson(json['createdAt'] as String),
      updatedAt:
          const DateTimeJsonConverter().fromJson(json['updatedAt'] as String),
    );

Map<String, dynamic> _$InsulinReportItemToJson(InsulinReportItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': _$ReportSourceEnumMap[instance.source]!,
      'value': instance.value,
      'time': const DateTimeJsonConverter().toJson(instance.time),
      'announceMealEnabled': instance.announceMealEnabled,
      'autoModeEnabled': instance.autoModeEnabled,
      'iob': instance.iob,
      'user_id': instance.userId,
      'hypoPrevention': instance.hypoPrevention,
      'createdAt': const DateTimeJsonConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeJsonConverter().toJson(instance.updatedAt),
    };

const _$ReportSourceEnumMap = {
  ReportSource.user: 'USER',
  ReportSource.sensor: 'SENSOR',
};
