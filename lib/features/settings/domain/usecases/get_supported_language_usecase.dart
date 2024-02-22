import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';

class GetSupportedLanguageUseCase
    implements
        UseCaseFuture<ErrorException, List<Language>, SupportedLanguageParams> {
  @override
  FutureOr<Either<ErrorException, List<Language>>> call(
    SupportedLanguageParams params,
  ) async {
    final _currentSupportedLangCode = <String>[];
    final _result = <Language>[];

    for (final item in params.locales) {
      _currentSupportedLangCode.add(item.languageCode);
    }

    for (final item in params.referenceLanguages) {
      if (_currentSupportedLangCode.contains(item.code)) {
        _result.add(item);
      }
    }

    return Right(_result.toSet().toList());
  }
}

class SupportedLanguageParams {
  SupportedLanguageParams({
    required this.referenceLanguages,
    required this.locales,
  });

  final List<Language> referenceLanguages;
  final List<Locale> locales;
}
