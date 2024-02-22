import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/domain/entities/enums/input_source.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'summary_report_item.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class SummaryReportItem extends Equatable {
  const SummaryReportItem({
    required this.value,
    required this.date,
    required this.source,
    this.level,
    this.average,
    this.highest,
    this.lowest,
  });

  factory SummaryReportItem.fromJson(Map<String, dynamic> json) =>
      _$SummaryReportItemFromJson(json);

  @JsonKey(fromJson: NumParser.doubleParse)
  final double value;

  @JsonKey(name: 'time')
  final DateTime date;

  @JsonKey(defaultValue: InputSource.sensor)
  final InputSource source;

  @JsonKey(defaultValue: BloodGlucoseLevel.status1)
  final BloodGlucoseLevel? level;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double? average;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double? highest;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double? lowest;

  Map<String, dynamic> toJson() => _$SummaryReportItemToJson(this);

  @override
  List<Object?> get props => [
        value,
        date,
        level,
        source,
        average,
        highest,
        lowest,
      ];
}
