import 'package:flutter/foundation.dart';
import 'package:illinois/model/occupation/Occupation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class OccupationMatch {
  double? matchPercent;
  Occupation? occupation;

  OccupationMatch({
    this.matchPercent,
    this.occupation,
  });

  factory OccupationMatch.fromJson(Map<String, dynamic> json) {
    return OccupationMatch(
      occupation: Occupation.fromJson(json["occupation"]),
      matchPercent: JsonUtils.doubleValue(json["match_percent"]) ?? 0.0,
    );
  }

  static List<OccupationMatch>? listFromJson(List<dynamic>? jsonList) {
    List<OccupationMatch>? result;
    if (jsonList != null) {
      result = <OccupationMatch>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          try {
            ListUtils.add(result, OccupationMatch.fromJson(mapVal));
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return result;
  }

  @override
  String toString() {
    return 'OccupationMatch(occupation: $occupation, matchPercent: $matchPercent';
  }
}
