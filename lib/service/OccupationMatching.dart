import 'dart:convert';

import 'package:http/http.dart';
import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/model/occupation/OccupationMatch.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class OccupationMatching with Service {
  static final OccupationMatching _instance = OccupationMatching._internal();

  factory OccupationMatching() => _instance;

  OccupationMatching._internal();

  static String? _bbBaseUrl = Config().skillsToJobsUrl;

  Future<List<OccupationMatch>?> getAllOccupationMatches() async {
    String url = '$_bbBaseUrl/user-match-results';
    Response? response = await Network().get(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? responseMap = JsonUtils.decodeMap(responseBody);
      if (responseMap != null) {
        List<OccupationMatch>? surveys = OccupationMatch.listFromJson(responseMap['matches']);
        return surveys;
      }
    }
    return null;
  }

  Future<Occupation?> getOccupation({required String occupationCode}) async {
    String url = '$_bbBaseUrl/occupation/$occupationCode';
    Response? response = await Network().get(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? responseMap = JsonUtils.decodeMap(responseBody);
      if (responseMap != null) {
        Occupation? occupation = Occupation.fromJson(responseMap);
        return occupation;
      }
    }
    return null;
  }

  Future<void> postResults({required SurveyResponse? surveyResponse}) async {
    Map<String, dynamic> surveyResult = {
      "scores": surveyResponse?.survey.stats?.scores.entries.map((mapEntry) => {
        "workstyle": mapEntry.key,
        "score": mapEntry.value,
      }).toList(),
    };
    String url = '$_bbBaseUrl/survey-data';
    Network().post(url, auth: Auth2(), body: jsonEncode(surveyResult));
  }

  Future<List<OccupationMatch>?> getOccupationsByKeyword({required String keyword}) {
    // TODO: implement getOccupationsByKeyword
    throw UnimplementedError();
  }

  Future<List<OccupationMatch>?> getTop10Occupations() async {
    // TODO: implement getTop10Occupations
    throw UnimplementedError();
  }
}
