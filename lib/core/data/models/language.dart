import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'language.g.dart';

@JsonSerializable()
class Language extends Equatable {
  const Language({
    required this.code,
    required this.name,
    required this.flag,
  });

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);

  @JsonKey(fromJson: StringParser.parse)
  final String code;

  @JsonKey(fromJson: StringParser.parse)
  final String name;

  @JsonKey(fromJson: StringParser.parse)
  final String flag;

  Map<String, dynamic> toJson() => _$LanguageToJson(this);

  Language copyWith({
    String? code,
    String? name,
    String? flag,
  }) {
    return Language(
      code: code ?? this.code,
      name: name ?? this.name,
      flag: flag ?? this.flag,
    );
  }

  @override
  List<Object?> get props => [code, name, flag];
}
