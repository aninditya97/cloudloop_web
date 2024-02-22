import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accepted_temporary_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class AcceptedTemporaryData extends Equatable {
  const AcceptedTemporaryData({
    required this.temporaryId,
    required this.invitationId,
    required this.userId,
    required this.acceptedAt,
  });

  factory AcceptedTemporaryData.fromJson(Map<String, dynamic> json) =>
      _$AcceptedTemporaryDataFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String temporaryId;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'invitation_id')
  final String invitationId;

  @JsonKey(name: 'accepted_at')
  final DateTime acceptedAt;

  Map<String, dynamic> toJson() => _$AcceptedTemporaryDataToJson(this);

  @override
  List<Object?> get props => [temporaryId, userId, invitationId, acceptedAt];
}
