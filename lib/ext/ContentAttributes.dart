
import 'package:illinois/model/Analytics.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';

extension ContentAttributesExt on ContentAttributes {

  AnalyticsFeature? get analyticsFeature {
    Set<String>? scope = this.scope;
    if (scope != null) {
      for (String scopeEntry in scope) {
        AnalyticsFeature? feature = AnalyticsFeature.fromName(scopeEntry);
        if (feature != null) {
          return feature;
        }
      }
    }
    return null;
  }
}