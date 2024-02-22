import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_user_data.g.dart';

@JsonSerializable()
class SearchUserData extends Equatable {
  const SearchUserData({
    this.items,
    required this.meta,
  });

  factory SearchUserData.fromJson(Map<String, dynamic> json) =>
      _$SearchUserDataFromJson(json);

  @JsonKey(name: 'data')
  final List<UserData>? items;

  final MetaData meta;

  Map<String, dynamic> toJson() => _$SearchUserDataToJson(this);

  @override
  List<Object?> get props => [items, meta];
}
