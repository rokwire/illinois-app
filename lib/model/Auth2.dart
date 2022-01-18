
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

////////////////////////////////
// Auth2Token

class Auth2Token {
  final String? idToken;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  
  Auth2Token({this.accessToken, this.refreshToken, this.idToken, this.tokenType});

  static Auth2Token? fromOther(Auth2Token? value, {String? idToken, String? accessToken, String? refreshToken, String? tokenType }) {
    return (value != null) ? Auth2Token(
      idToken: idToken ?? value.idToken,
      accessToken: accessToken ?? value.accessToken,
      refreshToken: refreshToken ?? value.refreshToken,
      tokenType: tokenType ?? value.tokenType,
    ) : null;
  }

  static Auth2Token? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Token(
      idToken: JsonUtils.stringValue(json['id_token']),
      accessToken: JsonUtils.stringValue(json['access_token']),
      refreshToken: JsonUtils.stringValue(json['refresh_token']),
      tokenType: JsonUtils.stringValue(json['token_type']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_token' : idToken,
      'access_token' : accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType
    };
  }

  bool operator ==(o) =>
    (o is Auth2Token) &&
      (o.idToken == idToken) &&
      (o.accessToken == accessToken) &&
      (o.refreshToken == refreshToken) &&
      (o.tokenType == tokenType);

  int get hashCode =>
    (idToken?.hashCode ?? 0) ^
    (accessToken?.hashCode ?? 0) ^
    (refreshToken?.hashCode ?? 0) ^
    (tokenType?.hashCode ?? 0);

  bool get isValid {
    return StringUtils.isNotEmpty(accessToken) && StringUtils.isNotEmpty(refreshToken) && StringUtils.isNotEmpty(tokenType);
  }

  bool get isValidUiuc {
    return StringUtils.isNotEmpty(accessToken) && StringUtils.isNotEmpty(idToken) && StringUtils.isNotEmpty(tokenType);
  }
}

////////////////////////////////
// Auth2LoginType

enum Auth2LoginType { anonymous, email, phone, phoneTwilio, oidc, oidcIllinois }

String? auth2LoginTypeToString(Auth2LoginType value) {
  switch (value) {
    case Auth2LoginType.anonymous: return 'anonymous';
    case Auth2LoginType.email: return 'email';
    case Auth2LoginType.phone: return 'phone';
    case Auth2LoginType.phoneTwilio: return 'twilio_phone';
    case Auth2LoginType.oidc: return 'oidc';
    case Auth2LoginType.oidcIllinois: return 'illinois_oidc';
  }
}

Auth2LoginType? auth2LoginTypeFromString(String? value) {
  if (value == 'anonymous') {
    return Auth2LoginType.anonymous;
  } 
  if (value == 'email') {
    return Auth2LoginType.email;
  }
  else if (value == 'phone') {
    return Auth2LoginType.phone;
  }
  else if (value == 'twilio_phone') {
    return Auth2LoginType.phoneTwilio;
  }
  else if (value == 'oidc') {
    return Auth2LoginType.oidc;
  }
  else if (value == 'illinois_oidc') {
    return Auth2LoginType.oidcIllinois;
  }
  return null;
}

////////////////////////////////
// Auth2Account

class Auth2Account {
  final String? id;
  final Auth2UserProfile? profile;
  final Auth2UserPrefs? prefs;
  final List<Auth2StringEntry>? permissions;
  final List<Auth2StringEntry>? roles;
  final List<Auth2StringEntry>? groups;
  final List<Auth2Type>? authTypes;
  
  
  Auth2Account({this.id, this.profile, this.prefs, this.permissions, this.roles, this.groups, this.authTypes});

