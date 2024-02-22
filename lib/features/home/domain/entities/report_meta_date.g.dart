// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_meta_date.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportMetaDate _$ReportMetaDateFromJson(Map<String, dynamic> json) =>
    ReportMetaDate(
      days: NumParser.intParse(json['days']),
      hours: NumParser.intParse(json['hours']),
      minutes: NumParser.intParse(json['minutes']),
      seconds: NumParser.intParse(json['seconds']),
    );

Map<String, dynamic> _$ReportMetaDateToJson(ReportMetaDate instance) =>
    <String, dynamic>{
      'days': instance.days,
      'hours': instance.hours,
      'minutes': instance.minutes,
      'seconds': instance.seconds,
    };
