import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/entities/enums/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'xdrip_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class XdripData extends Equatable {
  const XdripData({
    required this.glucose,
    required this.timestamp,
    required this.raw,
    required this.direction,
    required this.source,
  });

  factory XdripData.fromJson(Map<String, dynamic> json) =>
      _$XdripDataFromJson(json);

  final String glucose;

  final String timestamp;

  final String raw;

  final Directions direction;

  final String source;

  Map<String, dynamic> toJson() => _$XdripDataToJson(this);

  @override
  List<Object?> get props => [
        glucose,
        timestamp,
        raw,
        direction,
        source,
      ];
}