  static Auth2Account? fromJson(Map<String, dynamic>? json, { Auth2UserPrefs? prefs, Auth2UserProfile? profile }) {
    return (json != null) ? Auth2Account(
      id: JsonUtils.stringValue(json['id']),
      profile: Auth2UserProfile.fromJson(JsonUtils.mapValue(json['profile'])) ?? profile,
      prefs: Auth2UserPrefs.fromJson(JsonUtils.mapValue(json['preferences'])) ?? prefs, //TBD Auth2
      permissions: Auth2StringEntry.listFromJson(JsonUtils.listValue(json['permissions'])),
      roles: Auth2StringEntry.listFromJson(JsonUtils.listValue(json['roles'])),
      groups: Auth2StringEntry.listFromJson(JsonUtils.listValue(json['groups'])),
      authTypes: Auth2Type.listFromJson(JsonUtils.listValue(json['auth_types'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'profile': profile,
      'preferences': prefs,
      'permissions': permissions,
      'roles': roles,
      'groups': groups,
      'auth_types': authTypes,
    };
  }

  bool operator ==(o) =>
    (o is Auth2Account) &&
      (o.id == id) &&
      (o.profile == profile) &&
      DeepCollectionEquality().equals(o.permissions, permissions) &&
      DeepCollectionEquality().equals(o.roles, roles) &&
      DeepCollectionEquality().equals(o.groups, groups) &&
      DeepCollectionEquality().equals(o.authTypes, authTypes);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (profile?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(permissions)) ^
    (DeepCollectionEquality().hash(roles)) ^
    (DeepCollectionEquality().hash(groups)) ^
    (DeepCollectionEquality().hash(authTypes));

  bool get isValid {
    return (id != null) && id!.isNotEmpty /* && (profile != null) && profile.isValid*/;
  }

  Auth2Type? get authType {
    return ((authTypes != null) && (0 < authTypes!.length)) ? authTypes?.first : null;
  }

  bool hasRole(String role) => (Auth2StringEntry.findInList(roles, name: role) != null);
  bool hasPermission(String premission) => (Auth2StringEntry.findInList(permissions, name: premission) != null);
  bool bellongsToGroup(String group) => (Auth2StringEntry.findInList(groups, name: group) != null);
}

////////////////////////////////
// Auth2UserProfile

class Auth2UserProfile {
  String? _id;
  String? _firstName;
  String? _middleName;
  String? _lastName;
  int?    _birthYear;
  String? _photoUrl;

  String? _email;
  String? _phone;
  
  String? _address;
  String? _state;
  String? _zip;
  String? _country;
  
  Auth2UserProfile({String? id, String? firstName, String? middleName, String? lastName, int? birthYear, String? photoUrl,
    String? email, String? phone,
    String? address, String? state, String? zip, String? country
  }):
    _id = id,
    _firstName = firstName,
    _middleName = middleName,
    _lastName = lastName,
    _birthYear = birthYear,
    _photoUrl = photoUrl,
    
    _email = email,
    _phone = phone,
    
    _address = address,
    _state  = state,
    _zip  = zip,
    _country = country;
  

  static Auth2UserProfile? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2UserProfile(
      id: JsonUtils.stringValue(json['id']),
      firstName: JsonUtils.stringValue(json['first_name']),
      middleName: JsonUtils.stringValue(json['middle_name']),
      lastName: JsonUtils.stringValue(json['last_name']),
      birthYear: JsonUtils.intValue(json['birth_year']),
      photoUrl: JsonUtils.stringValue(json['photo_url']),

      email: JsonUtils.stringValue(json['email']),
      phone: JsonUtils.stringValue(json['phone']),
  
      address: JsonUtils.stringValue(json['address']),
      state: JsonUtils.stringValue(json['state']),
      zip: JsonUtils.stringValue(json['zip']),
      country: JsonUtils.stringValue(json['country']),
    ) : null;
  }

  factory Auth2UserProfile.empty() {
    return Auth2UserProfile();
  }

  static Auth2UserProfile? fromOther(Auth2UserProfile? other, {
    String? id, String? firstName, String? middleName, String? lastName, int? birthYear, String? photoUrl,
    String? email, String? phone,
    String? address, String? state, String? zip, String? country}) {

    return (other != null) ? Auth2UserProfile(
      id: id ?? other._id,
      firstName: firstName ?? other._firstName,
      middleName: middleName ?? other._middleName,
      lastName: lastName ?? other._lastName,
      birthYear: birthYear ?? other._birthYear,
      photoUrl: photoUrl ?? other._photoUrl,

      email: email ?? other._email,
      phone: phone ?? other._phone,
  
      address: address ?? other._address,
      state: state ?? other._state,
      zip: zip ?? other._zip,
      country: country ?? other._country,
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : _id,
      'first_name': _firstName,
      'middle_name': _middleName,
      'last_name': _lastName,
      'birth_year': _birthYear,
      'photo_url': _photoUrl,

      'email': _email,
      'phone': _phone,

      'address': _address,
      'state': _state,
      'zip': _zip,
      'country': _country,
    };
  }

  bool operator ==(o) =>
    (o is Auth2UserProfile) &&
      (o._id == _id) &&
      (o._firstName == _firstName) &&
      (o._middleName == _middleName) &&
      (o._lastName == _lastName) &&
      (o._birthYear == _birthYear) &&
      (o._photoUrl == _photoUrl) &&

      (o._email == _email) &&
      (o._phone == _phone) &&

      (o._address == _address) &&
      (o._state == _state) &&
      (o._zip == _zip) &&
      (o._country == _country);

  int get hashCode =>
    (_id?.hashCode ?? 0) ^
    (_firstName?.hashCode ?? 0) ^
    (_middleName?.hashCode ?? 0) ^
    (_lastName?.hashCode ?? 0) ^
    (_birthYear?.hashCode ?? 0) ^
    (_photoUrl?.hashCode ?? 0) ^

    (_email?.hashCode ?? 0) ^
    (_phone?.hashCode ?? 0) ^

    (_address?.hashCode ?? 0) ^
    (_state?.hashCode ?? 0) ^
    (_zip?.hashCode ?? 0) ^
    (_country?.hashCode ?? 0);

  bool apply(Auth2UserProfile? profile) {
    bool modified = false;
    if (profile != null) {
      if ((profile._id != null) && (profile._id != _id)) {
        _id = profile._id;
        modified = true;
      }
      if ((profile._firstName != null) && (profile._firstName != _firstName)) {
        _firstName = profile._firstName;
        modified = true;
      }
      if ((profile._middleName != null) && (profile._middleName != _middleName)) {
        _middleName = profile._middleName;
        modified = true;
      }
      if ((profile._lastName != null) && (profile._lastName != _lastName)) {
        _lastName = profile._lastName;
        modified = true;
      }
      if ((profile._birthYear != null) && (profile._birthYear != _birthYear)) {
        _birthYear = profile._birthYear;
        modified = true;
      }
      if ((profile._photoUrl != null) && (profile._photoUrl != _photoUrl)) {
        _photoUrl = profile._photoUrl;
        modified = true;
      }

      if ((profile._email != null) && (profile._email != _email)) {
        _email = profile._email;
        modified = true;
      }
      if ((profile._phone != null) && (profile._phone != _phone)) {
        _phone = profile._phone;
        modified = true;
      }

      if ((profile._address != null) && (profile._address != _address)) {
        _address = profile._address;
        modified = true;
      }
      if ((profile._state != null) && (profile._state != _state)) {
        _state = profile._state;
        modified = true;
      }
      if ((profile._zip != null) && (profile._zip != _zip)) {
        _zip = profile._zip;
        modified = true;
      }
      if ((profile._country != null) && (profile._country != _country)) {
        _country = profile._country;
        modified = true;
      }
    }
    return modified;
  }
  
  String? get id => _id;
  String? get firstName => _firstName;
  String? get middleName => _middleName;
  String? get lastName => _lastName;
  int?    get birthYear => _birthYear;
  String? get photoUrl => _photoUrl;

  String? get email => _email;
  String? get phone => _phone;
  
  String? get address => _address;
  String? get state => _state;
  String? get zip => _zip;
  String? get country => _country;

  bool   get isValid => StringUtils.isNotEmpty(id);
  String? get fullName => StringUtils.fullName([firstName, lastName]);
}

////////////////////////////////
// Auth2StringEntry

class Auth2StringEntry {
  final String? id;
  final String? name;
  
  Auth2StringEntry({this.id, this.name});

  static Auth2StringEntry? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2StringEntry(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'name': name,
    };
  }

  bool operator ==(o) =>
    (o is Auth2StringEntry) &&
      (o.id == id) &&
      (o.name == name);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0);

