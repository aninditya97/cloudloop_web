import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'insulin_report_item.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class InsulinReportItem extends Equatable {
  const InsulinReportItem({
    required this.id,
    required this.source,
    required this.value,
    required this.time,
    this.announceMealEnabled,
    this.autoModeEnabled,
    required this.iob,
    required this.userId,
    this.hypoPrevention,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InsulinReportItem.fromJson(Map<String, dynamic> json) =>
      _$InsulinReportItemFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int id;

  final ReportSource source;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double value;

  final DateTime time;

  final bool? announceMealEnabled;

  final bool? autoModeEnabled;

  final String iob;

  @JsonKey(name: 'user_id')
  final int userId;

  @JsonKey(fromJson: BoolParser.boolParse)
  final bool? hypoPrevention;

  final DateTime createdAt;

  final DateTime updatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'source': _$ReportSourceEnumMap[source],
        'value': value,
        'time': const DateTimeJsonConverter().toJson(time),
        'announce_meal_enabled': announceMealEnabled,
        'auto_mode_enabled': autoModeEnabled,
        'iob': iob,
        'user_id': userId,
        'hypoPrevention': hypoPrevention,
        'createdAt': const DateTimeJsonConverter().toJson(createdAt),
        'updatedAt': const DateTimeJsonConverter().toJson(updatedAt),
      };

  @override
  List<Object?> get props => [
        id,
        source,
        value,
        time,
        announceMealEnabled,
        autoModeEnabled,
        iob,
        hypoPrevention,
        createdAt,
        updatedAt,
      ];
}
