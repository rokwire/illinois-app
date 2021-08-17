
import 'package:illinois/model/Auth.dart';
import 'package:illinois/model/UserPiiData.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:uuid/uuid.dart';

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
// Auth2User

class Auth2User {
  final String id;
  final Auth2UserAccount account;
  final Auth2UserProfile profile;
  final List<String> permissions;
  final List<Auth2Role> roles;
  final List<Auth2Group> groups;
  final List<Auth2OrgMembership> orgMemberships;
  final AuthInfo uiucAccount;
  
  
  Auth2User({this.id, this.account, this.profile, this.permissions, this.roles, this.groups, this.orgMemberships}) :
    uiucAccount = AuthInfo.fromJson(Auth2OrgMembership.findInList(orgMemberships, orgId: Config().coreOrgId)?.userData);

  factory Auth2User.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2User(
      id: AppJson.stringValue(json['id']),
      account: Auth2UserAccount.fromJson(AppJson.mapValue(json['account'])),
      profile: Auth2UserProfile.fromJson(AppJson.mapValue(json['profile'])),
      permissions: AppJson.stringListValue(json['permissions']),
      roles: Auth2Role.listFromJson(AppJson.listValue(json['roles'])),
      groups: Auth2Group.listFromJson(AppJson.listValue(json['groups'])),
      orgMemberships: Auth2OrgMembership.listFromJson(AppJson.listValue(json['org_memberships'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'account': account,
      'profile': profile,
      'permissions': permissions,
      'roles': Auth2Role.listToJson(roles),
      'groups': Auth2Group.listToJson(groups),
      'org_memberships': Auth2OrgMembership.listToJson(orgMemberships),
    };
  }

  bool get isValid {
    return (id != null) && id.isNotEmpty &&
      (account != null) && account.isValid &&
      (profile != null) && profile.isValid;
  }

  UserPiiData get pii {
    return (uiucAccount != null) ? UserPiiData(
        pid: Uuid().v1(),
        uin: uiucAccount?.uin,
        netId: uiucAccount?.username,
        firstName: uiucAccount?.firstName,
        lastName: uiucAccount?.lastName,
        middleName: uiucAccount.middleName,
        userName: uiucAccount?.username,
        email: account?.email,
        phone: account?.phone,
        imageUrl: profile?.photoUrl
    ) : null;
  }
}

////////////////////////////////
// Auth2UserAccount

class Auth2UserAccount {
  final String id;
  final String email;
  final String phone;
  final String userName;
  
  Auth2UserAccount({this.id, this.email, this.phone, this.userName});

  factory Auth2UserAccount.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2UserAccount(
      id: AppJson.stringValue(json['id']),
      email: AppJson.stringValue(json['email']),
      phone: AppJson.stringValue(json['phone']),
      userName: AppJson.stringValue(json['username']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'email': email,
      'phone': phone,
      'username': userName,
    };
  }

  bool get isValid {
    return AppString.isStringNotEmpty(id);
  }
}

////////////////////////////////
// Auth2UserProfile

class Auth2UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String photoUrl;
  
  Auth2UserProfile({this.id, this.firstName, this.lastName, this.photoUrl});

  factory Auth2UserProfile.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2UserProfile(
      id: AppJson.stringValue(json['id']),
      firstName: AppJson.stringValue(json['first_name']),
      lastName: AppJson.stringValue(json['last_name']),
      photoUrl: AppJson.stringValue(json['photo_url']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'email': firstName,
      'phone': lastName,
      'username': photoUrl,
    };
  }

  bool get isValid {
    return AppString.isStringNotEmpty(id);
  }

  String get fullName {
    return AppString.fullName([firstName, lastName]);
  }
}

////////////////////////////////
// Auth2Role

class Auth2Role {
  final String id;
  final String orgId;
  final String name;
  final List<String> permissions;
  
  Auth2Role({this.id, this.orgId, this.name, this.permissions});

  factory Auth2Role.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2Role(
      id: AppJson.stringValue(json['id']),
      orgId: AppJson.stringValue(json['org_id']),
      name: AppJson.stringValue(json['name']),
      permissions: AppJson.stringListValue(json['permissions']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'org_id': orgId,
      'name': name,
      'permissions': permissions,
    };
  }

  static List<Auth2Role> listFromJson(List<dynamic> jsonList) {
    List<Auth2Role> authList;
    if (jsonList != null) {
      authList = <Auth2Role>[];
      for (dynamic jsonEntry in jsonList) {
        authList.add(Auth2Role.fromJson(AppJson.mapValue(jsonEntry)));
      }
    }
    return authList;
  }

