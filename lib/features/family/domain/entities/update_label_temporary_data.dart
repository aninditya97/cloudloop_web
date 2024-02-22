import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_label_temporary_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class UpdateLabelTemporaryData extends Equatable {
  const UpdateLabelTemporaryData({
    required this.temporaryId,
    required this.familyMemberId,
    required this.label,
    required this.updatedAt,
  });

  factory UpdateLabelTemporaryData.fromJson(Map<String, dynamic> json) =>
      _$UpdateLabelTemporaryDataFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String temporaryId;

  @JsonKey(name: 'family_member_id')
  final String familyMemberId;

  final String label;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$UpdateLabelTemporaryDataToJson(this);

  @override
  List<Object?> get props => [temporaryId, familyMemberId, label, updatedAt];
}
