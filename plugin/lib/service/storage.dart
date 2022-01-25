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

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/crypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage with Service {

  static const String notifySettingChanged  = 'edu.illinois.rokwire.setting.changed';
  
  static const String _ecryptionKeyId  = 'edu.illinois.rokwire.encryption.storage.key';
  static const String _encryptionIVId  = 'edu.illinois.rokwire.encryption.storage.iv';

  SharedPreferences? _sharedPreferences;
  String? _encryptionKey;
  String? _encryptionIV;

  // Singletone Factory

  static Storage? _instance;

  static Storage? get instance => _instance;
  
  @protected
  static set instance(Storage? value) => _instance = value;

  factory Storage() => _instance ?? (_instance = Storage.internal());

  @protected
  Storage.internal();

  // Service 

  @override
  Future<void> initService() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    _encryptionKey = await RokwirePlugin.getEncryptionKey(identifier: encryptionKeyId, size: AESCrypt.kCCBlockSizeAES128);
    _encryptionIV = await RokwirePlugin.getEncryptionKey(identifier: encryptionIVId, size: AESCrypt.kCCBlockSizeAES128);
    
    if (_sharedPreferences == null) {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Storage Initialization Failed',
        description: 'Failed to initialize application preferences storage.',
      );
    }
    else if ((_encryptionKey == null) || (_encryptionIV == null)) {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Storage Initialization Failed',
        description: 'Failed to initialize encryption keys.',
      );
    }
    else {
      await super.initService();
    }
  }

  // Encryption

  String  get encryptionKeyId => _ecryptionKeyId;
  String? get encryptionKey => _encryptionKey;
  
  String  get encryptionIVId => _encryptionIVId;
  String? get encryptionIV => _encryptionIV;

  String? encrypt(String? value) {
    return ((value != null) && (_encryptionKey != null) && (_encryptionIV != null)) ?
      AESCrypt.encrypt(value, key: _encryptionKey, iv: _encryptionIV) : null;
  }

  String? decrypt(String? value) {
    return ((value != null) && (_encryptionKey != null) && (_encryptionIV != null)) ?
      AESCrypt.decrypt(value, key: _encryptionKey, iv: _encryptionIV) : null;
  }

  // Utilities

  String? getStringWithName(String name, {String? defaultValue}) {
    return _sharedPreferences?.getString(name) ?? defaultValue;
  }

  void setStringWithName(String name, String? value) {
    if (value != null) {
      _sharedPreferences?.setString(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  String? getEncryptedStringWithName(String name, {String? defaultValue}) {
    String? value = _sharedPreferences?.getString(name);
    if (value != null) {
      if ((_encryptionKey != null) && (_encryptionIV != null)) {
        value = decrypt(value);
      }
      else {
        value = null;
      }
    }
    return value ?? defaultValue;
  }

  void setEncryptedStringWithName(String name, String? value) {
    if (value != null) {
      if ((_encryptionKey != null) && (_encryptionIV != null)) {
        value = encrypt(value);
        _sharedPreferences?.setString(name, value!);
      }
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  List<String>? getStringListWithName(String name, {List<String>? defaultValue}) {
    return _sharedPreferences?.getStringList(name) ?? defaultValue;
  }

  void setStringListWithName(String name, List<String>? value) {
    if (value != null) {
      _sharedPreferences?.setStringList(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  bool? getBoolWithName(String name, {bool? defaultValue = false}) {
    return _sharedPreferences?.getBool(name) ?? defaultValue;
  }

  void setBoolWithName(String name, bool? value) {
    if(value != null) {
      _sharedPreferences?.setBool(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  int? getIntWithName(String name, {int? defaultValue = 0}) {
    return _sharedPreferences?.getInt(name) ?? defaultValue;
  }

  void setIntWithName(String name, int? value) {
    if (value != null) {
      _sharedPreferences?.setInt(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }

  double getDoubleWithName(String name, {double defaultValue = 0.0}) {
    return _sharedPreferences?.getDouble(name) ?? defaultValue;
  }

  void setDoubleWithName(String name, double? value) {
    if (value != null) {
      _sharedPreferences?.setDouble(name, value);
    } else {
      _sharedPreferences?.remove(name);
    }
    NotificationService().notify(notifySettingChanged, name);
  }


  dynamic operator [](String name) {
    return _sharedPreferences?.get(name);
  }

  void operator []=(String key, dynamic value) {
    if (value is String) {
      _sharedPreferences?.setString(key, value);
    }
    else if (value is int) {
      _sharedPreferences?.setInt(key, value);
    }
    else if (value is double) {
      _sharedPreferences?.setDouble(key, value);
    }
    else if (value is bool) {
      _sharedPreferences?.setBool(key, value);
    }
    else if (value is List) {
      _sharedPreferences?.setStringList(key, value.cast<String>());
    }
    else if (value == null) {
      _sharedPreferences?.remove(key);
    }
  }

  void deleteEverything(){
    if (_sharedPreferences != null) {
      for(String key in _sharedPreferences!.getKeys()){
        _sharedPreferences!.remove(key);
      }
    }
  }

  // Config
  String get configEnvKey => 'edu.illinois.rokwire.config_environment';
  String? get configEnvironment => getStringWithName(configEnvKey);
  set configEnvironment(String? value) => setStringWithName(configEnvKey, value);

  // Upgrade

  String get reportedUpgradeVersionsKey  => 'edu.illinois.rokwire.reported_upgrade_versions';

  Set<String> get reportedUpgradeVersions {
    List<String>? list = getStringListWithName(reportedUpgradeVersionsKey);
    return (list != null) ? Set.from(list) : <String>{};
  }

  set reportedUpgradeVersion(String? version) {
    if (version != null) {
      Set<String> versions = reportedUpgradeVersions;
      versions.add(version);
      setStringListWithName(reportedUpgradeVersionsKey, versions.toList());
    }
  }

}
