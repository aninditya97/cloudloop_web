import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agp_report.g.dart';

@JsonSerializable()
class AGPReport extends Equatable {
  const AGPReport({
    required this.averageGlucose,
    required this.gmiPercentage,
    required this.gmiMmol,
    required this.glucoseSd,
    required this.glucoseCv,
    required this.timeInTarget,
    required this.timeAboveTarget,
    required this.timeBelowTarget,
    required this.numberOfHypos,
    required this.averageHypoDuration,
    required this.sensorGlucoseAvailability,
    required this.autoModeUse,
    required this.autoModeIntterupted,
  });

  factory AGPReport.fromJson(Map<String, dynamic> json) =>
      _$AGPReportFromJson(json);

  @JsonKey(name: 'average_glucose', defaultValue: 0)
  final double? averageGlucose;

  @JsonKey(name: 'gmi_percentage', defaultValue: 0)
  final double? gmiPercentage;

  @JsonKey(name: 'gmi_mmol_mol', defaultValue: 0)
  final double? gmiMmol;

  @JsonKey(name: 'glucose_sd', defaultValue: 0)
  final double? glucoseSd;

  @JsonKey(name: 'glucose_cv', defaultValue: 0)
  final double? glucoseCv;

  @JsonKey(name: 'time_in_target', defaultValue: 0)
  final double? timeInTarget;

  @JsonKey(name: 'time_below_target', defaultValue: 0)
  final double? timeBelowTarget;

  @JsonKey(name: 'time_above_target', defaultValue: 0)
  final double? timeAboveTarget;

  @JsonKey(name: 'number_of_hypos', defaultValue: 0)
  final double? numberOfHypos;

  @JsonKey(name: 'average_hypo_duration', defaultValue: 0)
  final double? averageHypoDuration;

  @JsonKey(name: 'sensor_glucose_availability', defaultValue: 0)
  final double? sensorGlucoseAvailability;

  // @JsonKey(name: 'total_daily_dose', defaultValue: 0)
  // final double? totalDailyDose;

  // @JsonKey(name: 'total_daily_bolus', defaultValue: 0)
  // final double? totalDailyBolus;

  // @JsonKey(name: 'total_daily_basal', defaultValue: 0)
  // final double? totalDailyBasal;

  @JsonKey(name: 'auto_mode_use', defaultValue: 0)
  final double? autoModeUse;

  @JsonKey(name: 'auto_mode_intterupted', defaultValue: 0)
  final double? autoModeIntterupted;

  Map<String, dynamic> toJson() => _$AGPReportToJson(this);

  @override
  List<Object?> get props => [
        averageGlucose,
        gmiPercentage,
        gmiMmol,
        glucoseSd,
        glucoseCv,
        timeInTarget,
        timeAboveTarget,
        timeBelowTarget,
        numberOfHypos,
        averageHypoDuration,
        sensorGlucoseAvailability,
        autoModeUse,
        autoModeIntterupted,
      ];
}
