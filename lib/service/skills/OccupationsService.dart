import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:illinois/model/occupation/OccupationMatch.dart';
import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class OccupationsService with Service {
  static final OccupationsService _instance = OccupationsService._internal();

  factory OccupationsService() => _instance;

  OccupationsService._internal();

  static String? _bbBaseUrl = Config().skillsToJobsUrl;

  Future<List<OccupationMatch>?> getAllOccupationMatches() async {
    // TODO: implement getAllOccupationMatches
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
    // TODO: implement getOccupation
    String url = '$_bbBaseUrl/occupation/$occupationCode';
    Response? response = await Network().get(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      debugPrint(responseBody);
      Map<String, dynamic>? responseMap = JsonUtils.decodeMap(responseBody);
      if (responseMap != null) {
        Occupation? survey = Occupation.fromJson(responseMap);
        return survey;
      }
    }
    return null;
  }

  Future<List<Occupation>> getOccupationsByKeyword({required String keyword}) {
    // TODO: implement getOccupationsByKeyword
    throw UnimplementedError();
  }

  Future<List<Occupation>> getTop10Occupations() async {
    // TODO: implement getTop10Occupations
    // 'online/occupations/'
    throw UnimplementedError();
  }
}
