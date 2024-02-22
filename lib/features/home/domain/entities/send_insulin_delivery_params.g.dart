// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_insulin_delivery_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendInsulinDeliveryParams _$SendInsulinDeliveryParamsFromJson(
        Map<String, dynamic> json) =>
    SendInsulinDeliveryParams(
      temporaryId: json['temporary_id'] as String?,
      value: NumParser.doubleParse(json['value']),
      source: json['source'] as String,
      time: json['time'] as String?,
      userId: json['user_id'] as int?,
      announceMealEnabled: json['announce_meal_enabled'] as bool?,
      autoModeEnabled: json['auto_mode_enabled'] as bool?,
      iob: (json['iob'] as num?)?.toDouble(),
      hypoPrevention: json['hypoPrevention'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$SendInsulinDeliveryParamsToJson(
        SendInsulinDeliveryParams instance) =>
    <String, dynamic>{
      'temporary_id': instance.temporaryId,
      'value': instance.value,
      'source': instance.source,
      'time': instance.time,
      'user_id': instance.userId,
      'announce_meal_enabled': instance.announceMealEnabled,
      'auto_mode_enabled': instance.autoModeEnabled,
      'iob': instance.iob,
      'hypoPrevention': instance.hypoPrevention,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
