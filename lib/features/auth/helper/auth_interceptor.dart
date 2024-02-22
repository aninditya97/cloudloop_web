import 'dart:developer';

import 'package:cloudloop_mobile/app/routes.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/blocs.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthHttpInterceptor extends Interceptor {
  AuthHttpInterceptor({
    required this.source,
    required this.dio,
  });

  /// Cache souce
  final GetCurrentTokenUsecase source;
  final Dio dio;

  @override
  Future onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final headers = await _getHeaders();
      log('HEADERS: $headers', name: 'NETWORK');

      // Set token in headers
      options.headers.addAll(headers);
    } on ErrorException catch (e) {
      log('TOKEN ERROR: ${e.message}');
    } catch (e) {
      log('TOKEN ERROR: $e');
    } finally {
      handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      // final context = AppRouter.navigatorKey.currentContext;
      // if (context != null) {
      //   BlocProvider.of<AuthenticationBloc>(context)
      //       .add(const AuthenticationLogoutRequested());
      //   AppRouter.router.go('/');
      // }
    }

    handler.next(err);
  }

  // Getting all custom headers every request http
  Future<Map<String, dynamic>> _getHeaders() async {
    final headers = <String, dynamic>{};
    try {
      final result = await source(const NoParams());
      result.fold(
        (failure) {},
        (token) {
          headers.putIfAbsent('Authorization', () => 'Bearer $token');
        },
      );
    } catch (_) {
      log('TOKEN ERROR: $_');
    }

    return headers;
  }
}