  static List<dynamic> listToJson(List<Auth2Role> authList) {
    List<dynamic> jsonList;
    if (authList != null) {
      jsonList = <dynamic>[];
      for (Auth2Role authEntry in authList) {
        jsonList.add(authEntry?.toJson());
      }
    }
    return jsonList;
  }
}

////////////////////////////////
// Auth2Group

class Auth2Group {
  final String id;
  final String orgId;
  final String name;
  final List<String> permissions;
  final List<Auth2Role> roles;
  final List<String> users;
  final List<String> orgMemberships;
  
  Auth2Group({this.id, this.orgId, this.name, this.permissions, this.roles, this.users, this.orgMemberships});

  factory Auth2Group.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2Group(
      id: AppJson.stringValue(json['id']),
      orgId: AppJson.stringValue(json['org_id']),
      name: AppJson.stringValue(json['name']),
      permissions: AppJson.stringListValue(json['permissions']),
      roles: Auth2Role.listFromJson(AppJson.listValue(json['roles'])),
      users: AppJson.stringListValue(json['users']),
      orgMemberships: AppJson.stringListValue(json['org_memberships']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'org_id': orgId,
      'name': name,
      'permissions': permissions,
      'roles': Auth2Role.listToJson(roles),
      'users': users,
      'org_memberships': orgMemberships,
    };
  }

  static List<Auth2Group> listFromJson(List<dynamic> jsonList) {
    List<Auth2Group> authList;
    if (jsonList != null) {
      authList = <Auth2Group>[];
      for (dynamic jsonEntry in jsonList) {
        authList.add(Auth2Group.fromJson(AppJson.mapValue(jsonEntry)));
      }
    }
    return authList;
  }

  static List<dynamic> listToJson(List<Auth2Group> authList) {
    List<dynamic> jsonList;
    if (authList != null) {
      jsonList = <dynamic>[];
      for (Auth2Group authEntry in authList) {
        jsonList.add(authEntry?.toJson());
      }
    }
    return jsonList;
  }
}

////////////////////////////////
// Auth2OrgMembership

class Auth2OrgMembership {
  final String id;
  final String orgId;
  final String userId;
  final Map<String, dynamic> userData;
  final List<String> permissions;
  final List<Auth2Role> roles;
  final List<Auth2Group> groups;
  
  Auth2OrgMembership({this.id, this.orgId, this.userId, this.userData, this.permissions, this.roles, this.groups});

  factory Auth2OrgMembership.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Auth2OrgMembership(
      id: AppJson.stringValue(json['id']),
      orgId: AppJson.stringValue(json['org_id']),
      userId: AppJson.stringValue(json['user_id']),
      userData: AppJson.mapValue(json['org_user_data']),
      permissions: AppJson.stringListValue(json['permissions']),
      roles: Auth2Role.listFromJson(AppJson.listValue(json['roles'])),
      groups: Auth2Group.listFromJson(AppJson.listValue(json['groups'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'org_id': orgId,
      'user_id': userId,
      'org_user_data': userData,
      'permissions': permissions,
      'roles': Auth2Role.listToJson(roles),
      'groups': Auth2Group.listToJson(groups),
    };
  }

  static Auth2OrgMembership findInList(List<Auth2OrgMembership> authList, {String orgId }) {
    if (authList != null) {
      for (Auth2OrgMembership authEntry in authList) {
        if ((orgId != null) && (authEntry.orgId == orgId)) {
          return authEntry;
        }
      }
    }
    return null;
  }

  static List<Auth2OrgMembership> listFromJson(List<dynamic> jsonList) {
    List<Auth2OrgMembership> authList;
    if (jsonList != null) {
      authList = <Auth2OrgMembership>[];
      for (dynamic jsonEntry in jsonList) {
        authList.add(Auth2OrgMembership.fromJson(AppJson.mapValue(jsonEntry)));
      }
    }
    return authList;
  }

  static List<dynamic> listToJson(List<Auth2OrgMembership> authList) {
    List<dynamic> jsonList;
    if (authList != null) {
      jsonList = <dynamic>[];
      for (Auth2OrgMembership authEntry in authList) {
        jsonList.add(authEntry?.toJson());
      }
    }
    return jsonList;
  }

}

////////////////////////////////
// Auth2LoginType

enum Auth2LoginType { email, phone, oidc }

String auth2LoginTypeToString(Auth2LoginType value) {
  switch (value) {
    case Auth2LoginType.email: return 'email';
    case Auth2LoginType.phone: return 'phone';
    case Auth2LoginType.oidc: return 'oidc';
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
  return null;
}

