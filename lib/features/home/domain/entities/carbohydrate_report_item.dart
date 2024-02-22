import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'carbohydrate_report_item.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class CarbohydrateReportItem extends Equatable {
  const CarbohydrateReportItem({
    required this.id,
    required this.value,
    required this.foodType,
    this.time,
    required this.source,
    this.createdAt,
    this.syncAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory CarbohydrateReportItem.fromJson(Map<String, dynamic> json) =>
      _$CarbohydrateReportItemFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int id;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double value;

  final ReportSource source;

  final FoodType? foodType;

  final DateTime? time;

  final DateTime? createdAt;

  final DateTime? syncAt;

  final DateTime? deletedAt;

  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$CarbohydrateReportItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        value,
        foodType,
        time,
        source,
        createdAt,
        syncAt,
        deletedAt,
        updatedAt,
      ];
}
