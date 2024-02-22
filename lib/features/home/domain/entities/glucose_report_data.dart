import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glucose_report_data.g.dart';

@JsonSerializable()
class GlucoseReportData extends Equatable {
  const GlucoseReportData({
    required this.items,
    this.meta,
    this.veryHeightLevel,
    this.highLevel,
    this.normalLevel,
    this.lowLevel,
    this.veryLowLevel,
  });

  factory GlucoseReportData.fromJson(Map<String, dynamic> json) =>
      _$GlucoseReportDataFromJson(json);

  @JsonKey(name: 'data')
  final List<GlucoseReportItem> items;

  final GlucoseReportMeta? meta;

  @JsonKey(name: 'veryHigh')
  final GlucoseReportMetaLevel? veryHeightLevel;

  @JsonKey(name: 'high')
  final GlucoseReportMetaLevel? highLevel;

  @JsonKey(name: 'normal')
  final GlucoseReportMetaLevel? normalLevel;

  @JsonKey(name: 'low')
  final GlucoseReportMetaLevel? lowLevel;

  @JsonKey(name: 'veryLow')
  final GlucoseReportMetaLevel? veryLowLevel;

  Map<String, dynamic> toJson() => _$GlucoseReportDataToJson(this);

  @override
  List<Object?> get props => [
        items,
        meta,
        veryHeightLevel,
        highLevel,
        normalLevel,
        lowLevel,
        veryHeightLevel,
      ];
}
