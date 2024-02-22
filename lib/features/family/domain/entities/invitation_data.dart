import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invitation_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class InvitationData extends Equatable {
  const InvitationData({
    required this.id,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvitationData.fromJson(Map<String, dynamic> json) =>
      _$InvitationDataFromJson(json);

  @JsonKey(fromJson: NumParser.intParse)
  final int id;

  final InvitationStatus status;

  final UserData? source;

  final DateTime createdAt;

  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$InvitationDataToJson(this);

  @override
  List<Object?> get props => [id, status, source, createdAt, updatedAt];
}
