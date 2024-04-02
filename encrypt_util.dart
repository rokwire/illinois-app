import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:uuid/uuid.dart';

void main() async {

  String encryptedFilepath = "assets/configs.json.enc";
  String keysFilepath = "assets/config.keys.json";
  String decryptedFile = "assets/configs.json";

  Map<String, dynamic>? _encryptionKeys = await loadEncryptionKeysFromAssets(keysFilepath);
  String? encryptionKey = _encryptionKeys != null ? _encryptionKeys['key'] : null;
  String? encryptionIV = _encryptionKeys != null ? _encryptionKeys['iv'] : null;
  if (encryptionKey == null || encryptionIV == null) {
    return;
  }

  // decryptAssetFile(encryptedFilepath, decryptedFile, encryptionKey, encryptionIV);
  // encryptAssetFile(decryptedFile, encryptedFilepath, encryptionKey, encryptionIV);

  String contents = """""";
  // print(decrypt(contents, key: encryptionKey, iv: encryptionIV));
  // print(encrypt(contents, key: encryptionKey, iv: encryptionIV));

  // print(json.encode(generateKey()));
}

void encryptAssetFile(String decryptedFile, String encryptedFile, String encryptionKey, String encryptionIV) {
  String decrypted = File(decryptedFile).readAsStringSync();
  String? encrypted = encrypt(decrypted, key: encryptionKey, iv: encryptionIV);
  if (encrypted != null) {
    File(encryptedFile).writeAsString(encrypted);
    print("saved encrypted output");
  }
}

void decryptAssetFile(String encryptedFile, String decryptedFile, String encryptionKey, String encryptionIV) {
  String encrypted = File(encryptedFile).readAsStringSync();
  String? decrypted = decrypt(encrypted, key: encryptionKey, iv: encryptionIV);
  if (decrypted != null) {
    File(decryptedFile).writeAsString(decrypted);
    print("saved decrypted output");
  }
}

Future<Map<String, dynamic>?> loadEncryptionKeysFromAssets(String filepath) async {
  try {
    String keysContents = File(filepath).readAsStringSync();
    return json.decode(keysContents);
  } catch (e) {
    print(e);
  }
  return null;
}

String? encrypt(String plainText, {String? key, String? iv, encrypt_package.AESMode mode = encrypt_package.AESMode.cbc, String padding = 'PKCS7' }) {
  if (key != null) {
    try {
      final encrypterKey = encrypt_package.Key.fromBase64(key);
      final encrypterIV = (iv != null) ? encrypt_package.IV.fromBase64(iv) : encrypt_package.IV.fromLength(base64Decode(key).length);
      final encrypter = encrypt_package.Encrypter(encrypt_package.AES(encrypterKey, mode: mode, padding: padding));
      return encrypter.encrypt(plainText, iv: encrypterIV).base64;
    }
    catch(e) {
      print(e.toString());
    }
  }
  return null;
}

String? decrypt(String cipherBase64, { String? key, String? iv, encrypt_package.AESMode mode = encrypt_package.AESMode.cbc, String padding = 'PKCS7' }) {
  if (key != null) {
    try {
      final encrypterKey = encrypt_package.Key.fromBase64(key);
      final encrypterIV = (iv != null) ? encrypt_package.IV.fromBase64(iv) : encrypt_package.IV.fromLength(base64Decode(key).length);
      final encrypter = encrypt_package.Encrypter(encrypt_package.AES(encrypterKey, mode: mode, padding: padding));
      return encrypter.decrypt(encrypt_package.Encrypted.fromBase64(cipherBase64), iv: encrypterIV);
    }
    catch(e) {
      print(e.toString());
    }
  }
  return null;
}

Map<String, dynamic> generateKey() {
  final key = encrypt_package.Key.fromSecureRandom(32);
  final iv = encrypt_package.IV.fromSecureRandom(16);
  Map<String, String> keys = {
    'id': Uuid().v4(),
    'key': key.base64,
    'iv': iv.base64,
  };
  return keys;
}