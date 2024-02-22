// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_invitation_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInvitationData _$UserInvitationDataFromJson(Map<String, dynamic> json) =>
    UserInvitationData(
      items: (json['data'] as List<dynamic>?)
          ?.map((e) => InvitationData.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaData.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserInvitationDataToJson(UserInvitationData instance) =>
    <String, dynamic>{
      'data': instance.items?.map((e) => e.toJson()).toList(),
      'meta': instance.meta.toJson(),
    };
