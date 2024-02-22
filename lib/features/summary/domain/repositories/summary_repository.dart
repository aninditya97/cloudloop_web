import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/database/database.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

abstract class SummaryRepository {
  Future<SummaryReport> summary({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<AGPReport> agpReport({
    int? page,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  });
}

class SummaryRepositoryImpl
    with ServiceNetworkHandlerMixin
    implements SummaryRepository {
  const SummaryRepositoryImpl({
    required this.httpClient,
    required this.localDatabase,
    required this.checkConnection,
  });

  final Dio httpClient;
  final DatabaseHelper localDatabase;
  final NetworkInfo checkConnection;

  @override
  Future<SummaryReport> summary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return get<SummaryReport>(
      '/users/summary',
      httpClient: httpClient,
      queryParameters: <String, dynamic>{
        'fromDate': startDate != null
            ? DateFormat('yyyy-MM-dd').format(startDate)
            : null,
        'toDate':
            endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      },
      onSuccess: (response) async {
        return SummaryReport.fromJson(
          (response.data as Map)['data'] as Map<String, dynamic>,
        );
      },
    );
  }

  @override
  Future<AGPReport> agpReport({
    int? page,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    return get<AGPReport>(
      '/users/agp-report',
      httpClient: httpClient,
      queryParameters: <String, dynamic>{
        'page': page,
        'fromDate':
            // '2024-01-04',
            startDate != null
                ? DateFormat('yyyy-MM-dd').format(startDate)
                : null,
        'toDate':
            // '2024-01-05',
            endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
        'user_id': userId,
      },
      onSuccess: (response) async {
        return AGPReport.fromJson(
          (response.data as Map)['data'] as Map<String, dynamic>,
        );
      },
    );
  }
}
