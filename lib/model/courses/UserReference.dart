
import 'package:rokwire_plugin/utils/utils.dart';

import 'Reference.dart';

class UserReference{
  final Reference? reference;
  final Map<String,dynamic>? userData;

  UserReference({this.reference, this.userData,});

  static UserReference? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UserReference(
      reference: Reference.fromJson(JsonUtils.mapValue('reference')),
      userData: json['user_data'],

    );

  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'reference': reference?.toJson(),
      'user_data': userData,
    };
    json.removeWhere((key, value) => (value == null));
    return json;
  }

  static List<UserReference>? listFromJson(List<dynamic>? jsonList) {
    List<UserReference>? result;
    if (jsonList != null) {
      result = <UserReference>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, UserReference.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<UserReference>? contentList) {
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