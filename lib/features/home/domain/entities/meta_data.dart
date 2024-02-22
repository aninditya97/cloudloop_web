import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meta_data.g.dart';

@JsonSerializable()
class MetaData extends Equatable {
  const MetaData({
    this.current,
    required this.page,
    required this.perPage,
    required this.totalData,
    required this.message,
    required this.statusCode,
    required this.totalPage,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) =>
      _$MetaDataFromJson(json);

  @JsonKey(name: 'current')
  final double? current;

  @JsonKey(name: 'page')
  final int page;

  @JsonKey(name: 'perPage')
  final int perPage;

  @JsonKey(name: 'totalData')
  final int totalData;

  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: 'statusCode')
  final int statusCode;

  @JsonKey(name: 'totalPage')
  final int totalPage;

  Map<String, dynamic> toJson() => _$MetaDataToJson(this);

  @override
  List<Object?> get props =>
      [current, page, perPage, totalData, message, statusCode, totalPage];
}
