// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glucose_report_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlucoseReportData _$GlucoseReportDataFromJson(Map<String, dynamic> json) =>
    GlucoseReportData(
      items: (json['data'] as List<dynamic>)
          .map((e) => GlucoseReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : GlucoseReportMeta.fromJson(json['meta'] as Map<String, dynamic>),
      veryHeightLevel: json['veryHigh'] == null
          ? null
          : GlucoseReportMetaLevel.fromJson(
              json['veryHigh'] as Map<String, dynamic>),
      highLevel: json['high'] == null
          ? null
          : GlucoseReportMetaLevel.fromJson(
              json['high'] as Map<String, dynamic>),
      normalLevel: json['normal'] == null
          ? null
          : GlucoseReportMetaLevel.fromJson(
              json['normal'] as Map<String, dynamic>),
      lowLevel: json['low'] == null
          ? null
          : GlucoseReportMetaLevel.fromJson(
              json['low'] as Map<String, dynamic>),
      veryLowLevel: json['veryLow'] == null
          ? null
          : GlucoseReportMetaLevel.fromJson(
              json['veryLow'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GlucoseReportDataToJson(GlucoseReportData instance) =>
    <String, dynamic>{
      'data': instance.items.map((e) => e.toJson()).toList(),
      'meta': instance.meta?.toJson(),
      'veryHigh': instance.veryHeightLevel?.toJson(),
      'high': instance.highLevel?.toJson(),
      'normal': instance.normalLevel?.toJson(),
      'low': instance.lowLevel?.toJson(),
      'veryLow': instance.veryLowLevel?.toJson(),
    };
