import 'dart:convert';

import 'package:http/http.dart';
import 'package:illinois/model/Occupation.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// Occupations currently does rely on the common Service initialization API so
// it does not need to extend Service interface and get registered in the app services list.
class Occupations /* with Service */ {
  static final Occupations _instance = Occupations._internal();

  factory Occupations() => _instance;

  Occupations._internal();

  Future<Response?> _getAllOccupationMatchesResponse() async => enabled ?
    Network().get('${Config().occupationsUrl}/user-match-results', auth: Auth2()) : null;

  Future<List<OccupationMatch>?> getAllOccupationMatches() async {
    Response? response = await _getAllOccupationMatchesResponse();
    Map<String, dynamic>? responseMap = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
    return (responseMap != null) ? OccupationMatch.listFromJson(JsonUtils.listValue(responseMap['matches'])) : null;
  }

  Future<Occupation?> getOccupation({required String occupationCode}) async {
    if (enabled) {
      String url = '${Config().occupationsUrl}/occupation/$occupationCode';
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
    }
    return null;
  }

  Future<void> postResults({required SurveyResponse? surveyResponse}) async {
    if (enabled) {
      Map<String, dynamic> surveyResult = {
        "scores": surveyResponse?.survey.stats?.scores.entries
            .map((mapEntry) => {
                  "workstyle": mapEntry.key,
                  "score": mapEntry.value,
                })
            .toList(),
      };
      String url = '${Config().occupationsUrl}/survey-data';
      Network().post(url, auth: Auth2(), body: jsonEncode(surveyResult));
    }
  }

  Future<List<OccupationMatch>?> getOccupationsByKeyword({required String keyword}) {
    // TODO: implement getOccupationsByKeyword
    throw UnimplementedError();
  }

  Future<List<OccupationMatch>?> getTop10Occupations() async {
    // TODO: implement getTop10Occupations
    throw UnimplementedError();
  }

  /////////////////////////
  // User Data

  Future<Map<String, dynamic>?> loadUserDataJson() async {
    Response? response = await _getAllOccupationMatchesResponse();
    return (response?.succeeded == true) ? { 'matches' : JsonUtils.decodeMap(response?.body) } : null;
  }

  /////////////////////////
  // Enabled

  bool get enabled => StringUtils.isNotEmpty(Config().occupationsUrl);
}
