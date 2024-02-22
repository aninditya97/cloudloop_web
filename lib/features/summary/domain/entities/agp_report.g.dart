// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agp_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AGPReport _$AGPReportFromJson(Map<String, dynamic> json) => AGPReport(
      averageGlucose: (json['average_glucose'] as num?)?.toDouble() ?? 0,
      gmiPercentage: (json['gmi_percentage'] as num?)?.toDouble() ?? 0,
      gmiMmol: (json['gmi_mmol_mol'] as num?)?.toDouble() ?? 0,
      glucoseSd: (json['glucose_sd'] as num?)?.toDouble() ?? 0,
      glucoseCv: (json['glucose_cv'] as num?)?.toDouble() ?? 0,
      timeInTarget: (json['time_in_target'] as num?)?.toDouble() ?? 0,
      timeAboveTarget: (json['time_above_target'] as num?)?.toDouble() ?? 0,
      timeBelowTarget: (json['time_below_target'] as num?)?.toDouble() ?? 0,
      numberOfHypos: (json['number_of_hypos'] as num?)?.toDouble() ?? 0,
      averageHypoDuration:
          (json['average_hypo_duration'] as num?)?.toDouble() ?? 0,
      sensorGlucoseAvailability:
          (json['sensor_glucose_availability'] as num?)?.toDouble() ?? 0,
      autoModeUse: (json['auto_mode_use'] as num?)?.toDouble() ?? 0,
      autoModeIntterupted:
          (json['auto_mode_intterupted'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$AGPReportToJson(AGPReport instance) => <String, dynamic>{
      'average_glucose': instance.averageGlucose,
      'gmi_percentage': instance.gmiPercentage,
      'gmi_mmol_mol': instance.gmiMmol,
      'glucose_sd': instance.glucoseSd,
      'glucose_cv': instance.glucoseCv,
      'time_in_target': instance.timeInTarget,
      'time_below_target': instance.timeBelowTarget,
      'time_above_target': instance.timeAboveTarget,
      'number_of_hypos': instance.numberOfHypos,
      'average_hypo_duration': instance.averageHypoDuration,
      'sensor_glucose_availability': instance.sensorGlucoseAvailability,
      'auto_mode_use': instance.autoModeUse,
      'auto_mode_intterupted': instance.autoModeIntterupted,
    };
