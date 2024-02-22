///
/// Utilities Class for parsing bool values
///
class BoolParser {
  /// A function to parse dynamic [value] to String.
  /// And for [fallbackValue] is mandatory because when there is an error
  /// in parse it will return the value of [fallbackValue].
  static bool boolParse(dynamic value, {bool fallbackValue = false}) {
    return tryParse(value) ?? fallbackValue;
  }

  /// Parse [value] as a, possibly signed, bool literal.
  ///
  /// Like [boolParse] except that this function returns `null` where a
  /// similar call to [boolParse] for invalid input [value].
  static bool? tryParse(dynamic value) {
    if (value is bool) {
      return value;
    } else if (value is num) {
      return value == 1;
    }

    return null;
  }
}
