// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodType _$FoodTypeFromJson(Map<String, dynamic> json) => FoodType(
      id: NumParser.intParse(json['id']),
      name: StringParser.parse(json['name']),
      description: StringParser.parse(json['description']),
      image: StringParser.parse(json['image']),
      createdAt: _$JsonConverterFromJson<String, DateTime>(
          json['createdAt'], const DateTimeJsonConverter().fromJson),
      updatedAt: _$JsonConverterFromJson<String, DateTime>(
          json['updatedAt'], const DateTimeJsonConverter().fromJson),
    );

Map<String, dynamic> _$FoodTypeToJson(FoodType instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'image': instance.image,
      'createdAt': _$JsonConverterToJson<String, DateTime>(
          instance.createdAt, const DateTimeJsonConverter().toJson),
      'updatedAt': _$JsonConverterToJson<String, DateTime>(
          instance.updatedAt, const DateTimeJsonConverter().toJson),
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
