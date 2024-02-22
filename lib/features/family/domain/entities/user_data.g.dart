// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      id: NumParser.intParse(json['id']),
      name: StringParser.parse(json['name']),
      email: StringParser.parse(json['email']),
      avatar: StringParser.parse(json['avatar']),
      birthDate: StringParser.parse(json['birthDate']),
      gender: StringParser.parse(json['gender']),
      diabetesType: NumParser.intParse(json['diabetesType']),
      weight: NumParser.intParse(json['weight']),
      totalDailyDose: NumParser.intParse(json['totalDailyDose']),
      currentBloodGlucose: NumParser.intParse(json['currentBloodGlucose']),
      connection: json['connection'] == null
          ? null
          : ConnectionData.fromJson(json['connection'] as Map<String, dynamic>),
      createdAt: _$JsonConverterFromJson<String, DateTime>(
          json['createdAt'], const DateTimeJsonConverter().fromJson),
      updatedAt: _$JsonConverterFromJson<String, DateTime>(
          json['updatedAt'], const DateTimeJsonConverter().fromJson),
      bloodGlucoses: (json['bloodGlucoses'] as List<dynamic>?)
          ?.map((e) => GlucoseReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      carbohydrates: (json['carbohydrates'] as List<dynamic>?)
          ?.map(
              (e) => CarbohydrateReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      insulinDeliveries: (json['insulinDeliveries'] as List<dynamic>?)
          ?.map((e) => InsulinReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] == null
          ? null
          : SummaryReport.fromJson(json['summary'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatar': instance.avatar,
      'birthDate': instance.birthDate,
      'gender': instance.gender,
      'diabetesType': instance.diabetesType,
      'weight': instance.weight,
      'totalDailyDose': instance.totalDailyDose,
      'currentBloodGlucose': instance.currentBloodGlucose,
      'connection': instance.connection?.toJson(),
      'createdAt': _$JsonConverterToJson<String, DateTime>(
          instance.createdAt, const DateTimeJsonConverter().toJson),
      'updatedAt': _$JsonConverterToJson<String, DateTime>(
          instance.updatedAt, const DateTimeJsonConverter().toJson),
      'bloodGlucoses': instance.bloodGlucoses?.map((e) => e.toJson()).toList(),
      'carbohydrates': instance.carbohydrates?.map((e) => e.toJson()).toList(),
      'insulinDeliveries':
          instance.insulinDeliveries?.map((e) => e.toJson()).toList(),
      'summary': instance.summary?.toJson(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
