// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insulin_report_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InsulinReportData _$InsulinReportDataFromJson(Map<String, dynamic> json) =>
    InsulinReportData(
      items: (json['data'] as List<dynamic>)
          .map((e) => InsulinReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : MetaData.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InsulinReportDataToJson(InsulinReportData instance) =>
    <String, dynamic>{
      'data': instance.items.map((e) => e.toJson()).toList(),
      'meta': instance.meta?.toJson(),
    };
