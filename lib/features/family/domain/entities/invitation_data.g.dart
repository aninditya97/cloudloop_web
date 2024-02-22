// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitationData _$InvitationDataFromJson(Map<String, dynamic> json) =>
    InvitationData(
      id: NumParser.intParse(json['id']),
      status: $enumDecode(_$InvitationStatusEnumMap, json['status']),
      source: json['source'] == null
          ? null
          : UserData.fromJson(json['source'] as Map<String, dynamic>),
      createdAt:
          const DateTimeJsonConverter().fromJson(json['createdAt'] as String),
      updatedAt:
          const DateTimeJsonConverter().fromJson(json['updatedAt'] as String),
    );

Map<String, dynamic> _$InvitationDataToJson(InvitationData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$InvitationStatusEnumMap[instance.status]!,
      'source': instance.source?.toJson(),
      'createdAt': const DateTimeJsonConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeJsonConverter().toJson(instance.updatedAt),
    };

const _$InvitationStatusEnumMap = {
  InvitationStatus.status1: 'ACCEPTED',
  InvitationStatus.status2: 'REJECTED',
  InvitationStatus.status3: 'PENDING',
};