  static List<Auth2StringEntry>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2StringEntry>? result;
    if (jsonList != null) {
      result = <Auth2StringEntry>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Auth2StringEntry.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Auth2StringEntry>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static Auth2StringEntry? findInList(List<Auth2StringEntry>? contentList, { String? name }) {
    if (contentList != null) {
      for (Auth2StringEntry? contentEntry in contentList) {
        if (contentEntry!.name == name) {
          return contentEntry;
        }
      }
    }
    return null;
  }
}

////////////////////////////////
// Auth2Type

class Auth2Type {
  final String? id;
  final String? identifier;
  final bool? active;
  final bool? active2fa;
  final String? code;
  final Map<String, dynamic>? params;
  
  final Auth2UiucUser? uiucUser;
  final Auth2LoginType? loginType;
  
  Auth2Type({this.id, this.identifier, this.active, this.active2fa, this.code, this.params}) :
    uiucUser = (params != null) ? Auth2UiucUser.fromJson(JsonUtils.mapValue(params['user'])) : null,
    loginType = auth2LoginTypeFromString(code);

  static Auth2Type? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Type(
      id: JsonUtils.stringValue(json['id']),
      identifier: JsonUtils.stringValue(json['identifier']),
      active: JsonUtils.boolValue(json['active']),
      active2fa: JsonUtils.boolValue(json['active_2fa']),
      code: JsonUtils.stringValue(json['code']),
      params: JsonUtils.mapValue(json['params']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'identifier': identifier,
      'active': active,
      'active_2fa': active2fa,
      'code': code,
      'params': params,
    };
  }

  bool operator ==(o) =>
    (o is Auth2Type) &&
      (o.id == id) &&
      (o.identifier == identifier) &&
      (o.active == active) &&
      (o.active2fa == active2fa) &&
      (o.code == code) &&
      DeepCollectionEquality().equals(o.params, params);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (identifier?.hashCode ?? 0) ^
    (active?.hashCode ?? 0) ^
    (active2fa?.hashCode ?? 0) ^
    (code?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(params));

  String? get uin {
    return (loginType == Auth2LoginType.oidcIllinois) ? identifier : null;
  }

  String? get phone {
    return (loginType == Auth2LoginType.phoneTwilio) ? identifier : null;
  }

  String? get email {
    return (loginType == Auth2LoginType.email) ? identifier : null;
  }

