import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

EncryptionResult encryptPass({text, key}) {
  final iv = IV.fromSecureRandom(16);

  final encrypter = Encrypter(
    AES(
      getHashKey(key),
      mode: AESMode.cfb64,
      padding: 'PKCS7',
    ),
  );
  Encrypted encryptedData = encrypter.encrypt(text, iv: iv);

  // Store both encryptedData and the iv, otherwise you will not able to decrypt!
  return EncryptionResult(encryptedData.base64, iv.base64);
}

decryptPass({text, iv, key}) {
  try {
    final nIv = IV.fromBase64(iv);
    final encrypter = Encrypter(
      AES(
        getHashKey(key),
        mode: AESMode.cfb64,
        padding: 'PKCS7',
      ),
    );
    return encrypter.decrypt64(text, iv: nIv);
  } catch (e) {
    return key;
  }
}

getHashKey(_) {
  // ignore: no_wildcard_variable_uses
  var bytes = utf8.encode(_);
  var digest = sha256.convert(bytes);
  var fDigest = md5.convert(digest.bytes);
  final hashKey = Key.fromUtf8(fDigest.toString());
  return hashKey;
}

class EncryptionResult {
  final String encryptedData;
  final String iv;

  EncryptionResult(this.encryptedData, this.iv);
}
