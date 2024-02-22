import 'dart:typed_data';

class Extensions {
  static String bytesToHex(List<int> inList) {
    final builder = StringBuffer();
    for (int i = 0; i < inList.length; i++) {
      builder.write(inList[i].toRadixString(16).padLeft(2, '0'));
    }
    return builder.toString();
  }

  static List<int> hexToBytes(String s) {
    int len = s.length;
    final data = Uint8List(len ~/ 2);
    for (int i = 0; i < len; i += 2) {
      data[i ~/ 2] = int.parse(s.substring(i, i + 2), radix: 16);
    }
    return data;
  }

  static String lastTwoCharactersOfString(String? s) {
    if (s == null) return 'NULL';
    return s.length > 1 ? s.substring(s.length - 2) : 'ERR-$s';
  }

  static void doSleep(int time) {
    try {
      Future<void>.delayed(Duration(milliseconds: time));
    } catch (e) {
      print(e);
    }
  }
}
