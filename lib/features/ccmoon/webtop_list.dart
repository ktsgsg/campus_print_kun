import 'secrets.dart';

class WebtopList {
  static const String hostname = 'https://ccmoon2.meijo-u.ac.jp';
  static const String _macApplies = 'user/mac_applies/index/2/';
  static const String _printService = 'user/';
  static const String _recordSystem = 'pcsweb/';
  static const String _ebookLib = 'elib/html/BookList?1=';

  final String baseurl;

  WebtopList({String? baseurl})
    : baseurl = baseurl ?? CcmoonSecrets.defaultBaseurl ?? '';

  String get urlMac => '$hostname$baseurl$_macApplies';
  String get urlPrint => '$hostname$baseurl$_printService';
  String get urlRecord => '$hostname$baseurl$_recordSystem';
  String get urlEbook => '$hostname$baseurl$_ebookLib';
}
