import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'remove_temporary_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class RemoveTemporaryData extends Equatable {
  const RemoveTemporaryData({
    required this.temporaryId,
    required this.familyMemberId,
    required this.userId,
    required this.deletedAt,
  });

  factory RemoveTemporaryData.fromJson(Map<String, dynamic> json) =>
      _$RemoveTemporaryDataFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String temporaryId;

  @JsonKey(name: 'family_member_id')
  final String familyMemberId;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'deleted_at')
  final DateTime deletedAt;

  Map<String, dynamic> toJson() => _$RemoveTemporaryDataToJson(this);

  @override
  List<Object?> get props => [temporaryId, userId, familyMemberId, deletedAt];
}
