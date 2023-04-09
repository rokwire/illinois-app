import 'package:http/http.dart';
import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class OccupationsService /* with Service */ {
  static final OccupationsService _instance = OccupationsService._internal();

  factory OccupationsService() => _instance;

  OccupationsService._internal();

  static String? _bbBaseUrl = Config().skillsToJobsUrl;

  Future<List<Occupation>?> getAllOccupations() async {
    // TODO: implement getAllOccupations
    String url = '$_bbBaseUrl/user-match-results';
    Response? response = await Network().get(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      List<dynamic>? responseMap = JsonUtils.decodeList(responseBody);
      if (responseMap != null) {
        List<Occupation>? surveys = Occupation.listFromJson(responseMap);
        return surveys;
      }
    }
    return null;
    // try {
    //   debugPrint('Getting all occupations');
    //   final response = await _dio.get(
    //     'user-match-results',
    //   );
    //   debugPrint("Response Code: ${response.statusCode}");
    //   debugPrint("Respone Data: ${response.data}");
    //   if (response.statusCode == 200) {
    //     final List<Occupation> result =
    //         ((response.data as Map<String, dynamic>)['matches'] as List).cast<Map<String, dynamic>>().map(
    //       (json) {
    //         debugPrint(json.toString());
    //         return Occupation(
    //           code: json['occupation_code'],
    //           title: json['occupation']['title'],
    //           description: json['occupation']['description'],
    //           matchPercentage: (json['score'] as double) * 100,
    //           onetLink: '',
    //           skills: [],
    //           technicalSkills: [],
    //         );
    //       },
    //     ).toList();
    //     debugPrint(result.toString());
    //     return result;
    //   }
    // } catch (e) {
    //   debugPrint("Respnse error: $e");
    // }
    // return [
    //   Occupation(
    //     code: '17-2051.00',
    //     title: 'Software Developer',
    //     description: 'Die from segmentation fault',
    //     matchPercentage: 75.0,
    //     onetLink: '',
    //     skills: [],
    //     technicalSkills: [],
    //   ),
    // ];
  }

  Future<Occupation?> getOccupation({required String occupationCode}) async {
    // TODO: implement getOccupation
    String url = '$_bbBaseUrl/occupation/$occupationCode';
    Response? response = await Network().get(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? responseMap = JsonUtils.decodeMap(responseBody);
      if (responseMap != null) {
        Occupation? survey = Occupation.fromJson(responseMap);
        // NotificationService().notify(notifySurveyLoaded);
        return survey;
      }
    }
    return null;
    // try {
    //   final response = await _dio.get('occupation/$occupationCode');
    //   debugPrint("Response Code: ${response.statusCode}");
    //   debugPrint("Respone Data: ${response.data}");
    //   if (response.statusCode == 200) {
    //     final result = Occupation.fromJson(response.data as Map<String, dynamic>);
    //     debugPrint(result.toString());
    //     return result;
    //   }
    // } catch (e) {
    //   debugPrint("Respnse error: $e");
    // }
    // return Occupation(
    //   title: 'Software Developer',
    //   description: 'Die from segmentation fault',
    //   matchPercentage: 75.0,
    //   onetLink: '',
    //   skills: [],
    //   technicalSkills: [],
    // );
    // throw UnimplementedError();
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
