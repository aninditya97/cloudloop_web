import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_insulin_delivery_params.g.dart';

@JsonSerializable()
class SendInsulinDeliveryParams extends Equatable {
  const SendInsulinDeliveryParams({
    this.temporaryId,
    required this.value,
    required this.source,
    this.time,
    this.userId,
    this.announceMealEnabled,
    this.autoModeEnabled,
    this.iob,
    this.hypoPrevention,
    this.createdAt,
    this.updatedAt,
  });

  factory SendInsulinDeliveryParams.fromJson(Map<String, dynamic> json) =>
      _$SendInsulinDeliveryParamsFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String? temporaryId;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double value;

  final String source;

  final String? time;

  @JsonKey(name: 'user_id')
  final int? userId;

  @JsonKey(name: 'announce_meal_enabled')
  final bool? announceMealEnabled;

  @JsonKey(name: 'auto_mode_enabled')
  final bool? autoModeEnabled;

  final double? iob;

  final int? hypoPrevention;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Map<String, dynamic> toJson() => _$SendInsulinDeliveryParamsToJson(this);

  @override
  List<Object?> get props => [
        temporaryId,
        value,
        source,
        time,
        announceMealEnabled,
        autoModeEnabled,
        userId,
        iob,
        hypoPrevention,
        createdAt,
        updatedAt,
      ];
}
