// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchUserData _$SearchUserDataFromJson(Map<String, dynamic> json) =>
    SearchUserData(
      items: (json['data'] as List<dynamic>?)
          ?.map((e) => UserData.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaData.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchUserDataToJson(SearchUserData instance) =>
    <String, dynamic>{
      'data': instance.items?.map((e) => e.toJson()).toList(),
      'meta': instance.meta.toJson(),
    };
