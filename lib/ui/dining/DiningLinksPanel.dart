
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryContentPanel.dart';
import 'package:illinois/ui/home/HomeSavedGBVResourcesWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';

class DiningLinksPanel extends GBVResourceDirectoryContentPanel {
  DiningLinksPanel() : super(
    headerBarTitle: Localization().getStringEx('panel.browse.entry.dining.dining_links.title', 'Campus Dining'),
    contentWidgetBuilder: (context) => DiningLinksWidget(),
    analyticsFeature: AnalyticsFeature.DiningLinks,
  );
}

class DiningLinksWidget extends GBVResourceDirectoryContentWidget {
  DiningLinksWidget() : super(
    contentCategory: 'dining_links',
    contentAssetKey: 'assets/extra/diningLinks.json',
    favoriteKey: HomeSavedGBVResourcesWidget.favoriteKey,
    favoriteListner: HomeSavedGBVResourcesWidget.favoriteListener,
    contentFailedMessage: Localization().getStringEx('', 'Failed to load dining links data'),
  );
}

