import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.birthDate,
    required this.gender,
    required this.weight,
    required this.totalDailyDose,
    // required this.diabetesType,
    this.basalRate,
    this.insulinCarbRatio,
    this.insulinSensitivityFactor,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  @JsonKey(fromJson: StringParser.parse)
  final String id;

  @JsonKey(fromJson: StringParser.parse)
  final String name;

  @JsonKey(fromJson: StringParser.parse)
  final String? email;

  @JsonKey(fromJson: StringParser.parse)
  final String? avatar;

  @JsonKey(fromJson: DateTime.tryParse)
  final DateTime? birthDate;

  @JsonKey(defaultValue: Gender.male)
  final Gender gender;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double weight;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double totalDailyDose;

  // @JsonKey(defaultValue: DiabetesType.type1)
  // final DiabetesType diabetesType;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double? basalRate;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double? insulinCarbRatio;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double? insulinSensitivityFactor;

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatar,
        birthDate,
        gender,
        weight,
        totalDailyDose,
        // diabetesType,
        basalRate,
        insulinCarbRatio,
        insulinSensitivityFactor,
      ];

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? birthDate,
    Gender? gender,
    double? weight,
    double? totalDailyDose,
    // DiabetesType? diabetesType,
    double? basalRate,
    double? insulinCarbRatio,
    double? insulinSensitivityFactor,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      totalDailyDose: totalDailyDose ?? this.totalDailyDose,
      // diabetesType: diabetesType ?? this.diabetesType,
      basalRate: basalRate ?? this.basalRate,
      insulinCarbRatio: insulinCarbRatio ?? this.insulinCarbRatio,
      insulinSensitivityFactor:
          insulinSensitivityFactor ?? this.insulinSensitivityFactor,
    );
  }
}
