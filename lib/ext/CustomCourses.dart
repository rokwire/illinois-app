import 'package:illinois/model/CustomCourses.dart';
import 'package:rokwire_plugin/service/localization.dart';

extension ReferenceExt on Reference {
  String? highlightLabelText() {
    switch (type) {
      case ReferenceType.video: return Localization().getStringEx('model.custom_courses.reference_type.video.highlight.label', 'Video');
      case ReferenceType.text: return Localization().getStringEx('model.custom_courses.reference_type.text.highlight.label', 'Key Term');
      case ReferenceType.powerpoint: return Localization().getStringEx('model.custom_courses.reference_type.powerpoint.highlight.label', 'Powerpoint');
      case ReferenceType.pdf: return Localization().getStringEx('model.custom_courses.reference_type.pdf.highlight.label', 'PDF');
      case ReferenceType.uri: return Localization().getStringEx('model.custom_courses.reference_type.uri.highlight.label', 'Web Link');
      case ReferenceType.survey: return Localization().getStringEx('model.custom_courses.reference_type.survey.highlight.label', 'Survey');
      default: return null;
    }
  }

  String? highlightActionText() {
    switch (type) {
      case ReferenceType.video: return Localization().getStringEx('model.custom_courses.reference_type.video.highlight.action', 'WATCH NOW');
      case ReferenceType.text: return Localization().getStringEx('model.custom_courses.reference_type.text.highlight.action', 'LEARN NOW');
      case ReferenceType.powerpoint: return Localization().getStringEx('model.custom_courses.reference_type.powerpoint.highlight.action', 'VIEW NOW');
      case ReferenceType.pdf: return Localization().getStringEx('model.custom_courses.reference_type.pdf.highlight.action', 'VIEW NOW');
      case ReferenceType.uri: return Localization().getStringEx('model.custom_courses.reference_type.uri.highlight.action', 'OPEN NOW');
      case ReferenceType.survey: return Localization().getStringEx('model.custom_courses.reference_type.survey.highlight.action', 'START NOW');
      default: return null;
    }
  }
}