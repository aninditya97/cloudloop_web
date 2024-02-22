import 'package:intl/intl.dart';

extension NumberExtension on num {
  String format() {
    return NumberFormat.decimalPattern().format(this);
  }
}
