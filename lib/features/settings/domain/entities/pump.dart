import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pump.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class PumpData extends Equatable {
  const PumpData({
    required this.id,
    required this.name,
    required this.status,
    this.connectAt,
  });

  factory PumpData.fromJson(Map<String, dynamic> json) =>
      _$PumpDataFromJson(json);

  @JsonKey(name: 'id')
  final String id;

  @JsonKey(fromJson: StringParser.parse)
  final String name;

  final bool status;

  @JsonKey(name: 'connect_at', fromJson: DateTime.tryParse)
  final DateTime? connectAt;

  Map<String, dynamic> toJson() => _$PumpDataToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        status,
        connectAt,
      ];
}
