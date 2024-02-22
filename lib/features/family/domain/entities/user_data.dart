import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/domain.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class UserData extends Equatable {
  const UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.birthDate,
    required this.gender,
    required this.diabetesType,
    required this.weight,
    required this.totalDailyDose,
    required this.currentBloodGlucose,
    this.connection,
    this.createdAt,
    this.updatedAt,
    this.bloodGlucoses,
    this.carbohydrates,
    this.insulinDeliveries,
    this.summary,
  });

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int id;

  @JsonKey(fromJson: StringParser.parse)
  final String name;

  @JsonKey(fromJson: StringParser.parse)
  final String email;

  @JsonKey(fromJson: StringParser.parse)
  final String? avatar;

  @JsonKey(fromJson: StringParser.parse)
  final String birthDate;

  @JsonKey(fromJson: StringParser.parse)
  final String gender;

  @JsonKey(fromJson: NumParser.intParse)
  final int diabetesType;

  @JsonKey(fromJson: NumParser.intParse)
  final int weight;

  @JsonKey(fromJson: NumParser.intParse)
  final int totalDailyDose;

  @JsonKey(fromJson: NumParser.intParse)
  final int currentBloodGlucose;

  final ConnectionData? connection;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  @JsonKey(name: 'bloodGlucoses')
  final List<GlucoseReportItem>? bloodGlucoses;

  @JsonKey(name: 'carbohydrates')
  final List<CarbohydrateReportItem>? carbohydrates;

  @JsonKey(name: 'insulinDeliveries')
  final List<InsulinReportItem>? insulinDeliveries;

  @JsonKey(name: 'summary')
  final SummaryReport? summary;

  Map<String, dynamic> toJson() => _$UserDataToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatar,
        birthDate,
        gender,
        diabetesType,
        weight,
        totalDailyDose,
        currentBloodGlucose,
        createdAt,
        updatedAt,
        bloodGlucoses,
        carbohydrates,
        insulinDeliveries,
        summary,
      ];
}
