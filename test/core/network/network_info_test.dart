import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mocktail/mocktail.dart';

class MockInternetConnectionChecker extends Mock
    implements InternetConnectionCheckerPlus {}

void main() {
  late NetworkInfoImpl networkInfo;
  late MockInternetConnectionChecker mockInternetConnectionChecker;

  setUp(() {
    mockInternetConnectionChecker = MockInternetConnectionChecker();
    networkInfo = NetworkInfoImpl(mockInternetConnectionChecker);
  });

  group('core/network/', () {
    test(
      'should forward the call to InternetConnectionChecker.hasConnection',
      () async {
        // arrange
        final tHasConnectionFuture = Future.value(true);

        when(() => mockInternetConnectionChecker.hasConnection)
            .thenAnswer((_) => tHasConnectionFuture);

        // actual
        final result = networkInfo.isConnected;

        // assert
        verify(() => mockInternetConnectionChecker.hasConnection).called(1);
        expect(result, tHasConnectionFuture);
      },
    );
  });
}
