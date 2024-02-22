import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_meta_date.g.dart';

@JsonSerializable()
class ReportMetaDate extends Equatable {
  const ReportMetaDate({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  factory ReportMetaDate.fromJson(Map<String, dynamic> json) =>
      _$ReportMetaDateFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int days;

  @JsonKey(fromJson: NumParser.intParse)
  final int hours;

  @JsonKey(fromJson: NumParser.intParse)
  final int minutes;

  @JsonKey(fromJson: NumParser.intParse)
  final int seconds;

  Map<String, dynamic> toJson() => _$ReportMetaDateToJson(this);

  @override
  List<Object?> get props => [
        days,
        hours,
        minutes,
        seconds,
      ];
}
