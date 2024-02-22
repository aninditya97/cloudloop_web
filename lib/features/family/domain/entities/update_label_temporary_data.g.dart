// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_label_temporary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLabelTemporaryData _$UpdateLabelTemporaryDataFromJson(
        Map<String, dynamic> json) =>
    UpdateLabelTemporaryData(
      temporaryId: json['temporary_id'] as String,
      familyMemberId: json['family_member_id'] as String,
      label: json['label'] as String,
      updatedAt:
          const DateTimeJsonConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$UpdateLabelTemporaryDataToJson(
        UpdateLabelTemporaryData instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'family_member_id': instance.familyMemberId,
      'label': instance.label,
      'updated_at': const DateTimeJsonConverter().toJson(instance.updatedAt),
    };
