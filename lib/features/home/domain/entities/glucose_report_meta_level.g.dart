// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glucose_report_meta_level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlucoseReportMetaLevel _$GlucoseReportMetaLevelFromJson(
        Map<String, dynamic> json) =>
    GlucoseReportMetaLevel(
      percentage: NumParser.doubleParse(json['percentage']),
      dates: json['dates'] == null
          ? null
          : ReportMetaDate.fromJson(json['dates'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GlucoseReportMetaLevelToJson(
        GlucoseReportMetaLevel instance) =>
    <String, dynamic>{
      'percentage': instance.percentage,
      'dates': instance.dates?.toJson(),
    };
