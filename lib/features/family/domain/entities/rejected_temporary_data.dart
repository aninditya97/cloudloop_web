import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rejected_temporary_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class RejactedTemporaryData extends Equatable {
  const RejactedTemporaryData({
    required this.temporaryId,
    required this.invitationId,
    required this.userId,
    required this.rejactedAt,
  });

  factory RejactedTemporaryData.fromJson(Map<String, dynamic> json) =>
      _$RejactedTemporaryDataFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String temporaryId;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'invitation_id')
  final String invitationId;

  @JsonKey(name: 'rejacted_at')
  final DateTime rejactedAt;

  Map<String, dynamic> toJson() => _$RejactedTemporaryDataToJson(this);

  @override
  List<Object?> get props => [temporaryId, userId, invitationId, rejactedAt];
}
