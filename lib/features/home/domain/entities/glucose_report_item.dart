import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glucose_report_item.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class GlucoseReportItem extends Equatable {
  const GlucoseReportItem({
    required this.id,
    required this.value,
    required this.source,
    required this.userId,
    required this.time,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GlucoseReportItem.fromJson(Map<String, dynamic> json) =>
      _$GlucoseReportItemFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int id;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double value;

  final ReportSource source;

  @JsonKey(name: 'user_id')
  final int userId;

  final DateTime time;

  final GlucoseLevel level;

  final DateTime createdAt;

  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$GlucoseReportItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        value,
        source,
        userId,
        time,
        level,
        createdAt,
        updatedAt,
      ];
}
