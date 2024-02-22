// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glucose_report_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlucoseReportMeta _$GlucoseReportMetaFromJson(Map<String, dynamic> json) =>
    GlucoseReportMeta(
      current: NumParser.doubleParse(json['current']),
      highest: NumParser.doubleParse(json['highest']),
      lowest: NumParser.doubleParse(json['lowest']),
      average: NumParser.doubleParse(json['average']),
    );

Map<String, dynamic> _$GlucoseReportMetaToJson(GlucoseReportMeta instance) =>
    <String, dynamic>{
      'current': instance.current,
      'highest': instance.highest,
      'lowest': instance.lowest,
      'average': instance.average,
    };
