/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import "package:asn1lib/asn1lib.dart";
import "package:pointycastle/export.dart";
import 'package:encrypt/encrypt.dart' as encrypt_package;

class AESCrypt {

  static const int kCCBlockSizeAES128 = 16;

  static String? encrypt(String plainText, {String? key, String? iv, encrypt_package.AESMode mode = encrypt_package.AESMode.cbc, String padding = 'PKCS7' }) {
    if (key != null) {
      try {
        final encrypterKey = encrypt_package.Key.fromBase64(key);
        final encrypterIV = (iv != null) ? encrypt_package.IV.fromBase64(iv) : encrypt_package.IV.fromLength(base64Decode(key).length);
        final encrypter = encrypt_package.Encrypter(encrypt_package.AES(encrypterKey, mode: mode, padding: padding));
        return encrypter.encrypt(plainText, iv: encrypterIV).base64;
      }
      catch(e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  static String? decrypt(String cipherBase64, { String? key, String? iv, encrypt_package.AESMode mode = encrypt_package.AESMode.cbc, String padding = 'PKCS7' }) {
    if (key != null) {
      try {
        final encrypterKey = encrypt_package.Key.fromBase64(key);
        final encrypterIV = (iv != null) ? encrypt_package.IV.fromBase64(iv) : encrypt_package.IV.fromLength(base64Decode(key).length);
        final encrypter = encrypt_package.Encrypter(encrypt_package.AES(encrypterKey, mode: mode, padding: padding));
        return encrypter.decrypt(encrypt_package.Encrypted.fromBase64(cipherBase64), iv: encrypterIV);
      }
      catch(e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  static String randomKey({ int keySize = kCCBlockSizeAES128 }) {
    var random = Random.secure();
    return base64Encode(List.generate(keySize, (index) {
      return random.nextInt(256);
    }));
  }

  /*static bool debugEncode() {
    String base64Key = '...';
    String base64IV = '...';

    String configAsset = '...';
    String configDev = '...';
    String configProd = '...';
    String configTest = '...';

    String configAssetEnc = AESCrypt.encrypt(configAsset, key: base64Key, iv: base64IV);
    String configDevEnc = AESCrypt.encrypt(configDev, key: base64Key, iv: base64IV);
    String configProdEnc = AESCrypt.encrypt(configProd, key: base64Key, iv: base64IV);
    String configTestEnc = AESCrypt.encrypt(configTest, key: base64Key, iv: base64IV);

    String configAssetDec = AESCrypt.decrypt(configAssetEnc, key: base64Key, iv: base64IV);
    String configDevDec = AESCrypt.decrypt(configDevEnc, key: base64Key, iv: base64IV);
    String configProdDec = AESCrypt.decrypt(configProdEnc, key: base64Key, iv: base64IV);
    String configTestDec = AESCrypt.decrypt(configTestEnc, key: base64Key, iv: base64IV);

    return (configAsset == configAssetDec) && (configDev == configDevDec) && (configProd == configProdDec) && (configTest == configTestDec);
  }*/

}

class RSACrypt {

  static String? encrypt(String plainText, PublicKey publicKey) {
      try {
        final encrypter = encrypt_package.Encrypter(encrypt_package.RSA(publicKey: publicKey as RSAPublicKey, privateKey: null));
        return encrypter.encrypt(plainText).base64;
      }
      catch(e) {
        debugPrint(e.toString());
      }
      return null;
  }

  static String? decrypt(String cipherBase64, PrivateKey privateKey) {
      try {
        final encrypter = encrypt_package.Encrypter(encrypt_package.RSA(publicKey: null, privateKey: privateKey as RSAPrivateKey?));
        return encrypter.decrypt(encrypt_package.Encrypted.fromBase64(cipherBase64));
      }
      catch(e) {
        debugPrint(e.toString());
      }
      return null;
  }
}

/// Helper class to handle RSA key generation and encoding
class RsaKeyHelper {
  
  /// Generate a [PublicKey] and [PrivateKey] pair
  ///
  /// Returns a [AsymmetricKeyPair] based on the [RSAKeyGenerator] with custom parameters,
  /// including a [SecureRandom]
  static Future<AsymmetricKeyPair<PublicKey, PrivateKey>> computeRSAKeyPair(SecureRandom secureRandom) async {
    return await compute(getRsaKeyPair, secureRandom);
  }

  /// Generates a [SecureRandom]
  ///
  /// Returns [FortunaRandom] to be used in the [AsymmetricKeyPair] generation
  static SecureRandom getSecureRandom() {
    var secureRandom = FortunaRandom();
    var random = Random.secure();
    List<int> seeds = [];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Decode Public key from PEM Format
  ///
  /// Given a base64 encoded PEM [String] with correct headers and footers, return a
  /// [RSAPublicKey]
  ///
  /// *PKCS1*
  /// RSAPublicKey ::= SEQUENCE {
  ///    modulus           INTEGER,  -- n
  ///    publicExponent    INTEGER   -- e
  /// }
  ///
  /// *PKCS8*
  /// PublicKeyInfo ::= SEQUENCE {
  ///   algorithm       AlgorithmIdentifier,
  ///   PublicKey       BIT STRING
  /// }
  ///
  /// AlgorithmIdentifier ::= SEQUENCE {
  ///   algorithm       OBJECT IDENTIFIER,
  ///   parameters      ANY DEFINED BY algorithm OPTIONAL
  /// }
  static RSAPublicKey? parsePublicKeyFromPem(pemString) {
    return (pemString != null) ? parsePublicKeyFromPemData(_decodePEM(pemString)) : null;
  }

  static RSAPublicKey parsePublicKeyFromPemData(Uint8List pemData) {

    var asn1Parser = ASN1Parser(pemData);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    ASN1Integer modulus, exponent;
    // Depending on the first element type, we either have PKCS1 or 2
    if (topLevelSeq.elements[0].runtimeType == ASN1Integer) {
      modulus = topLevelSeq.elements[0] as ASN1Integer;
      exponent = topLevelSeq.elements[1] as ASN1Integer;
    } else {
      var publicKeyBitString = topLevelSeq.elements[1];

      var publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes()!);
      ASN1Sequence publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
      modulus = publicKeySeq.elements[0] as ASN1Integer;
      exponent = publicKeySeq.elements[1] as ASN1Integer;
    }

    RSAPublicKey rsaPublicKey = RSAPublicKey(modulus.valueAsBigInteger!, exponent.valueAsBigInteger!);

    return rsaPublicKey;
  }

  /// Sign plain text with Private Key
  ///
  /// Given a plain text [String] and a [RSAPrivateKey], decrypt the text using
  /// a [RSAEngine] cipher
  static String sign(String plainText, RSAPrivateKey privateKey) {
    var signer = RSASigner(SHA256Digest(), "0609608648016503040201");
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return  base64Encode(signer.generateSignature(_createUint8ListFromString(plainText)).bytes);
  }


  /// Creates a [Uint8List] from a string to be signed
  static Uint8List _createUint8ListFromString(String s) {
    var codec = const Utf8Codec(allowMalformed: true);
    return Uint8List.fromList(codec.encode(s));
  }

  /// Decode Private key from PEM Format
  ///
  /// Given a base64 encoded PEM [String] with correct headers and footers, return a
  /// [RSAPrivateKey]
  static RSAPrivateKey? parsePrivateKeyFromPem(pemString) {
    return (pemString != null) ? parsePrivateKeyFromPemData(_decodePEM(pemString)) : null;
  }

  static RSAPrivateKey parsePrivateKeyFromPemData(Uint8List pemData) {

    var asn1Parser = ASN1Parser(pemData);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    ASN1Integer modulus, privateExponent, p, q;
    // Depending on the number of elements, we will either use PKCS1 or PKCS8
    if (topLevelSeq.elements.length == 3) {
      var privateKey = topLevelSeq.elements[2];

      asn1Parser = ASN1Parser(privateKey.contentBytes()!);
      var pkSeq = asn1Parser.nextObject() as ASN1Sequence;

      modulus = pkSeq.elements[1] as ASN1Integer;
      privateExponent = pkSeq.elements[3] as ASN1Integer;
      p = pkSeq.elements[4] as ASN1Integer;
      q = pkSeq.elements[5] as ASN1Integer;
    } else {
      modulus = topLevelSeq.elements[1] as ASN1Integer;
      privateExponent = topLevelSeq.elements[3] as ASN1Integer;
      p = topLevelSeq.elements[4] as ASN1Integer;
      q = topLevelSeq.elements[5] as ASN1Integer;
    }

    RSAPrivateKey rsaPrivateKey = RSAPrivateKey(
        modulus.valueAsBigInteger!,
        privateExponent.valueAsBigInteger!,
        p.valueAsBigInteger,
        q.valueAsBigInteger);

    return rsaPrivateKey;
  }

  static Uint8List _decodePEM(String pem) {
    return base64.decode(_removePemHeaderAndFooter(pem));
  }

  static String _removePemHeaderAndFooter(String pem) {
    var startsWith = [
      "-----BEGIN PUBLIC KEY-----",
      "-----BEGIN RSA PRIVATE KEY-----",
      "-----BEGIN RSA PUBLIC KEY-----",
      "-----BEGIN PRIVATE KEY-----",
      "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
      "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
    ];
    var endsWith = [
      "-----END PUBLIC KEY-----",
      "-----END PRIVATE KEY-----",
      "-----END RSA PRIVATE KEY-----",
      "-----END RSA PUBLIC KEY-----",
      "-----END PGP PUBLIC KEY BLOCK-----",
      "-----END PGP PRIVATE KEY BLOCK-----",
    ];
    bool isOpenPgp = pem.contains('BEGIN PGP');

    pem = pem.replaceAll(' ', '');
    pem = pem.replaceAll('\n', '');
    pem = pem.replaceAll('\r', '');

    for (var s in startsWith) {
      s = s.replaceAll(' ', '');
      if (pem.startsWith(s)) {
        pem = pem.substring(s.length);
      }
    }

    for (var s in endsWith) {
      s = s.replaceAll(' ', '');
      if (pem.endsWith(s)) {
        pem = pem.substring(0, pem.length - s.length);
      }
    }

    if (isOpenPgp) {
      var index = pem.indexOf('\r\n');
      pem = pem.substring(0, index);
    }

    return pem;
  }

  /// Encode Private key to PEM Format
  ///
  /// Given [RSAPrivateKey] returns a base64 encoded [String] with standard PEM headers and footers
  static String encodePrivateKeyToPemPKCS1(RSAPrivateKey privateKey) {
    Uint8List dataBytes = encodePrivateKeyToPEMDataPKCS1(privateKey);
    var dataBase64 = base64.encode(dataBytes);
    return """-----BEGIN PRIVATE KEY-----\r\n$dataBase64\r\n-----END PRIVATE KEY-----""";
  }

  static Uint8List encodePrivateKeyToPEMDataPKCS1(RSAPrivateKey privateKey) {

    var topLevel = ASN1Sequence();

    var version = ASN1Integer(BigInt.from(0));
    var modulus = ASN1Integer(privateKey.n!);
    var publicExponent = ASN1Integer(privateKey.exponent!);
    var privateExponent = ASN1Integer(privateKey.privateExponent!);
    var p = ASN1Integer(privateKey.p!);
    var q = ASN1Integer(privateKey.q!);
    var dP = privateKey.privateExponent! % (privateKey.p! - BigInt.from(1));
    var exp1 = ASN1Integer(dP);
    var dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.from(1));
    var exp2 = ASN1Integer(dQ);
    var iQ = privateKey.q!.modInverse(privateKey.p!);
    var co = ASN1Integer(iQ);

    topLevel.add(version);
    topLevel.add(modulus);
    topLevel.add(publicExponent);
    topLevel.add(privateExponent);
    topLevel.add(p);
    topLevel.add(q);
    topLevel.add(exp1);
    topLevel.add(exp2);
    topLevel.add(co);

    return topLevel.encodedBytes;
  }

  /// Encode Public key to PEM Format
  ///
  /// Given [RSAPublicKey] returns a base64 encoded [String] with standard PEM headers and footers
  static String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
    Uint8List pemData = encodePublicKeyToPemDataPKCS1(publicKey);
    var dataBase64 = base64.encode(pemData);
    return """-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----""";
  }

  static Uint8List encodePublicKeyToPemDataPKCS1(RSAPublicKey publicKey) {
    var topLevel = ASN1Sequence();

    topLevel.add(ASN1Integer(publicKey.modulus!));
    topLevel.add(ASN1Integer(publicKey.exponent!));

    return topLevel.encodedBytes;
  }
  
  /// Generate a [PublicKey] and [PrivateKey] pair
  ///
  /// Returns a [AsymmetricKeyPair] based on the [RSAKeyGenerator] with custom parameters,
  /// including a [SecureRandom]
  static AsymmetricKeyPair<PublicKey, PrivateKey> getRsaKeyPair(SecureRandom secureRandom) {
    var rsapars = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 5);
    var params = ParametersWithRandom(rsapars, secureRandom);
    var keyGenerator = RSAKeyGenerator();
    keyGenerator.init(params);
    return keyGenerator.generateKeyPair();
  }

  /// Verify a [PublicKey] and [PrivateKey] pair
  ///
  /// Returns a boolean based on the whether [AsymmetricKeyPair] is paired or not,
  static Future<bool> verifyRsaKeyPair(AsymmetricKeyPair<PublicKey, PrivateKey> rsaKeyPair) async {
    return await compute(_verifyRSAKeyPair, rsaKeyPair);
  }
}

bool _verifyRSAKeyPair(AsymmetricKeyPair<PublicKey, PrivateKey> rsaKeyPair) {
  PublicKey rsaPublicKey = rsaKeyPair.publicKey;
  PrivateKey rsaPrivateKey = rsaKeyPair.privateKey;
  String aesKey = AESCrypt.randomKey();
  String? encryptedAESKey = RSACrypt.encrypt(aesKey, rsaPublicKey);
  if (encryptedAESKey != null) {
    String? decryptedAESKey = RSACrypt.decrypt(encryptedAESKey, rsaPrivateKey);
    return (decryptedAESKey == aesKey);
  }
  return false;
}