import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Internet connection checker
/// Getting current info internet connection status
abstract class NetworkInfo {
  /// Get current status internet connection.
  /// Connected on Internet or not.
  ///
  /// - Return `true` when user/device has internet connection
  /// - Return `false` when user/device has't internet connection
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this.connectionChecker);

  final InternetConnectionCheckerPlus connectionChecker;

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
