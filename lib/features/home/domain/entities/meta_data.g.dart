// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetaData _$MetaDataFromJson(Map<String, dynamic> json) => MetaData(
      current: (json['current'] as num?)?.toDouble(),
      page: json['page'] as int,
      perPage: json['perPage'] as int,
      totalData: json['totalData'] as int,
      message: json['message'] as String,
      statusCode: json['statusCode'] as int,
      totalPage: json['totalPage'] as int,
    );

Map<String, dynamic> _$MetaDataToJson(MetaData instance) => <String, dynamic>{
      'current': instance.current,
      'page': instance.page,
      'perPage': instance.perPage,
      'totalData': instance.totalData,
      'message': instance.message,
      'statusCode': instance.statusCode,
      'totalPage': instance.totalPage,
    };
