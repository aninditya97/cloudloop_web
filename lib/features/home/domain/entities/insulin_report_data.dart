import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'insulin_report_data.g.dart';

@JsonSerializable()
class InsulinReportData extends Equatable {
  const InsulinReportData({
    required this.items,
    this.meta,
  });

  factory InsulinReportData.fromJson(Map<String, dynamic> json) =>
      _$InsulinReportDataFromJson(json);

  @JsonKey(name: 'data')
  final List<InsulinReportItem> items;

  final MetaData? meta;

  Map<String, dynamic> toJson() => _$InsulinReportDataToJson(this);

  @override
  List<Object?> get props => [items];
}
