import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/data/raw/languages.dart';

class LanguagesData {
  static List<Language> data = _dataFromMap();

  static List<Language> _dataFromMap() =>
      languagesRawData.map(Language.fromJson).toList();
}
