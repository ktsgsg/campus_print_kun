import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

/// 名城大 Web プリントの公開鍵 (PKCS#1 v1.5 / RSA) で平文を暗号化し
/// Base64 エンコードして返す。
///
/// ブラウザ側 (JSEncrypt 互換) と一致させるため OAEP ではなく v1.5 を使う。
/// 入力は単一ブロックに収まる前提 (ユーザ名/パスワード相当)。
String encryptForMeijo(String message, String publicKeyPem) {
  final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
  final cipher = PKCS1Encoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  final input = Uint8List.fromList(utf8.encode(message));
  if (input.length > cipher.inputBlockSize) {
    throw ArgumentError(
      '平文が公開鍵のブロックサイズを超えています '
      '(input=${input.length}, blockSize=${cipher.inputBlockSize})',
    );
  }
  final encrypted = cipher.process(input);
  return base64.encode(encrypted);
}
