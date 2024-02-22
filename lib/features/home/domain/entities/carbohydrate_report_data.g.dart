// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carbohydrate_report_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarbohydrateReportData _$CarbohydrateReportDataFromJson(
        Map<String, dynamic> json) =>
    CarbohydrateReportData(
      items: (json['data'] as List<dynamic>)
          .map(
              (e) => CarbohydrateReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CarbohydrateReportDataToJson(
        CarbohydrateReportData instance) =>
    <String, dynamic>{
      'data': instance.items.map((e) => e.toJson()).toList(),
    };
