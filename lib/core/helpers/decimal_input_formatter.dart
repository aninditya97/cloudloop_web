import 'dart:math' as math;

import 'package:flutter/services.dart';

/// TextFormatter for decimal input
class SetDecimalTextInputFormatter extends TextInputFormatter {
  SetDecimalTextInputFormatter({
    required this.decimalRange,
    this.activatedNegativeValues = false,
  }) : assert(decimalRange >= 0, 'DecimalTextInputFormatter declaretion error');

  final int decimalRange;
  final bool activatedNegativeValues;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    var newSelection = newValue.selection;
    var truncated = newValue.text;

    if (newValue.text.contains(' ')) {
      return oldValue;
    }

    if (newValue.text.isEmpty) {
      return newValue;
    } else if (double.tryParse(newValue.text) == null &&
        !(newValue.text.length == 1 &&
            (activatedNegativeValues == true) &&
            newValue.text == '-')) {
      return oldValue;
    }

    if (activatedNegativeValues == false &&
        (double.tryParse(newValue.text) ?? 0) < 0) {
      return oldValue;
    }

    final value = newValue.text;

    if (decimalRange == 0 && value.contains('.')) {
      truncated = oldValue.text;
      newSelection = oldValue.selection;
    }

    if (value.contains('.') &&
        value.substring(value.indexOf('.') + 1).length > decimalRange) {
      truncated = oldValue.text;
      newSelection = oldValue.selection;
    } else if (value == '.') {
      truncated = '0.';

      newSelection = newValue.selection.copyWith(
        baseOffset: math.min(truncated.length, truncated.length + 1),
        extentOffset: math.min(truncated.length, truncated.length + 1),
      );
    }

    return TextEditingValue(text: truncated, selection: newSelection);
  }
}
