import 'dart:convert';

class IJILog {
  IJILog({
    required this.time,
    required this.type,
    required this.data,
    required this.report,
  });
  factory IJILog.fromBytes(List<int> bytes) {
    final time = bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3];
    final type = bytes[4];
    //Map<String, dynamic> data = json.decode(utf8.decode(bytes.sublist(5, 15)));
    var data = bytes[5].toString();
    data = data.substring(0, 14);
    final report = bytes[15];
    return IJILog(time: time, type: type, data: data, report: report);
  }
  int time;
  int type;
  //Map<String, dynamic> data;
  String data;
  int report;

  List<int> toBytes() {
    final bytes = <int>[
      time >> 24 & 0xff,
      time >> 16 & 0xff,
      time >> 8 & 0xff,
      time & 0xff,
      type,
      ...utf8.encode(json.encode(data)).sublist(0, 10),
      report
    ];
    return bytes;
  }
}
