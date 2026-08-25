
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryContentPanel.dart';
import 'package:illinois/ui/home/HomeSavedResourcesWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';

class TransportationAndSafetyLinksPanel extends GBVResourceDirectoryContentPanel {
  TransportationAndSafetyLinksPanel() : super(
    headerBarTitle: Localization().getStringEx('panel.browse.entry.transit_and_safety.transportation_and_safety_links.title', 'Transportation & Safety Links'),
    contentCategory: 'transportation_and_safety_links',
    contentAssetKey: 'assets/transportationAndSafetyLinks.json',
    favoriteKey: HomeSavedResourcesWidget.favoriteKey,
    favoriteListner: HomeSavedResourcesWidget.favoriteListener,
    contentFailedMessage: Localization().getStringEx('', 'Failed to load transportation links data'),
    analyticsFeature: AnalyticsFeature.MTD,
  );
}


