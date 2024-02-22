import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/entities/enums/user_role.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_member_temporary_data.g.dart';

@JsonSerializable()
class FamilyMemberTemporaryData extends Equatable {
  const FamilyMemberTemporaryData({
    required this.id,
    required this.label,
    required this.role,
    required this.userId,
    required this.name,
    required this.email,
    required this.avatar,
    required this.birthDate,
    required this.gender,
    required this.diabetesType,
    required this.weight,
    required this.totalDailyDose,
    required this.currentBloodGlucose,
  });

  factory FamilyMemberTemporaryData.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberTemporaryDataFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int id;

  @JsonKey(fromJson: StringParser.parse)
  final String? label;

  @JsonKey(defaultValue: UserRole.member)
  final UserRole role;

  @JsonKey(name: 'user_id', fromJson: NumParser.intParse)
  final int userId;

  @JsonKey(fromJson: StringParser.parse)
  final String name;

  @JsonKey(fromJson: StringParser.parse)
  final String email;

  @JsonKey(fromJson: StringParser.parse)
  final String? avatar;

  @JsonKey(name: 'birth_date', fromJson: StringParser.parse)
  final String birthDate;

  @JsonKey(fromJson: StringParser.parse)
  final String gender;

  @JsonKey(fromJson: NumParser.intParse)
  final int diabetesType;

  @JsonKey(fromJson: NumParser.intParse)
  final int weight;

  @JsonKey(name: 'total_daily_dose', fromJson: NumParser.intParse)
  final int totalDailyDose;

  @JsonKey(fromJson: NumParser.intParse)
  final int currentBloodGlucose;

  Map<String, dynamic> toJson() => _$FamilyMemberTemporaryDataToJson(this);

  @override
  List<Object?> get props => [
        id,
        label,
        role,
        userId,
        name,
        email,
        avatar,
        birthDate,
        gender,
        diabetesType,
        weight,
        totalDailyDose,
        currentBloodGlucose,
      ];
}
