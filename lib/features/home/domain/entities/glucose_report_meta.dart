import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glucose_report_meta.g.dart';

@JsonSerializable()
class GlucoseReportMeta extends Equatable {
  const GlucoseReportMeta({
    required this.current,
    required this.highest,
    required this.lowest,
    required this.average,
  });

  factory GlucoseReportMeta.fromJson(Map<String, dynamic> json) =>
      _$GlucoseReportMetaFromJson(json);

  @JsonKey(fromJson: NumParser.doubleParse)
  final double current;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double highest;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double lowest;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double average;

  Map<String, dynamic> toJson() => _$GlucoseReportMetaToJson(this);

  @override
  List<Object?> get props => [
        current,
        highest,
        lowest,
        average,
      ];
}
