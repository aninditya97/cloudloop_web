import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'summary_report.g.dart';

@JsonSerializable()
class SummaryReport extends Equatable {
  const SummaryReport({
    required this.glucose,
    required this.insulin,
    required this.carbohydrate,
  });

  factory SummaryReport.fromJson(Map<String, dynamic> json) =>
      _$SummaryReportFromJson(json);

  @JsonKey(name: 'currentBloodGlucose')
  final SummaryReportItem? glucose;

  @JsonKey(name: 'currentInsulinDelivery')
  final SummaryReportItem? insulin;

  @JsonKey(name: 'currentCarbohydrate')
  final SummaryReportItem? carbohydrate;

  Map<String, dynamic> toJson() => _$SummaryReportToJson(this);

  @override
  List<Object?> get props => [glucose, insulin, carbohydrate];
}
