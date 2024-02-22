import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glucose_report_meta_level.g.dart';

@JsonSerializable()
class GlucoseReportMetaLevel extends Equatable {
  const GlucoseReportMetaLevel({
    this.percentage,
    this.dates,
  });

  factory GlucoseReportMetaLevel.fromJson(Map<String, dynamic> json) =>
      _$GlucoseReportMetaLevelFromJson(json);

  @JsonKey(fromJson: NumParser.doubleParse)
  final double? percentage;

  final ReportMetaDate? dates;

  Map<String, dynamic> toJson() => _$GlucoseReportMetaLevelToJson(this);

  @override
  List<Object?> get props => [percentage, dates];
}
