
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryContentPanel.dart';
import 'package:illinois/ui/home/HomeSavedResourcesWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';

class TransportationLinksPanel extends GBVResourceDirectoryContentPanel {
  TransportationLinksPanel() : super(
    headerBarTitle: Localization().getStringEx('panel.browse.entry.transit_and_safety.transportation_links.title', 'Transportation Links'),
    contentCategory: 'transportation_links',
    contentAssetKey: 'assets/extrs/transportationLinks.json',
    favoriteKey: HomeSavedResourcesWidget.favoriteKey,
    favoriteListner: HomeSavedResourcesWidget.favoriteListener,
    contentFailedMessage: Localization().getStringEx('', 'Failed to load transportation links data'),
    analyticsFeature: AnalyticsFeature.MTD,
  );
}


