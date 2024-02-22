import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/entities/enums/user_role.dart';
import 'package:cloudloop_mobile/features/family/domain/entities/user_data.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_data.g.dart';

@JsonSerializable()
class FamilyData extends Equatable {
  const FamilyData({
    required this.id,
    required this.label,
    required this.role,
    required this.user,
  });

  factory FamilyData.fromJson(Map<String, dynamic> json) =>
      _$FamilyDataFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int id;

  @JsonKey(fromJson: StringParser.parse)
  final String? label;

  @JsonKey(defaultValue: UserRole.member)
  final UserRole role;

  final UserData? user;

  Map<String, dynamic> toJson() => _$FamilyDataToJson(this);

  @override
  List<Object?> get props => [id, label, role, user];
}
