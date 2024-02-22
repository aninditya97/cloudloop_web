// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carbohydrate_report_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarbohydrateReportItem _$CarbohydrateReportItemFromJson(
        Map<String, dynamic> json) =>
    CarbohydrateReportItem(
      id: NumParser.intParse(json['id']),
      value: NumParser.doubleParse(json['value']),
      foodType: json['foodType'] == null
          ? null
          : FoodType.fromJson(json['foodType'] as Map<String, dynamic>),
      time: _$JsonConverterFromJson<String, DateTime>(
          json['time'], const DateTimeJsonConverter().fromJson),
      source: $enumDecode(_$ReportSourceEnumMap, json['source']),
      createdAt: _$JsonConverterFromJson<String, DateTime>(
          json['createdAt'], const DateTimeJsonConverter().fromJson),
      syncAt: _$JsonConverterFromJson<String, DateTime>(
          json['syncAt'], const DateTimeJsonConverter().fromJson),
      updatedAt: _$JsonConverterFromJson<String, DateTime>(
          json['updatedAt'], const DateTimeJsonConverter().fromJson),
      deletedAt: _$JsonConverterFromJson<String, DateTime>(
          json['deletedAt'], const DateTimeJsonConverter().fromJson),
    );

Map<String, dynamic> _$CarbohydrateReportItemToJson(
        CarbohydrateReportItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value': instance.value,
      'source': _$ReportSourceEnumMap[instance.source]!,
      'foodType': instance.foodType?.toJson(),
      'time': _$JsonConverterToJson<String, DateTime>(
          instance.time, const DateTimeJsonConverter().toJson),
      'createdAt': _$JsonConverterToJson<String, DateTime>(
          instance.createdAt, const DateTimeJsonConverter().toJson),
      'syncAt': _$JsonConverterToJson<String, DateTime>(
          instance.syncAt, const DateTimeJsonConverter().toJson),
      'deletedAt': _$JsonConverterToJson<String, DateTime>(
          instance.deletedAt, const DateTimeJsonConverter().toJson),
      'updatedAt': _$JsonConverterToJson<String, DateTime>(
          instance.updatedAt, const DateTimeJsonConverter().toJson),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

const _$ReportSourceEnumMap = {
  ReportSource.user: 'USER',
  ReportSource.sensor: 'SENSOR',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
