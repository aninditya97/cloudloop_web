// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SummaryReport _$SummaryReportFromJson(Map<String, dynamic> json) =>
    SummaryReport(
      glucose: json['currentBloodGlucose'] == null
          ? null
          : SummaryReportItem.fromJson(
              json['currentBloodGlucose'] as Map<String, dynamic>),
      insulin: json['currentInsulinDelivery'] == null
          ? null
          : SummaryReportItem.fromJson(
              json['currentInsulinDelivery'] as Map<String, dynamic>),
      carbohydrate: json['currentCarbohydrate'] == null
          ? null
          : SummaryReportItem.fromJson(
              json['currentCarbohydrate'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SummaryReportToJson(SummaryReport instance) =>
    <String, dynamic>{
      'currentBloodGlucose': instance.glucose?.toJson(),
      'currentInsulinDelivery': instance.insulin?.toJson(),
      'currentCarbohydrate': instance.carbohydrate?.toJson(),
    };
