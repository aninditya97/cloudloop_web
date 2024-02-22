import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_type.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class FoodType extends Equatable {
  const FoodType({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory FoodType.fromJson(Map<String, dynamic> json) =>
      _$FoodTypeFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int id;

  @JsonKey(fromJson: StringParser.parse)
  final String name;

  @JsonKey(fromJson: StringParser.parse)
  final String description;

  @JsonKey(fromJson: StringParser.parse)
  final String image;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$FoodTypeToJson(this);

  @override
  List<Object?> get props =>
      [id, name, description, image, createdAt, updatedAt];
}
