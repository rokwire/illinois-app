
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryContentPanel.dart';
import 'package:illinois/ui/home/HomeSavedResourcesWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';

class CareerPlanningLinksPanel extends GBVResourceDirectoryContentPanel {
  CareerPlanningLinksPanel() : super(
    contentCategory: 'career_planning_links',
    contentAssetKey: 'assets/extra/careerPlanningLinks.json',
    favoriteKey: HomeSavedResourcesWidget.favoriteKey,
    headerBarTitle: Localization().getStringEx('panel.browse.entry.career_exploration.career_planing_links.title', 'Career Planning Links'),
    contentFailedMessage: Localization().getStringEx('', 'Failed to load career planing links data'),
    analyticsFeature: AnalyticsFeature.CareerExplorationSkillsSelfEvaluation,
  );
}
