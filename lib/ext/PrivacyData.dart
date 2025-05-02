
import 'package:illinois/model/PrivacyData.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension PrivacyEntry2Ext on PrivacyEntry2 {
  String? get displayTitle => Localization().getString(titleKey, defaults: title);
  String? get displayDescription => Localization().getString(descriptionKey, defaults: description)?.replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
  String? get displayDataUsageInfo => Localization().getString(dataUsageKey, defaults: dataUsage);

  //The additional data is needed for the Wallet section (personalization)
  String? get displayAdditionalDescription => Localization().getString(additionalDescriptionKey, defaults: additionalDescription);
  String? get displayAdditionalDataUsageInfo => Localization().getString(additionalDataUsageKey, defaults: additionalDataUsage);

  bool get isVisible =>
      StringUtils.isNotEmpty(displayTitle) &&
      StringUtils.isNotEmpty(iconRes) &&
      StringUtils.isNotEmpty(offIconRes) &&
      (minLevel != null) &&
      (hidden != true);

}