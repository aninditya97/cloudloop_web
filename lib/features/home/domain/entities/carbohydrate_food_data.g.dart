// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carbohydrate_food_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarbohydrateFoodData _$CarbohydrateFoodDataFromJson(
        Map<String, dynamic> json) =>
    CarbohydrateFoodData(
      items: (json['data'] as List<dynamic>)
          .map((e) => FoodType.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : MetaData.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CarbohydrateFoodDataToJson(
        CarbohydrateFoodData instance) =>
    <String, dynamic>{
      'data': instance.items.map((e) => e.toJson()).toList(),
      'meta': instance.meta?.toJson(),
    };
