import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_invitation_data.g.dart';

@JsonSerializable()
class UserInvitationData extends Equatable {
  const UserInvitationData({
    this.items,
    required this.meta,
  });

  factory UserInvitationData.fromJson(Map<String, dynamic> json) =>
      _$UserInvitationDataFromJson(json);

  @JsonKey(name: 'data')
  final List<InvitationData>? items;

  final MetaData meta;

  Map<String, dynamic> toJson() => _$UserInvitationDataToJson(this);

  @override
  List<Object?> get props => [items, meta];
}
