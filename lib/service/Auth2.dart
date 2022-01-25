
import 'package:flutter/foundation.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart' as rokwire;


class Auth2 extends rokwire.Auth2 {

  static String get notifyLoginStarted      => rokwire.Auth2.notifyLoginStarted;
  static String get notifyLoginSucceeded    => rokwire.Auth2.notifyLoginSucceeded;
  static String get notifyLoginFailed       => rokwire.Auth2.notifyLoginFailed;
  static String get notifyLoginChanged      => rokwire.Auth2.notifyLoginChanged;
  static String get notifyLoginFinished     => rokwire.Auth2.notifyLoginFinished;
  static String get notifyLogout            => rokwire.Auth2.notifyLogout;
  static String get notifyProfileChanged    => rokwire.Auth2.notifyProfileChanged;
  static String get notifyPrefsChanged      => rokwire.Auth2.notifyPrefsChanged;
  static String get notifyCardChanged       => rokwire.Auth2.notifyCardChanged;
  static String get notifyUserDeleted       => rokwire.Auth2.notifyUserDeleted;
  static String get notifyPrepareUserDelete => rokwire.Auth2.notifyPrepareUserDelete;

  // Singletone Factory

  @protected
  Auth2.internal() : super.internal();

  factory Auth2() => ((rokwire.Auth2.instance is Auth2) ? (rokwire.Auth2.instance as Auth2) : (rokwire.Auth2.instance = Auth2.internal()));

  @override
  Auth2UserPrefs get defaultAnonimousPrefs => Auth2UserPrefs.fromStorage(
    profile: Storage().userProfile,
    includedFoodTypes: Storage().includedFoodTypesPrefs,
    excludedFoodIngredients: Storage().excludedFoodIngredientsPrefs,
    settings: FirebaseMessaging.storedSettings,
  );

}

