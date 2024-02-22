import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_profile_temporary_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class UpdateProfileTemporaryData extends Equatable {
  const UpdateProfileTemporaryData({
    required this.temporaryId,
    required this.userId,
    required this.name,
    required this.email,
    required this.avatar,
    this.birthDate,
    required this.gender,
    required this.weight,
    required this.totalDailyDose,
    required this.diabetesType,
  });

  factory UpdateProfileTemporaryData.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileTemporaryDataFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String temporaryId;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(fromJson: StringParser.parse)
  final String name;

  @JsonKey(fromJson: StringParser.parse)
  final String email;

  @JsonKey(fromJson: StringParser.parse)
  final String avatar;

  @JsonKey(fromJson: DateTime.tryParse)
  final DateTime? birthDate;

  @JsonKey(defaultValue: Gender.male)
  final Gender gender;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double weight;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double totalDailyDose;

  @JsonKey(defaultValue: DiabetesType.type1)
  final DiabetesType diabetesType;

  Map<String, dynamic> toJson() => _$UpdateProfileTemporaryDataToJson(this);

  @override
  List<Object?> get props => [
        temporaryId,
        userId,
        name,
        email,
        avatar,
        birthDate,
        gender,
        weight,
        totalDailyDose,
        diabetesType,
      ];
}