  static List<Auth2Type>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2Type>? result;
    if (jsonList != null) {
      result = <Auth2Type>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Auth2Type.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Auth2Type>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

////////////////////////////////
// Auth2Error

class Auth2Error {
  final String? status;
  final String? message;
  
  Auth2Error({this.status, this.message});

  static Auth2Error? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Error(
      status: JsonUtils.stringValue(json['status']),
      message: JsonUtils.stringValue(json['message']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'status' : status,
      'message': message,
    };
  }

  bool operator ==(o) =>
    (o is Auth2Error) &&
      (o.status == status) &&
      (o.message == message);

  int get hashCode =>
    (status?.hashCode ?? 0) ^
    (message?.hashCode ?? 0);

}

////////////////////////////////
// Auth2UiucUser

class Auth2UiucUser {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? identifier;
  final List<String>? groups;
  final Map<String, dynamic>? systemSpecific;
  final Set<String>? groupsMembership;
  
  Auth2UiucUser({this.email, this.firstName, this.lastName, this.middleName, this.identifier, this.groups, this.systemSpecific}) :
    groupsMembership = (groups != null) ? Set.from(groups) : null;

  static Auth2UiucUser? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2UiucUser(
      email: JsonUtils.stringValue(json['email']),
      firstName: JsonUtils.stringValue(json['first_name']),
      lastName: JsonUtils.stringValue(json['last_name']),
      middleName: JsonUtils.stringValue(json['middle_name']),
      identifier: JsonUtils.stringValue(json['identifier']),
      groups: JsonUtils.stringListValue(json['groups']),
      systemSpecific: JsonUtils.mapValue(json['system_specific']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'email' : email,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'identifier': identifier,
      'groups': groups,
      'system_specific': systemSpecific,
    };
  }

  bool operator ==(o) =>
    (o is Auth2UiucUser) &&
      (o.email == email) &&
      (o.firstName == firstName) &&
      (o.lastName == lastName) &&
      (o.middleName == middleName) &&
      (o.identifier == identifier) &&
      DeepCollectionEquality().equals(o.groups, groups) &&
      DeepCollectionEquality().equals(o.systemSpecific, systemSpecific);

  int get hashCode =>
    (email?.hashCode ?? 0) ^
    (firstName?.hashCode ?? 0) ^
    (lastName?.hashCode ?? 0) ^
    (middleName?.hashCode ?? 0) ^
    (identifier?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(groups)) ^
    (DeepCollectionEquality().hash(systemSpecific));

  String? get uin {
    return ((systemSpecific != null) ? JsonUtils.stringValue(systemSpecific!['uiucedu_uin']) : null) ?? identifier;
  }

  String? get netId {
    return (systemSpecific != null) ? JsonUtils.stringValue(systemSpecific!['preferred_username']) : null;
  }

  String? get fullName {
    return StringUtils.fullName([firstName, middleName, lastName]);
  }

  static List<Auth2UiucUser>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2UiucUser>? result;
    if (jsonList != null) {
      result = <Auth2UiucUser>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Auth2UiucUser.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Auth2UiucUser>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

////////////////////////////////
// Auth2UserPrefs

class Auth2UserPrefs {

  static const String notifyPrivacyLevelChanged  = "edu.illinois.rokwire.user.prefs.privacy.level.changed";
  static const String notifyRolesChanged         = "edu.illinois.rokwire.user.prefs.roles.changed";
  static const String notifyFavoriteChanged      = "edu.illinois.rokwire.user.prefs.favorite.changed";
  static const String notifyFavoritesChanged     = "edu.illinois.rokwire.user.prefs.favorites.changed";
  static const String notifyInterestsChanged     = "edu.illinois.rokwire.user.prefs.interests.changed";
  static const String notifyFoodChanged          = "edu.illinois.rokwire.user.prefs.food.changed";
  static const String notifyTagsChanged          = "edu.illinois.rokwire.user.prefs.tags.changed";
  static const String notifySettingsChanged      = "edu.illinois.rokwire.user.prefs.settings.changed";
  static const String notifyVoterChanged         = "edu.illinois.rokwire.user.prefs.voter.changed";
  static const String notifyChanged              = "edu.illinois.rokwire.user.prefs.changed";

  static const String _foodIncludedTypes         = "included_types";
  static const String _foodExcludedIngredients   = "excluded_ingredients";
  
  int? _privacyLevel;
  Set<UserRole>? _roles;
  Map<String, Set<String>>?  _favorites;
  Map<String, Set<String>>?  _interests;
  Map<String, Set<String>>?  _foodFilters;
  Map<String, bool>? _tags;
  Map<String, dynamic>? _settings;
  Auth2VoterPrefs? _voter;

  Auth2UserPrefs({int? privacyLevel, Set<UserRole>? roles, Map<String, Set<String>>? favorites, Map<String, Set<String>>? interests, Map<String, Set<String>>? foodFilters, Map<String, bool>? tags, Map<String, dynamic>? settings, Auth2VoterPrefs? voter}) {
    _privacyLevel = privacyLevel;
    _roles = roles;
    _favorites = favorites;
    _interests = interests;
    _foodFilters = foodFilters;
    _tags = tags;
    _settings = settings;
    _voter = Auth2VoterPrefs.fromOther(voter, onChanged: _onVoterChanged);
  }

  static Auth2UserPrefs? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2UserPrefs(
      privacyLevel: JsonUtils.intValue(json['privacy_level']),
      roles: UserRole.setFromJson(JsonUtils.listValue(json['roles'])),
      favorites: _mapOfStringSetsFromJson(JsonUtils.mapValue(json['favorites'])),
      interests: _mapOfStringSetsFromJson(JsonUtils.mapValue(json['interests'])),
      foodFilters: _mapOfStringSetsFromJson(JsonUtils.mapValue(json['food'])),
      tags: _tagsFromJson(JsonUtils.mapValue(json['tags'])),
      settings: JsonUtils.mapValue(json['settings']),
      voter: Auth2VoterPrefs.fromJson(JsonUtils.mapValue(json['voter'])),
    ) : null;
  }

  factory Auth2UserPrefs.empty() {
    return Auth2UserPrefs(
      privacyLevel: null,
      roles: Set<UserRole>(),
      favorites: Map<String, Set<String>>(),
      interests: Map<String, Set<String>>(),
      foodFilters: {
        _foodIncludedTypes : Set<String>(),
        _foodExcludedIngredients : Set<String>(),
      },
      tags: Map<String, bool>(),
      settings: Map<String, dynamic>(),
      voter: Auth2VoterPrefs(),
    );
  }

  factory Auth2UserPrefs.fromStorage({Map<String, dynamic>? profile, Set<String>? includedFoodTypes, Set<String>? excludedFoodIngredients, Map<String, dynamic>? settings}) {
    Map<String, dynamic>? privacy = (profile != null) ? JsonUtils.mapValue(profile['privacySettings']) : null;
    int? privacyLevel = (privacy != null) ? JsonUtils.intValue(privacy['level']) : null;
    Set<UserRole>? roles = (profile != null) ? UserRole.setFromJson(JsonUtils.listValue(profile['roles'])) : null;
    Map<String, Set<String>>? favorites = (profile != null) ? _mapOfStringSetsFromJson(JsonUtils.mapValue(profile['favorites'])) : null;
    Map<String, Set<String>>? interests = (profile != null) ? _interestsFromProfileList(JsonUtils.listValue(profile['interests'])) : null;
    Map<String, bool>? tags = (profile != null) ? _tagsFromProfileLists(positive: JsonUtils.listValue(profile['positiveInterestTags']), negative: JsonUtils.listValue(profile['negativeInterestTags'])) : null;
    Auth2VoterPrefs? voter = (profile != null) ? Auth2VoterPrefs.fromJson(profile) : null;

    return Auth2UserPrefs(
      privacyLevel: privacyLevel,
      roles: roles ?? Set<UserRole>(),
      favorites: favorites ?? Map<String, Set<String>>(),
      interests: interests ?? Map<String, Set<String>>(),
      foodFilters: {
        _foodIncludedTypes : includedFoodTypes ?? Set<String>(),
        _foodExcludedIngredients : excludedFoodIngredients ?? Set<String>(),
      },
      tags: tags ?? Map<String, bool>(),
      settings: settings ?? Map<String, dynamic>(),
      voter: voter ?? Auth2VoterPrefs(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacy_level' : privacyLevel,
      'roles': UserRole.setToJson(roles),
      'favorites': _mapOfStringSetsToJson(_favorites),
      'interests': _mapOfStringSetsToJson(_interests),
      'food': _mapOfStringSetsToJson(_foodFilters),
      'tags': _tags,
      'settings': _settings,
      'voter': _voter
    };
  }

  bool operator ==(o) =>
    (o is Auth2UserPrefs) &&
      (o._privacyLevel == _privacyLevel) &&
      DeepCollectionEquality().equals(o._roles, _roles) &&
      DeepCollectionEquality().equals(o._favorites, _favorites) &&
      DeepCollectionEquality().equals(o._interests, _interests) &&
      DeepCollectionEquality().equals(o._foodFilters, _foodFilters) &&
      DeepCollectionEquality().equals(o._tags, _tags) &&
      DeepCollectionEquality().equals(o._settings, _settings) &&
      (o._voter == _voter);

  int get hashCode =>
    (_privacyLevel?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(_roles)) ^
    (DeepCollectionEquality().hash(_favorites)) ^
    (DeepCollectionEquality().hash(_interests)) ^
    (DeepCollectionEquality().hash(_foodFilters)) ^
    (DeepCollectionEquality().hash(_tags)) ^
    (DeepCollectionEquality().hash(_settings)) ^
    (_voter?.hashCode ?? 0);

  bool apply(Auth2UserPrefs? prefs, { bool? notify }) {
    bool modified = false;

    if (prefs != null) {
      
      if ((prefs.privacyLevel != null) && (prefs.privacyLevel! > 0) && (prefs.privacyLevel != _privacyLevel)) {
        _privacyLevel = prefs._privacyLevel;
        if (notify == true) {
          NotificationService().notify(notifyPrivacyLevelChanged);
        }
        modified = true;
      }
      
      if ((prefs.roles != null) && prefs.roles!.isNotEmpty && !DeepCollectionEquality().equals(prefs.roles, _roles)) {
        _roles = prefs._roles;
        if (notify == true) {
          NotificationService().notify(notifyRolesChanged);
        }
        modified = true;
      }
      
      if ((prefs._favorites != null) && prefs.hasFavorites && !DeepCollectionEquality().equals(prefs._favorites, _favorites)) {
        _favorites = prefs._favorites;
        if (notify == true) {
          NotificationService().notify(notifyFavoritesChanged);
        }
        modified = true;
      }
      
      if ((prefs._interests != null) && prefs._interests!.isNotEmpty && !DeepCollectionEquality().equals(prefs._interests, _interests)) {
        _interests = prefs._interests;
        if (notify == true) {
          NotificationService().notify(notifyInterestsChanged);
        }
        modified = true;
      }
      
      if ((prefs._foodFilters != null) && prefs.hasFoodFilters && !DeepCollectionEquality().equals(prefs._foodFilters, _foodFilters)) {
        _foodFilters = prefs._foodFilters;
        if (notify == true) {
          NotificationService().notify(notifyInterestsChanged);
        }
        modified = true;
      }

      if ((prefs._tags != null) && prefs._tags!.isNotEmpty && !DeepCollectionEquality().equals(prefs._tags, _tags)) {
        _tags = prefs._tags;
        if (notify == true) {
          NotificationService().notify(notifyTagsChanged);
        }
        modified = true;
      }
      
      if ((prefs._settings != null) && prefs._settings!.isNotEmpty && !DeepCollectionEquality().equals(prefs._settings, _settings)) {
        _settings = prefs._settings;
        if (notify == true) {
          NotificationService().notify(notifySettingsChanged);
        }
        modified = true;
      }
      
      if ((prefs._voter != null) && prefs._voter!.isNotEmpty && (prefs._voter != _voter)) {
        _voter = Auth2VoterPrefs.fromOther(prefs._voter, onChanged: _onVoterChanged);
        if (notify == true) {
          NotificationService().notify(notifyVoterChanged);
        }
        modified = true;
      }
    }
    return modified;
  }

  // Privacy

  int? get privacyLevel {
    return _privacyLevel;
  }
  
  set privacyLevel(int? value) {
    if (_privacyLevel != value) {
      _privacyLevel = value;
      NotificationService().notify(notifyPrivacyLevelChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Roles

  Set<UserRole>? get roles {
    return _roles;
  } 
  
  set roles(Set<UserRole>? value) {
    if (_roles != value) {
      _roles = (value != null) ? Set.from(value) : null;
      NotificationService().notify(notifyRolesChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Favorites

  Set<String>? getFavorites(String favoriteKey) {
    return (_favorites != null) ? _favorites![favoriteKey] : null;
  }

  bool isFavorite(Favorite? favorite) {
    Set<String>? favoriteIdsForKey = (_favorites != null) ? _favorites![favorite?.favoriteKey] : null;
    return (favoriteIdsForKey != null) && favoriteIdsForKey.contains(favorite?.favoriteId);
  }

  void toggleFavorite(Favorite? favorite) {
    if(_favorites == null){
      _favorites = Map<String, Set<String>>();
    }

    if ((favorite != null) && (_favorites != null)) {
      Set<String>? favoriteIdsForKey = _favorites![favorite.favoriteKey];
      bool shouldFavorite = (favoriteIdsForKey == null) || !favoriteIdsForKey.contains(favorite.favoriteId);
      if (shouldFavorite) {
        if (favoriteIdsForKey == null) {
          _favorites![favorite.favoriteKey] = favoriteIdsForKey = Set<String>();
        }
        SetUtils.add(favoriteIdsForKey, favorite.favoriteId);
      }
      else {
        favoriteIdsForKey.remove(favorite.favoriteId);
        if (favoriteIdsForKey.isEmpty) {
          _favorites!.remove(favorite.favoriteKey);
        }
      }

      Analytics().logFavorite(favorite, shouldFavorite);
      NotificationService().notify(notifyFavoriteChanged, favorite);
      NotificationService().notify(notifyFavoritesChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  bool isListFavorite(List<Favorite>? favorites) {
    if ((favorites != null) && (_favorites != null)) {
      for (Favorite favorite in favorites) {
        if (!isFavorite(favorite)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  void setListFavorite(List<Favorite>? favorites, bool shouldFavorite, {Favorite? sourceFavorite}) {
    if(_favorites == null){
      _favorites = Map<String, Set<String>>();
    }

    if ((favorites != null) && (_favorites != null)) {
      for (Favorite favorite in favorites) {
        Set<String>? favoriteIdsForKey = _favorites![favorite.favoriteKey];
        bool isFavorite = (favoriteIdsForKey != null) && favoriteIdsForKey.contains(favorite.favoriteId);
        if (isFavorite && !shouldFavorite) {
          favoriteIdsForKey.remove(favorite.favoriteId);
          if (favoriteIdsForKey.isEmpty) {
            _favorites!.remove(favorite.favoriteKey);
          }
        }
        else if (!isFavorite && shouldFavorite) {
          if (favoriteIdsForKey == null) {
            _favorites![favorite.favoriteKey] = favoriteIdsForKey = Set<String>();
          }
          SetUtils.add(favoriteIdsForKey, favorite.favoriteId);
        }
        //DeviceCalendar().onFavoriteUpdated(favorite, shouldFavorite);
        NotificationService().notify(notifyFavoriteChanged, favorite);
      }
      if (sourceFavorite != null) {
        Analytics().logFavorite(sourceFavorite, shouldFavorite);
      }
      NotificationService().notify(notifyFavoritesChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  bool get hasFavorites {
    bool result = false;
    _favorites?.forEach((String key, Set<String> values) {
      if (values.isNotEmpty) {
        result = true;
      }
    });
    return result;
  }

  // Interests

  Iterable<String>? get interestCategories {
    return _interests?.keys;
  }

  void toggleInterestCategory(String? category) {
    if(_interests == null){
      _interests = Map<String, Set<String>>();
    }

    if ((category != null) && (_interests != null)) {
      if (_interests!.containsKey(category)) {
        _interests!.remove(category);
      }
      else {
        _interests![category] = Set<String>();
      }

      NotificationService().notify(notifyInterestsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyInterestCategories(Set<String>? categories) {
    if(_interests == null){
      _interests = Map<String, Set<String>>();
    }

    if ((categories != null) && (_interests != null)) {

      bool modified = false;
      Set<String>? categoriesToRemove;
      for (String category in _interests!.keys) {
        if (!categories.contains(category)) {
          if (categoriesToRemove == null) {
            categoriesToRemove = Set<String>();
          }
          categoriesToRemove.add(category);
        }
      }

      for (String category in categories) {
        if (!_interests!.containsKey(category)) {
          _interests![category] = Set<String>();
          modified = true;
        }
      }

      if (categoriesToRemove != null) {
        for (String category in categoriesToRemove) {
          _interests!.remove(category);
          modified = true;
        }
      }

      if (modified) {
        NotificationService().notify(notifyInterestsChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  Set<String>? getInterestsFromCategory(String? category) {
    return ((_interests != null) && (category != null)) ? _interests![category] : null;
  }

  bool? hasInterest(String? category, String? interest) {
    Set<String>? interests = ((category != null) && (_interests != null)) ? _interests![category] : null;
    return ((interests != null) && (interest != null)) ? interests.contains(interest) : null;
  }

  void toggleInterest(String? category, String? interest) {
    if(_interests == null){
      _interests = Map<String, Set<String>>();
    }

    if ((category != null) && (interest != null) && (_interests != null)) {
      Set<String>? categories = _interests![category];
      if (categories == null) {
        _interests![category] = categories = Set<String>();
      }
      if (categories.contains(interest)) {
        categories.remove(interest);
      }
      else {
        categories.add(interest);
      }

      NotificationService().notify(notifyInterestsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void toggleInterests(String? category, Iterable<String>? interests) {
    if(_interests == null){
      _interests = Map<String, Set<String>>();
    }

    if ((category != null) && (interests != null) && interests.isNotEmpty && (_interests != null)) {
      Set<String>? categories = _interests![category];
      if (categories == null) {
        _interests![category] = categories = Set<String>();
      }
      for (String interest in interests) {
        if (categories.contains(interest)) {
          categories.remove(interest);
        }
        else {
          categories.add(interest);
        }
      }

      NotificationService().notify(notifyInterestsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyInterests(String? category, Iterable<String>? interests) {
    if(_interests == null){
      _interests = Map<String, Set<String>>();
    }

    if ((category != null) && (_interests != null)) {
      bool modified = false;
      if ((interests != null) && !DeepCollectionEquality().equals(_interests![category], interests)) {
        _interests![category] = Set<String>.from(interests);
        modified = true;
      }
      else if (_interests!.containsKey(category)) {
        _interests!.remove(category);
        modified = true;
      }

      if (modified) {
        NotificationService().notify(notifyInterestsChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  void clearInterestsAndTags() {
    bool modified = false;

    if ((_interests == null) || _interests!.isNotEmpty) {
      _interests = Map<String, Set<String>>();
      modified = true;
      NotificationService().notify(notifyInterestsChanged);
    }

    if ((_tags == null) || _tags!.isNotEmpty) {
      _tags = Map<String, bool>();
      modified = true;
      NotificationService().notify(notifyTagsChanged);
    }

    if (modified) {
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Sports

  static const String sportsInterestsCategory = "sports";  

  Set<String>? get sportsInterests => getInterestsFromCategory(sportsInterestsCategory);
  bool? hasSportInterest(String? sport) => hasInterest(sportsInterestsCategory, sport);
  void toggleSportInterest(String? sport) => toggleInterest(sportsInterestsCategory, sport);
  void toggleSportInterests(Iterable<String>? sports) => toggleInterests(sportsInterestsCategory, sports);

  // Food

  Set<String>? get excludedFoodIngredients {
    return (_foodFilters != null) ? _foodFilters![_foodExcludedIngredients] : null;
  }

  set excludedFoodIngredients(Set<String>? value) {
    if (!SetEquality().equals(excludedFoodIngredients, value)) {
      if (value != null) {
        if (_foodFilters != null) {
          _foodFilters![_foodExcludedIngredients] = value;
        }
        else {
          _foodFilters = { _foodExcludedIngredients : value };
        }
      }
      else if (_foodFilters != null) {
        _foodFilters!.remove(_foodExcludedIngredients);
      }
      NotificationService().notify(notifyFoodChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  Set<String>? get includedFoodTypes {
    return (_foodFilters != null) ? _foodFilters![_foodIncludedTypes] : null;
  }

  set includedFoodTypes(Set<String>? value) {
    if (!SetEquality().equals(includedFoodTypes, value)) {
      if (value != null) {
        if (_foodFilters != null) {
          _foodFilters![_foodIncludedTypes] = value;
        }
        else {
          _foodFilters = { _foodIncludedTypes : value };
        }
      }
      else if (_foodFilters != null) {
        _foodFilters!.remove(_foodIncludedTypes);
      }
      NotificationService().notify(notifyFoodChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  bool get hasFoodFilters {
    return (includedFoodTypes?.isNotEmpty ?? false) || (excludedFoodIngredients?.isNotEmpty ?? false);
  }

  void clearFoodFilters() {
    if (hasFoodFilters) {
      _foodFilters = Map<String, Set<String>>();
      NotificationService().notify(notifyFoodChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Tags

  Set<String>? get positiveTags => getTags(positive: true);
  bool hasPositiveTag(String tag) => hasTag(tag, positive: true);
  void togglePositiveTag(String? tag) => toggleTag(tag, positive: true);

  Set<String>? getTags({ bool? positive }) {
    Set<String>? tags;
    if (_tags != null) {
      tags = Set<String>();
      for (String tag in _tags!.keys) {
        if ((positive == null) || (_tags![tag] == positive)) {
          tags.add(tag);
        }
      }
    }
    return tags;
  }

  bool hasTag(String? tag, { bool? positive}) {
    if ((_tags != null) && (tag != null)) {
      bool? value = _tags![tag];
      return (value != null) && ((positive == null) || (value == positive));
    }
    return false;
  }

  void toggleTag(String? tag, { bool positive = true}) {
    if(_tags == null){
      _tags = Map<String, bool>();
    }

    if ((_tags != null) && (tag != null)) {
      if (_tags!.containsKey(tag)) {
        _tags!.remove(tag);
      }
      else {
        _tags![tag] = positive;
      }
    }
    NotificationService().notify(notifyTagsChanged);
    NotificationService().notify(notifyChanged, this);
  }

  void addTag(String? tag, { bool? positive }) {
    if(_tags == null){
      _tags = Map<String, bool>();
    }

    if ((_tags != null) && (tag != null) && (_tags![tag] != positive)) {
      _tags![tag] = positive ?? false;
      NotificationService().notify(notifyTagsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void removeTag(String? tag) {
    if ((_tags != null) && (tag != null) && _tags!.containsKey(tag)) {
      _tags!.remove(tag);
      NotificationService().notify(notifyTagsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyTags(Iterable<String>? tags, { bool positive = true }) {
    if(_tags == null){
      _tags = Map<String, bool>();
    }

    if ((_tags != null) && (tags != null)) {
      bool modified = false;
      for (String tag in tags) {
        if (_tags![tag] != positive) {
          _tags![tag] = positive;
          modified = true;
        }
      }
      if (modified) {
        NotificationService().notify(notifyTagsChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }
  // Settings

  bool? getBoolSetting({String? settingName, bool? defaultValue}){
    return JsonUtils.boolValue(getSetting(settingName: settingName)) ?? defaultValue;
  }

  dynamic getSetting({String? settingName}){
    if(_settings?.isNotEmpty ?? false){
      return _settings![settingName];
    }

    return null;//consider default TBD
  }

  void applySetting(String settingName, dynamic settingValue){
    if(_settings == null)
      _settings = Map<String, dynamic>();
    _settings![settingName] = settingValue;

    NotificationService().notify(notifySettingsChanged);
    NotificationService().notify(notifyChanged, this);
  }

  // Voter

  Auth2VoterPrefs? get voter => _voter;

  void _onVoterChanged() {
    NotificationService().notify(notifyVoterChanged);
    NotificationService().notify(notifyChanged, this);
  }

  // Helpers

  static Map<String, Set<String>>? _mapOfStringSetsFromJson(Map<String, dynamic>? jsonMap) {
    Map<String, Set<String>>? result;
    if (jsonMap != null) {
      result = Map<String, Set<String>>();
      for (String key in jsonMap.keys) {
        MapUtils.set(result, key, JsonUtils.setStringsValue(jsonMap[key]));
      }
    }
    return result;
  }

  static Map<String, dynamic>? _mapOfStringSetsToJson(Map<String, Set<String>>? contentMap) {
    Map<String, dynamic>? jsonMap;
    if (contentMap != null) {
      jsonMap = Map<String, dynamic>();
      for (String key in contentMap.keys) {
        jsonMap[key] = List.from(contentMap[key]!);
      }
    }
    return jsonMap;
  }

  static Map<String, bool>? _tagsFromJson(Map<String, dynamic>? json) {
    try { return json?.cast<String, bool>(); }
    catch(e) { print(e.toString()); }
    return null;
  }

  static Map<String, bool>? _tagsFromProfileLists({List<dynamic>? positive, List<dynamic>? negative}) {
    Map<String, bool>? result = ((positive != null) || (negative != null)) ? Map<String, bool>() : null;

    if (negative != null) {
      for (dynamic negativeEntry in negative) {
        if (negativeEntry is String) {
          result![negativeEntry] = false;
        }
      }
    }

    if (positive != null) {
      for (dynamic positiveEntry in positive) {
        if (positiveEntry is String) {
          result![positiveEntry] = true;
        }
      }
    }
    
    return result;
  }

  static Map<String, Set<String>>? _interestsFromProfileList(List<dynamic>? jsonList) {
    Map<String, Set<String>>? result;
    if (jsonList != null) {
      result = Map<String, Set<String>>();
      for (dynamic jsonEntry in jsonList) {
        if (jsonEntry is Map) {
          String? category = JsonUtils.stringValue(jsonEntry['category']);
          if (category != null) {
            result[category] = JsonUtils.setStringsValue(jsonEntry['subcategories']) ?? Set<String>();
          }
        }
      }
    }
    return result;
  }
}

class Auth2VoterPrefs {
  bool? _registeredVoter;
  String? _votePlace;
  bool? _voterByMail;
  bool? _voted;
  
  Function? onChanged;
  
  Auth2VoterPrefs({bool? registeredVoter, String? votePlace, bool? voterByMail, bool? voted, this.onChanged}) :
    _registeredVoter = registeredVoter,
    _votePlace = votePlace,
    _voterByMail = voterByMail,
    _voted = voted;

  static Auth2VoterPrefs? fromJson(Map<String, dynamic>? json, { Function? onChanged }) {
    return (json != null) ? Auth2VoterPrefs(
      registeredVoter: JsonUtils.boolValue(json['registered_voter']),
      votePlace: JsonUtils.stringValue(json['vote_place']),
      voterByMail: JsonUtils.boolValue(json['voter_by_mail']),
      voted: JsonUtils.boolValue(json['voted']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'registered_voter' : _registeredVoter,
      'vote_place': _votePlace,
      'voter_by_mail': _voterByMail,
      'voted': _voted,
    };
  }

  static Auth2VoterPrefs? fromOther(Auth2VoterPrefs? other, { Function? onChanged }) {
    return (other != null) ? Auth2VoterPrefs(
      registeredVoter: other.registeredVoter,
      votePlace: other.votePlace,
      voterByMail: other.voterByMail,
      voted: other.voted,
      onChanged: onChanged,
    ) : null;
  }

  bool operator ==(o) =>
    (o is Auth2VoterPrefs) &&
      (o._registeredVoter == _registeredVoter) &&
      (o._votePlace == _votePlace) &&
      (o._voterByMail == _voterByMail) &&
      (o._voted == _voted);

  int get hashCode =>
    (_registeredVoter?.hashCode ?? 0) ^
    (_votePlace?.hashCode ?? 0) ^
    (_voterByMail?.hashCode ?? 0) ^
    (_voted?.hashCode ?? 0);

  bool get isEmpty =>
    (_registeredVoter == null) &&
    (_votePlace == null) &&
    (_voterByMail == null) &&
    (_voted == null);

  bool get isNotEmpty => !isEmpty;
  
  void clear() {

    bool modified = false;
    if (_registeredVoter != null) {
      _registeredVoter = null;
      modified = true;
    }

    if (_votePlace != null) {
      _votePlace = null;
      modified = true;
    }

    if (_voterByMail != null) {
      _voterByMail = null;
      modified = true;
    }

    if (_voted != null) {
      _voted = null;
      modified = true;
    }

    if (modified) {
      _notifyChanged();
    }
  }

  bool? get registeredVoter => _registeredVoter;
  set registeredVoter(bool? value) {
    if (_registeredVoter != value) {
      _registeredVoter = value;
      _notifyChanged();
    }
  }

  String? get votePlace => _votePlace;
  set votePlace(String? value) {
    if (_votePlace != value) {
      _votePlace = value;
      _notifyChanged();
    }
  }
  
  bool? get voterByMail => _voterByMail;
  set voterByMail(bool? value) {
    if (_voterByMail != value) {
      _voterByMail = value;
      _notifyChanged();
    }
  }

  bool? get voted => _voted;
  set voted(bool? value) {
    if (_voted != value) {
      _voted = value;
      _notifyChanged();
    }
  }

  void _notifyChanged() {
    if (onChanged != null) {
      onChanged!();
    }
  }
}

////////////////////////////////
// UserRole

class UserRole {
  static const student = const UserRole._internal('student');
  static const visitor = const UserRole._internal('visitor');
  static const fan = const UserRole._internal('fan');
  static const employee = const UserRole._internal('employee');
  static const alumni = const UserRole._internal('alumni');
  static const parent = const UserRole._internal('parent');
  static const resident = const UserRole._internal('resident');
  static const gies = const UserRole._internal('gies');

  static List<UserRole> get values {
    return [student, visitor, fan, employee, alumni, parent, resident, gies];
  }

  final String _value;

  const UserRole._internal(this._value);

  static UserRole? fromString(String? value) {
    return (value != null) ? UserRole._internal(value) : null;
  }

  static UserRole? fromJson(dynamic value) {
    return (value is String) ? UserRole._internal(value) : null;
  }

  toString() => _value;
  toJson() => _value;

  @override
  bool operator==(dynamic obj) {
    if (obj is UserRole) {
      return obj._value == _value;
    }
    return false;
  }

  @override
  int get hashCode => _value.hashCode;

  static List<UserRole>? listFromJson(List<dynamic>? jsonList) {
    List<UserRole>? result;
    if (jsonList != null) {
      result = <UserRole>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, UserRole.fromString(JsonUtils.stringValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<UserRole>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (UserRole contentEntry in contentList) {
        jsonList.add(contentEntry.toString());
      }
    }
    return jsonList;
  }

  static Set<UserRole>? setFromJson(List<dynamic>? jsonList) {
    Set<UserRole>? result;
    if (jsonList != null) {
      result = Set<UserRole>();
      for (dynamic jsonEntry in jsonList) {
        SetUtils.add(result, (jsonEntry is String) ? UserRole.fromString(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic>? setToJson(Set<UserRole>? contentSet) {
    List<dynamic>? jsonList;
    if (contentSet != null) {
      jsonList = <dynamic>[];
      for (UserRole? contentEntry in contentSet) {
        jsonList.add(contentEntry?.toString());
      }
    }
    return jsonList;
  }
}


////////////////////////////////
// Favorite

abstract class Favorite {
  String? get favoriteId;
  String? get favoriteTitle;
  String get favoriteKey;
}

////////////////////////////////
// Auth2PhoneVerificationMethod

enum Auth2PhoneVerificationMethod { call, sms }

////////////////////////////////
// AuthCard

class AuthCard {

  final String? uin;
  final String? fullName;
  final String? role;
  final String? studentLevel;
  final String? cardNumber;
  final String? expirationDate;
  final String? libraryNumber;
  final String? magTrack2;
  final String? photoBase64;

  AuthCard({this.uin, this.cardNumber, this.libraryNumber, this.expirationDate, this.fullName, this.role, this.studentLevel, this.magTrack2, this.photoBase64});

  static AuthCard? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AuthCard(
      uin: json['UIN'],
      fullName: json['full_name'],
      role: json['role'],
      studentLevel: json['student_level'],
      cardNumber: json['card_number'],
      expirationDate: json['expiration_date'],
      libraryNumber: json['library_number'],
      magTrack2: json['mag_track2'],
      photoBase64: json['photo_base64'],
    ) : null;
  }

  toJson() {
    return {
      'UIN': uin,
      'full_name': fullName,
      'role': role,
      'student_level': studentLevel,
      'card_number': cardNumber,
      'expiration_date': expirationDate,
      'library_number': libraryNumber,
      'mag_track2': magTrack2,
      'photo_base64': photoBase64,
    };
  }

  toShortJson() {
    return {
      'UIN': uin,
      'full_name': fullName,
      'role': role,
      'student_level': studentLevel,
      'card_number': cardNumber,
      'expiration_date': expirationDate,
      'library_number': libraryNumber,
      'mag_track2': magTrack2,
      'photo_base64_len': photoBase64?.length,
    };
  }

  bool operator ==(o) =>
      o is AuthCard &&
          o.uin == uin &&
          o.fullName == fullName &&
          o.role == role &&
          o.studentLevel == studentLevel &&
          o.cardNumber == cardNumber &&
          o.expirationDate == expirationDate &&
          o.libraryNumber == libraryNumber &&
          o.magTrack2 == magTrack2 &&
          o.photoBase64 == photoBase64;

  int get hashCode =>
      uin.hashCode ^
      fullName.hashCode ^
      role.hashCode ^
      studentLevel.hashCode ^
      cardNumber.hashCode ^
      expirationDate.hashCode ^
      libraryNumber.hashCode ^
      magTrack2.hashCode ^
      photoBase64.hashCode;

  Future<Uint8List?>? get photoBytes async {
    return (photoBase64 != null) ? await compute(base64Decode, photoBase64!) : null;
  }

  bool get needsUpdate {
    return (role == "Undergraduate") && (studentLevel != "1U");
  }
}

