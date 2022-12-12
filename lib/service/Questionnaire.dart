
import 'package:http/http.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Questionnaires /* with Service */ {

  static const String _participateInResearchSetting = 'edu.illinois.rokwire.settings.questionnaire.research.participate';

  // Singletone instance

  static final Questionnaires _service = Questionnaires._internal();
  factory Questionnaires() => _service;

  Questionnaires._internal();

  // Implementation

  Future<Questionnaire?> loadResearch() async {
    //TMP: return Questionnaire.fromJson(JsonUtils.decodeMap(await AppBundle.loadString('assets/questionnaire.demographics.json')));
    if (Config().contentUrl != null) {
      Response? response = await Network().get("${Config().contentUrl}/content_items", body: JsonUtils.encode({'categories': ['research_questionnaire']}), auth: Auth2());
      List<dynamic>? responseList = (response?.statusCode == 200) ? JsonUtils.decodeList(response?.body)  : null;
      dynamic responseItem = ((responseList != null) && responseList.isNotEmpty) ? responseList.first : null;
      Map<String, dynamic>? responseData = (responseItem is Map) ? JsonUtils.mapValue(responseItem['data']) : null;
      return Questionnaire.fromJson(responseData);
    }
    return null;
  }

  // Settings

  bool get participateInResearch => (Auth2().prefs?.getBoolSetting(_participateInResearchSetting) == true);
  set participateInResearch(bool value) {
    if (value == false) {
      Auth2().profile?.clearAllResearchQuestionnaireAnswers();
    }
    Auth2().prefs?.applySetting(_participateInResearchSetting, value);
  }
}