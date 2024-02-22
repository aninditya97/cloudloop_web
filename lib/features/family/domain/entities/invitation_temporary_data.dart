import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invitation_temporary_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class InvitationTemporaryData extends Equatable {
  const InvitationTemporaryData({
    required this.temporaryId,
    required this.email,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvitationTemporaryData.fromJson(Map<String, dynamic> json) =>
      _$InvitationTemporaryDataFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String temporaryId;

  final String email;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$InvitationTemporaryDataToJson(this);

  @override
  List<Object?> get props => [
        temporaryId,
        email,
        userId,
        createdAt,
        updatedAt,
      ];
}
