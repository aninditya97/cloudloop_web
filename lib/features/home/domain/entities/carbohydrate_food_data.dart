import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'carbohydrate_food_data.g.dart';

@JsonSerializable()
class CarbohydrateFoodData extends Equatable {
  const CarbohydrateFoodData({
    required this.items,
    this.meta,
  });

  factory CarbohydrateFoodData.fromJson(Map<String, dynamic> json) =>
      _$CarbohydrateFoodDataFromJson(json);

  @JsonKey(name: 'data')
  final List<FoodType> items;

  final MetaData? meta;

  Map<String, dynamic> toJson() => _$CarbohydrateFoodDataToJson(this);

  @override
  List<Object?> get props => [items, meta];
}
