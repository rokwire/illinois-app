
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
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
    const String researchQuestionnaireCategory = 'research_questionnaire';
    dynamic contentItem = await Content().loadContentItem(researchQuestionnaireCategory);
    return Questionnaire.fromJson(JsonUtils.mapValue((contentItem is List) ? contentItem.first : contentItem));
  }

  // Settings

  bool? get participateInResearch => Auth2().prefs?.getBoolSetting(_participateInResearchSetting);
  set participateInResearch(bool? value) {
    if (value == false) {
      Auth2().profile?.clearAllResearchQuestionnaireAnswers();
    }
    Auth2().prefs?.applySetting(_participateInResearchSetting, value);
  }
}