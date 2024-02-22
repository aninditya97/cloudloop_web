import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'carbohydrate_report_data.g.dart';

@JsonSerializable()
class CarbohydrateReportData extends Equatable {
  const CarbohydrateReportData({
    required this.items,
  });

  factory CarbohydrateReportData.fromJson(Map<String, dynamic> json) =>
      _$CarbohydrateReportDataFromJson(json);

  @JsonKey(name: 'data')
  final List<CarbohydrateReportItem> items;

  Map<String, dynamic> toJson() => _$CarbohydrateReportDataToJson(this);

  @override
  List<Object?> get props => [items];
}
