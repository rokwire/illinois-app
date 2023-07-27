import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension SurveyExt on Survey {
  String? get displayTitle {
    if (StringUtils.isNotEmpty(title)) {
      return title;
    }
    else if (StringUtils.isNotEmpty(id)) {
      return id;
    }
    else {
      return null;
    }
  }
}