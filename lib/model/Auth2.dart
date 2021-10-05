
import 'package:collection/collection.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/utils/Utils.dart';

////////////////////////////////
// Auth2Token

class Auth2Token {
  final String idToken;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  
  Auth2Token({this.accessToken, this.refreshToken, this.idToken, this.tokenType});

  factory Auth2Token.fromOther(Auth2Token value, {String idToken, String accessToken, String refreshToken, String tokenType }) {
    return (value != null) ? Auth2Token(
      idToken: idToken ?? value?.idToken,
      accessToken: accessToken ?? value?.accessToken,
      refreshToken: refreshToken ?? value?.refreshToken,
      tokenType: tokenType ?? value?.tokenType,
    ) : null;
  }

  factory Auth2Token.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2Token(
      idToken: AppJson.stringValue(json['id_token']),
      accessToken: AppJson.stringValue(json['access_token']),
      refreshToken: AppJson.stringValue(json['refresh_token']),
      tokenType: AppJson.stringValue(json['token_type']),
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

  bool get isValid {
    return AppString.isStringNotEmpty(accessToken) && AppString.isStringNotEmpty(refreshToken) && AppString.isStringNotEmpty(tokenType);
  }

  bool get isValidUiuc {
    return AppString.isStringNotEmpty(accessToken) && AppString.isStringNotEmpty(idToken) && AppString.isStringNotEmpty(tokenType);
  }
}

////////////////////////////////
// Auth2LoginType

enum Auth2LoginType { email, phone, oidc, oidcIllinois }

String auth2LoginTypeToString(Auth2LoginType value) {
  switch (value) {
    case Auth2LoginType.email: return 'email';
    case Auth2LoginType.phone: return 'phone';
    case Auth2LoginType.oidc: return 'oidc';
    case Auth2LoginType.oidcIllinois: return 'illinois_oidc';
  }
  return null;
}

Auth2LoginType auth2LoginTypeFromString(String value) {
  if (value == 'email') {
    return Auth2LoginType.email;
  }
  else if (value == 'phone') {
    return Auth2LoginType.email;
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
  final String id;
  final Auth2UserProfile profile;
  final Auth2UserPrefs prefs;
  final List<Auth2StringEntry> permissions;
  final List<Auth2StringEntry> roles;
  final List<Auth2StringEntry> groups;
  final List<Auth2Type> authTypes;
  
  
  Auth2Account({this.id, this.profile, this.prefs, this.permissions, this.roles, this.groups, this.authTypes});

  factory Auth2Account.fromJson(Map<String, dynamic> json, { Auth2UserPrefs prefs }) {
    return (json != null) ? Auth2Account(
      id: AppJson.stringValue(json['id']),
      profile: Auth2UserProfile.fromJson(AppJson.mapValue(json['profile'])),
      prefs: Auth2UserPrefs.fromJson(AppJson.mapValue(json['preferences'])) ?? prefs, //TBD Auth2
      permissions: Auth2StringEntry.listFromJson(AppJson.listValue(json['permissions'])),
      roles: Auth2StringEntry.listFromJson(AppJson.listValue(json['roles'])),
      groups: Auth2StringEntry.listFromJson(AppJson.listValue(json['groups'])),
      authTypes: Auth2Type.listFromJson(AppJson.listValue(json['auth_types'])),
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
    (DeepCollectionEquality().hash(permissions) ?? 0) ^
    (DeepCollectionEquality().hash(roles) ?? 0) ^
    (DeepCollectionEquality().hash(groups) ?? 0) ^
    (DeepCollectionEquality().hash(authTypes) ?? 0);

  bool get isValid {
    return (id != null) && id.isNotEmpty &&
      (profile != null) && profile.isValid;
  }

  Auth2Type get authType {
    return ((authTypes != null) && (0 < authTypes.length)) ? authTypes?.first : null;
  }

}

////////////////////////////////
// Auth2UserProfile

class Auth2UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final int birthYear;
  final String photoUrl;

  final String email;
  final String phone;
  
  final String address;
  final String state;
  final String zip;
  final String country;
  
  Auth2UserProfile({this.id, this.firstName, this.lastName, this.birthYear, this.photoUrl,
    this.email, this.phone, this.address, this.state, this.zip, this.country
  });

  factory Auth2UserProfile.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2UserProfile(
      id: AppJson.stringValue(json['id']),
      firstName: AppJson.stringValue(json['first_name']),
      lastName: AppJson.stringValue(json['last_name']),
      birthYear: AppJson.intValue(json['birth_year']),
      photoUrl: AppJson.stringValue(json['photo_url']),

      email: AppJson.stringValue(json['email']),
      phone: AppJson.stringValue(json['phone']),
  
      address: AppJson.stringValue(json['address']),
      state: AppJson.stringValue(json['state']),
      zip: AppJson.stringValue(json['zip']),
      country: AppJson.stringValue(json['country']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'first_name': firstName,
      'last_name': lastName,
      'birth_year': birthYear,
      'photo_url': photoUrl,

      'email': email,
      'phone': phone,

      'address': address,
      'state': state,
      'zip': zip,
      'country': country,
    };
  }

  bool operator ==(o) =>
    (o is Auth2UserProfile) &&
      (o.id == id) &&
      (o.firstName == firstName) &&
      (o.lastName == lastName) &&
      (o.birthYear == birthYear) &&
      (o.photoUrl == photoUrl) &&

      (o.email == email) &&
      (o.phone == phone) &&

      (o.address == address) &&
      (o.state == state) &&
      (o.zip == zip) &&
      (o.country == country);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (firstName?.hashCode ?? 0) ^
    (lastName?.hashCode ?? 0) ^
    (birthYear?.hashCode ?? 0) ^
    (photoUrl?.hashCode ?? 0) ^

    (email?.hashCode ?? 0) ^
    (phone?.hashCode ?? 0) ^

    (address?.hashCode ?? 0) ^
    (state?.hashCode ?? 0) ^
    (zip?.hashCode ?? 0) ^
    (country?.hashCode ?? 0);

  bool get isValid {
    return AppString.isStringNotEmpty(id);
  }

  String get fullName {
    return AppString.fullName([firstName, lastName]);
  }
}

////////////////////////////////
// Auth2StringEntry

class Auth2StringEntry {
  final String id;
  final String name;
  
  Auth2StringEntry({this.id, this.name});

  factory Auth2StringEntry.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2StringEntry(
      id: AppJson.stringValue(json['id']),
      name: AppJson.stringValue(json['name']),
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

  static List<Auth2StringEntry> listFromJson(List<dynamic> jsonList) {
    List<Auth2StringEntry> result;
    if (jsonList != null) {
      result = <Auth2StringEntry>[];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? Auth2StringEntry.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<Auth2StringEntry> contentList) {
    List<dynamic> jsonList;
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
// Auth2Type

class Auth2Type {
  final String id;
  final String identifier;
  final bool active;
  final bool active2fa;
  final Map<String, dynamic> params;
  
  final Auth2UiucUser uiucUser;
  
  Auth2Type({this.id, this.identifier, this.active, this.active2fa, this.params}) :
  uiucUser = (params != null) ? Auth2UiucUser.fromJson(AppJson.mapValue(params['user'])) : null;

  factory Auth2Type.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2Type(
      id: AppJson.stringValue(json['id']),
      identifier: AppJson.stringValue(json['identifier']),
      active: AppJson.boolValue(json['active']),
      active2fa: AppJson.boolValue(json['active_2fa']),
      params: AppJson.mapValue(json['params']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'identifier': identifier,
      'active': active,
      'active_2fa': active2fa,
      'params': params,
    };
  }

  bool operator ==(o) =>
    (o is Auth2Type) &&
      (o.id == id) &&
      (o.identifier == identifier) &&
      (o.active == active) &&
      (o.active2fa == active2fa) &&
      DeepCollectionEquality().equals(o.params, params);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (identifier?.hashCode ?? 0) ^
    (active?.hashCode ?? 0) ^
    (active2fa?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(params) ?? 0);

  static List<Auth2Type> listFromJson(List<dynamic> jsonList) {
    List<Auth2Type> result;
    if (jsonList != null) {
      result = <Auth2Type>[];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? Auth2Type.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<Auth2Type> contentList) {
    List<dynamic> jsonList;
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
// Auth2UiucUser

class Auth2UiucUser {
  final String email;
  final String firstName;
  final String lastName;
  final String middleName;
  final String identifier;
  final List<String> groups;
  final Map<String, dynamic> systemSpecific;
  final Set<String> groupsMembership;
  
  Auth2UiucUser({this.email, this.firstName, this.lastName, this.middleName, this.identifier, this.groups, this.systemSpecific}) :
    groupsMembership = (groups != null) ? Set.from(groups) : null;

  factory Auth2UiucUser.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2UiucUser(
      email: AppJson.stringValue(json['email']),
      firstName: AppJson.stringValue(json['first_name']),
      lastName: AppJson.stringValue(json['last_name']),
      middleName: AppJson.stringValue(json['middle_name']),
      identifier: AppJson.stringValue(json['identifier']),
      groups: AppJson.stringListValue(json['groups']),
      systemSpecific: AppJson.mapValue(json['system_specific']),
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
    (DeepCollectionEquality().hash(groups) ?? 0) ^
    (DeepCollectionEquality().hash(systemSpecific) ?? 0);

  String get uin {
    return (systemSpecific != null) ? AppJson.stringValue(systemSpecific['uiucedu_uin']) : null;
  }

  String get fullName {
    return AppString.fullName([firstName, middleName, lastName]);
  }

  static List<Auth2UiucUser> listFromJson(List<dynamic> jsonList) {
    List<Auth2UiucUser> result;
    if (jsonList != null) {
      result = <Auth2UiucUser>[];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? Auth2UiucUser.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<Auth2UiucUser> contentList) {
    List<dynamic> jsonList;
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
  static const String notifyInterestsChanged  = "edu.illinois.rokwire.user.prefs.interests.changed";
  static const String notifyFavoritesChanged  = "edu.illinois.rokwire.user.prefs.favorites.changed";
  static const String notifyFavoriteChanged  = "edu.illinois.rokwire.user.prefs.favorite.changed";
  static const String notifyRolesChanged  = "edu.illinois.rokwire.user.prefs.roles.changed";
  static const String notifyTagsChanged  = "edu.illinois.rokwire.user.prefs.tags.changed";
  static const String notifyChanged  = "edu.illinois.rokwire.user.prefs.changed";

  int _privacyLevel;
  Set<UserRole> _roles;
  Map<String, Set<String>>  _favorites;
  Map<String, Set<String>>  _interests;
  Map<String, bool> _tags;

  Auth2UserPrefs({int privacyLevel, Set<UserRole> roles, Map<String, Set<String>> favorites, Map<String, Set<String>> interests, Map<String, bool> tags}) {
    _privacyLevel = privacyLevel;
    _roles = roles;
    _favorites = favorites;
    _interests = interests;
    _tags = tags;
  }

  factory Auth2UserPrefs.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2UserPrefs(
      privacyLevel: AppJson.intValue(json['privacy_level']),
      roles: UserRole.setFromJson(AppJson.listValue(json['roles'])),
      favorites: mapOfStringSetsFromJson(AppJson.mapValue(json['favorites'])),
      interests: mapOfStringSetsFromJson(AppJson.mapValue(json['interests'])),
      tags: _tagsFromJson(AppJson.mapValue(json['tags'])),
    ) : null;
  }

  factory Auth2UserPrefs.empty() {
    return Auth2UserPrefs(
      privacyLevel: null,
      roles: Set<UserRole>(),
      favorites: Map<String, Set<String>>(),
      interests: Map<String, Set<String>>(),
      tags: Map<String, bool>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacy_level' : privacyLevel,
      'roles': UserRole.setToJson(roles),
      'favorites': mapOfStringSetsToJson(_favorites),
      'interests': mapOfStringSetsToJson(_interests),
      'tags': _tags,
    };
  }

  bool operator ==(o) =>
    (o is Auth2UserPrefs) &&
      (o._privacyLevel == _privacyLevel) &&
      DeepCollectionEquality().equals(o._roles, _roles) &&
      DeepCollectionEquality().equals(o._favorites, _favorites) &&
      DeepCollectionEquality().equals(o._interests, _interests) &&
      DeepCollectionEquality().equals(o._tags, _tags);

  int get hashCode =>
    (_privacyLevel?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(_roles) ?? 0) ^
    (DeepCollectionEquality().hash(_favorites) ?? 0) ^
    (DeepCollectionEquality().hash(_interests) ?? 0) ^
    (DeepCollectionEquality().hash(_tags) ?? 0);

  bool apply(Auth2UserPrefs prefs) {
    bool modified = false;

    if (prefs != null) {
      if ((prefs.privacyLevel != null) && (prefs.privacyLevel > 0) && (prefs.privacyLevel != _privacyLevel)) {
        _privacyLevel = prefs._privacyLevel;
        modified = true;
      }
      if ((prefs.roles != null) && prefs.roles.isNotEmpty && !DeepCollectionEquality().equals(prefs.roles, _roles)) {
        _roles = prefs._roles;
        modified = true;
      }
      if ((prefs._favorites != null) && prefs._favorites.isNotEmpty && !DeepCollectionEquality().equals(prefs._favorites, _favorites)) {
        _favorites = prefs._favorites;
        modified = true;
      }
      if ((prefs._interests != null) && prefs._interests.isNotEmpty && !DeepCollectionEquality().equals(prefs._interests, _interests)) {
        _interests = prefs._interests;
        modified = true;
      }
      if ((prefs._tags != null) && prefs._tags.isNotEmpty && !DeepCollectionEquality().equals(prefs._tags, _tags)) {
        _tags = prefs._tags;
        modified = true;
      }
    }
    return modified;
  }
  
  // Privacy

  int get privacyLevel {
    return _privacyLevel;
  }
  
  set privacyLevel(int value) {
    if (_privacyLevel != value) {
      _privacyLevel = value;
      NotificationService().notify(notifyPrivacyLevelChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Roles

  Set<UserRole> get roles {
    return _roles;
  } 
  
  set roles(Set<UserRole> value) {
    if (_roles != value) {
      _roles = (value != null) ? Set.from(value) : null;
      NotificationService().notify(notifyRolesChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Favorites

  Set<String> getFavorites(String favoriteKey) {
    return (_favorites != null) ? _favorites[favoriteKey] : null;
  }

  bool isFavorite(Favorite favorite) {
    Set<String> favoriteIdsForKey = (_favorites != null) ? _favorites[favorite?.favoriteKey] : null;
    return (favoriteIdsForKey != null) && favoriteIdsForKey.contains(favorite?.favoriteId);
  }

  void toggleFavorite(Favorite favorite) {
    if ((favorite != null) && (_favorites != null)) {
      Set<String> favoriteIdsForKey = _favorites[favorite?.favoriteKey];
      bool shouldFavorite = (favoriteIdsForKey == null) || !favoriteIdsForKey.contains(favorite?.favoriteId);
      if (shouldFavorite) {
        if (favoriteIdsForKey == null) {
          _favorites[favorite.favoriteKey] = favoriteIdsForKey = Set<String>();
        }
        favoriteIdsForKey.add(favorite.favoriteId);
      }
      else {
        favoriteIdsForKey.remove(favorite?.favoriteId);
        if (favoriteIdsForKey.isEmpty) {
          _favorites.remove(favorite?.favoriteKey);
        }
      }

      Analytics().logFavorite(favorite, shouldFavorite);
      DeviceCalendar().onFavoriteUpdated(favorite, shouldFavorite);
      NotificationService().notify(notifyFavoriteChanged, favorite);
      NotificationService().notify(notifyFavoritesChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  bool isListFavorite(List<Favorite> favorites) {
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

  void setListFavorite(List<Favorite> favorites, bool shouldFavorite, {Favorite sourceFavorite}) {
    if ((favorites != null) && (_favorites != null)) {
      for (Favorite favorite in favorites) {
        Set<String> favoriteIdsForKey = _favorites[favorite?.favoriteKey];
        bool isFavorite = (favoriteIdsForKey != null) && favoriteIdsForKey.contains(favorite?.favoriteId);
        if (isFavorite && !shouldFavorite) {
          favoriteIdsForKey.remove(favorite?.favoriteId);
          if (favoriteIdsForKey.isEmpty) {
            _favorites.remove(favorite?.favoriteKey);
          }
        }
        else if (!isFavorite && shouldFavorite) {
          if (favoriteIdsForKey == null) {
            _favorites[favorite.favoriteKey] = favoriteIdsForKey = Set<String>();
          }
          favoriteIdsForKey.add(favorite.favoriteId);
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

  // Interests

  Iterable<String> get interestCategories {
    return _interests?.keys;
  }

  void toggleInterestCategory(String category) {
    if ((category != null) && (_interests != null)) {
      if (_interests.containsKey(category)) {
        _interests.remove(category);
      }
      else {
        _interests[category] = Set<String>();
      }

      NotificationService().notify(notifyInterestsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyInterestCategories(Set<String> categories) {
    if ((categories != null) && (_interests != null)) {

      bool modified = false;
      Set<String> categoriesToRemove;
      for (String category in _interests.keys) {
        if (!categories.contains(category)) {
          if (categoriesToRemove == null) {
            categoriesToRemove = Set<String>();
          }
          categoriesToRemove.add(category);
        }
      }

      for (String category in categories) {
        if (!_interests.containsKey(category)) {
          _interests[category] = Set<String>();
          modified = true;
        }
      }

      if (categoriesToRemove != null) {
        for (String category in categoriesToRemove) {
          _interests.remove(category);
          modified = true;
        }
      }

      if (modified) {
        NotificationService().notify(notifyInterestsChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  Set<String> getInterestsFromCategory(String category) {
    return ((_interests != null) && (category != null)) ? _interests[category] : null;
  }

  bool hasInterest(String category, String interest) {
    Set<String> interests = ((category != null) && (_interests != null)) ? _interests[category] : null;
    return ((interests != null) && (interest != null)) ? interests.contains(interest) : null;
  }

  void toggleInterest(String category, String interest) {
    if ((category != null) && (interest != null) && (_interests != null)) {
      Set<String> categories = _interests[category];
      if (categories == null) {
        _interests[category] = categories = Set<String>();
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

  void toggleInterests(String category, Iterable<String> interests) {
    if ((category != null) && (interests != null) && interests.isNotEmpty && (_interests != null)) {
      Set<String> categories = _interests[category];
      if (categories == null) {
        _interests[category] = categories = Set<String>();
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

  void applyInterests(String category, Iterable<String> interests) {
    if ((category != null) && (_interests != null)) {
      bool modified = false;
      if ((interests != null) && !DeepCollectionEquality().equals(_interests[category], interests)) {
        _interests[category] = Set<String>.from(interests);
        modified = true;
      }
      else if (_interests.containsKey(category)) {
        _interests.remove(category);
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

    if ((_interests == null) || _interests.isNotEmpty) {
      _interests = Map<String, Set<String>>();
      modified = true;
      NotificationService().notify(notifyInterestsChanged);
    }

    if ((_tags == null) || _tags.isNotEmpty) {
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

  Set<String> get sportsInterests => getInterestsFromCategory(sportsInterestsCategory);
  bool hasSportInterest(String sport) => hasInterest(sportsInterestsCategory, sport);
  void toggleSportInterest(String sport) => toggleInterest(sportsInterestsCategory, sport);
  void toggleSportInterests(Iterable<String> sports) => toggleInterests(sportsInterestsCategory, sports);

  // Tags

  Set<String> get positiveTags => getTags(positive: true);
  bool hasPositiveTag(String tag) => hasTag(tag, positive: true);
  void togglePositiveTag(String tag) => toggleTag(tag, positive: true);

  Set<String> getTags({ bool positive }) {
    Set<String> tags;
    if (_tags != null) {
      tags = Set<String>();
      for (String tag in _tags.keys) {
        if ((positive == null) || (_tags[tag] == positive)) {
          tags.add(tag);
        }
      }
    }
    return tags;
  }

  bool hasTag(String tag, { bool positive}) {
    if ((_tags != null) && (tag != null)) {
      bool value = _tags[tag];
      return (value != null) && ((positive == null) || (value == positive));
    }
    return false;
  }

  void toggleTag(String tag, { bool positive = true}) {
    if ((_tags != null) && (tag != null)) {
      if (_tags.containsKey(tag)) {
        _tags.remove(tag);
      }
      else {
        _tags[tag] = positive;
      }
    }
    NotificationService().notify(notifyTagsChanged);
    NotificationService().notify(notifyChanged, this);
  }

  void addTag(String tag, { bool positive }) {
    if ((_tags != null) && (tag != null) && (_tags[tag] != positive)) {
      _tags[tag] = positive;
      NotificationService().notify(notifyTagsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void removeTag(String tag) {
    if ((_tags != null) && (tag != null) && _tags.containsKey(tag)) {
      _tags.remove(tag);
      NotificationService().notify(notifyTagsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyTags(Iterable<String> tags, { bool positive = true }) {
    if ((_tags != null) && (tags != null)) {
      bool modified = false;
      for (String tag in tags) {
        if (_tags[tag] != positive) {
          _tags[tag] = positive;
          modified = true;
        }
      }
      if (modified) {
        NotificationService().notify(notifyTagsChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  // Helpers

  static Map<String, Set<String>> mapOfStringSetsFromJson(Map<String, dynamic> jsonMap) {
    Map<String, Set<String>> result;
    if (jsonMap != null) {
      result = Map<String, Set<String>>();
      for (String key in jsonMap.keys) {
        result[key] = AppJson.setStringsValue(jsonMap[key]);
      }
    }
    return result;
  }

  static Map<String, dynamic> mapOfStringSetsToJson(Map<String, Set<String>> contentMap) {
    Map<String, dynamic> jsonMap;
    if (contentMap != null) {
      jsonMap = Map<String, dynamic>();
      for (String key in contentMap.keys) {
        jsonMap[key] = List.from(contentMap[key]);
      }
    }
    return jsonMap;
  }

  static _tagsFromJson(Map<String, dynamic> json) {
    try { return json?.cast<String, bool>(); }
    catch(e) { print(e?.toString()); }
  }
}

