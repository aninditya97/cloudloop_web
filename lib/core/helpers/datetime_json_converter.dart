import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

class DateTimeJsonConverter implements JsonConverter<DateTime, String> {
  const DateTimeJsonConverter();

  @override
  DateTime fromJson(String json) {
   //kai_20231030 blocked  return DateTime.parse(json).toLocal();
    final f = DateFormat('yyyy-MM-dd HH:mm:ss');
    return DateTime.parse(f.format(DateTime.parse(json)));
  }

  @override
  String toJson(DateTime json) => json.toIso8601String();
}
